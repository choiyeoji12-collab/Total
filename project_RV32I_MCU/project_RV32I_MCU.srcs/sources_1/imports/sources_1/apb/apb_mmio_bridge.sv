`timescale 1ns / 1ps

// 주소를 해독하고 APB 통신 규칙을 만드는 통역사
module apb_mmio_bridge #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH / 8,
    parameter int NUM_SLAVES = 5,
    parameter logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] SLAVE_BASE = {
        32'h2000_0000,
        32'h2000_1000,
        32'h2000_2000,
        32'h2000_3000,
        32'h2000_4000
    },
    parameter logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] SLAVE_MASK = {
        32'hFFFF_F000,
        32'hFFFF_F000,
        32'hFFFF_F000,
        32'hFFFF_F000,
        32'hFFFF_F000
    }
) (
    // CPU 쪽 인터페이스
    input  logic                         PCLK,
    input  logic                         PRESETn,

    input  logic                         req_valid,
    output logic                         req_ready,
    input  logic [ADDR_WIDTH-1:0]        req_addr,
    input  logic                         req_write,
    input  logic [DATA_WIDTH-1:0]        req_wdata,
    input  logic [STRB_WIDTH-1:0]        req_strb,
    input  logic [2:0]                   req_prot,

    output logic                         rsp_valid,
    output logic [DATA_WIDTH-1:0]        rsp_rdata,
    output logic                         rsp_err,

    // APB 버스 쪽 인터페이스
    output logic [ADDR_WIDTH-1:0]        PADDR,
    output logic                         PWRITE,
    output logic                         PENABLE,
    output logic [DATA_WIDTH-1:0]        PWDATA,
    output logic [STRB_WIDTH-1:0]        PSTRB,     // APB용 바이트 쓰기 제어 신호
    output logic [2:0]                   PPROT,     // APB용 보안 신호
    output logic [NUM_SLAVES-1:0]        PSEL,

    input  logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0] PRDATA,
    input  logic [NUM_SLAVES-1:0]                 PREADY,
    input  logic [NUM_SLAVES-1:0]                 PSLVERR  // 장치 내부 에러 신호
);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_SETUP,   // 주소와 선택 신호를 먼저 띄워놓고 준비하는 상태
        ST_ACCESS   // PENABLE을 켜서 진짜로 데이터를 주고받는 상태
    } apb_state_t;

    apb_state_t state_q, state_d;

    logic [ADDR_WIDTH-1:0] req_addr_q, req_addr_d;     // 주소 기억용
    logic [DATA_WIDTH-1:0] req_wdata_q, req_wdata_d;    // 쓸 데이터 기억용
    logic [STRB_WIDTH-1:0] req_strb_q, req_strb_d;      // 바이트 제어 신호 기억용
    logic [2:0]            req_prot_q, req_prot_d;      // 보호 신호 기억용
    logic                  req_write_q, req_write_d;    // 쓰기 여부 기억용
    logic [NUM_SLAVES-1:0] psel_q, psel_d;          // 누구를 선택했는지 기억용

    // 현재 선택된 하나의 장치에서만 신호를 뽑아내기 위한 내부 변수들
    logic [DATA_WIDTH-1:0] active_prdata;   // 선택된 장치가 보내온 데이터
    logic                  active_pready;   // 선택된 장치의 준비 완료 신호
    logic                  active_pslverr;  // 선택된 장치의 에러 신호

    logic                  decode_miss;     // 아무 장치도 선택되지 않았을 때 켜지는 신호
    logic                  decode_overlap;  // 실수로 2개 이상의 장치가 선택되었을 때 켜지는 신호

    // 여러 개의 장치가 동시에 선택되었는지 검사하는 함수 
    function automatic logic has_multiple_hits (
        input logic [NUM_SLAVES-1:0] sel_vec    // PSEL 배열을 입력으로 받음
    );
        logic seen_one;     // 1을 한 번이라도 봤는지 기억하는 변수
        int i;
        begin   
            seen_one = 1'b0;
            has_multiple_hits = 1'b0;   // 다중 선택이 안 되었다고 가정
            for (i = 0; i < NUM_SLAVES; i = i + 1) begin    // 장치 개수만큼 반복
                if (sel_vec[i]) begin       // 만약 i 번쨰 장치의 스위치가 1 켜져있다면
                    if (seen_one) begin     // 근데 이미 이전에 1을 본 적이 있다면
                        has_multiple_hits = 1'b1;   // 다중 선택 에러 발생
                    end
                    seen_one = 1'b1;    // 1을 봤었다고 표시
                end
            end
        end
    endfunction

    // CPU의 주소를 보고 어느 장치로 가야할지 스위치를 켜주는 주소 해독기
    function automatic logic [NUM_SLAVES-1:0] decode_psel (
        input logic [ADDR_WIDTH-1:0] addr   // CPU가 접근하려는 주소
    );
        logic [NUM_SLAVES-1:0] hit_vec;     // 장치별 스위치 배열 (결과값)
        int i;
        begin
            hit_vec = '0;   // 처음엔 모든 스위치를 0으로 끔
            for (i = 0; i < NUM_SLAVES; i++) begin
                // (CPU 주소&마스크) == (장치기준주소&마스크)인지 비교
                // 뒷자리 세부 주소는 가려버리고, 앞자리 구역 번호가 일치하는지 확인하는 과정
                if ((addr & SLAVE_MASK[i]) == (SLAVE_BASE[i] & SLAVE_MASK[i])) begin
                    hit_vec[i] = 1'b1;  // 일치하는 장치의 스위치 1로 켬
                end
            end
            return hit_vec;     // 켜진 스위치 결과를 밖으로 내보냄
        end
    endfunction

    always_comb begin
        active_prdata  = '0;
        active_pready  = 1'b1;  // 기본적으로 준비되었다고 가정
        active_pslverr = 1'b0;  // 기본적으로 에러 없다고 가정
        for (int i = 0; i < NUM_SLAVES; i++) begin
            if (psel_q[i]) begin        // 만약 i번쨰 장치의 PSEL 스위치가 켜져 있다면
                active_prdata  = PRDATA[i];     // 그 장치의 데이터를 active 변수에 연결
                active_pready  = PREADY[i];     // 그 장치의 준비 신호를 active 변수에 연결
                active_pslverr = PSLVERR[i];    // 그 장치의 에러 신호를 active 변수에 연결
            end
        end
    end

    // 아무 스위치도 안 켜져있으면 miss = 1
    assign decode_miss = (psel_q == '0);
    // 2개 이상 켜졌으면 overlap = 1
    assign decode_overlap = has_multiple_hits(psel_q);

    always_comb begin
        state_d     = state_q;
        req_addr_d  = req_addr_q;
        req_wdata_d = req_wdata_q;
        req_strb_d  = req_strb_q;
        req_prot_d  = req_prot_q;
        req_write_d = req_write_q;
        psel_d      = psel_q;

        req_ready   = 1'b0;
        rsp_valid   = 1'b0;
        rsp_rdata   = active_prdata;    // CPU에게 줄 데이터는 현재 활성화된 장치의 데이터
        rsp_err     = 1'b0;

        PADDR       = req_addr_q;
        PWDATA      = req_wdata_q;
        PWRITE      = req_write_q;
        PSTRB       = req_write_q ? req_strb_q : '0;
        PPROT       = req_prot_q;
        PENABLE     = 1'b0;
        PSEL        = '0;

        case (state_q)
            ST_IDLE: begin
                req_ready = 1'b1;
                if (req_valid) begin            // CPU가 요청을 보냈다면
                    req_addr_d  = req_addr;     // CPU가 보낸 주소를 기억
                    req_wdata_d = req_wdata;    // 쓸 데이터를 기억
                    req_strb_d  = req_write ? req_strb : '0;    // 쓰기면 Strobe도 기억
                    req_prot_d  = req_prot;     // 보호 신호 기 억
                    req_write_d = req_write;    // 쓰기 여부 기억
                    // 요청이 들어오면 주소 해독기(decode_psel)를 거쳐 타겟을 정하고 SETUP으로 넘어감
                    psel_d      = decode_psel(req_addr);
                    state_d     = ST_SETUP;
                end
            end

            ST_SETUP: begin
                // APB 규격에 맞게 주소와 선택신호를 먼저 쫙 깔아줌
                PADDR   = req_addr_q;   // 주소를 APB 버스에 올림
                PWDATA  = req_wdata_q;  // 데이터를 APB 버스에 올림
                PWRITE  = req_write_q;  // 읽기/쓰기 신호를 버스에 올림
                PSTRB   = req_write_q ? req_strb_q : '0;    // Strobe 올림
                PPROT   = req_prot_q;   // 보호 신호 올림
                PSEL    = psel_q;       // 선택된 장치의 PSEL 핀을 1로 켬
                state_d = ST_ACCESS;    // 한 클럭만 준비하고 무조건 ACCESS 상태로 넘어감
            end

            ST_ACCESS: begin
                // 설정 유지
                PADDR   = req_addr_q;
                PWDATA  = req_wdata_q;
                PWRITE  = req_write_q;
                PSTRB   = req_write_q ? req_strb_q : '0;
                PPROT   = req_prot_q;
                PSEL    = psel_q;
                PENABLE = 1'b1;     // 여기서 PENABLE을 켜서 장치에 데이터를 밀어넣음

                // 만약 주소를 못 찾았거나 여러 개를 찾았다면 에러 처리
                if (decode_miss || decode_overlap) begin
                    rsp_valid = 1'b1;
                    rsp_rdata = '0;
                    rsp_err   = 1'b1;
                    state_d   = ST_IDLE;
                // 타겟 장치가 준비되었다고 응답하면 정상 처리 완료
                end else if (active_pready) begin
                    rsp_valid = 1'b1;       // CPU에게 작업 끝났다고 응답 보냄
                    rsp_rdata = active_prdata;  // 장치가 준 데이터를 CPU로 토스
                    rsp_err   = active_pslverr; // 장치가 에러 띄웠으면 같이 토스
                    state_d   = ST_IDLE;
                end
            end

            default: begin
                state_d = ST_IDLE;
            end
        endcase
    end

    // 클럭이 뛸 때마다 예약된 다음 상태(d)를 현재 상태(q)로 업데이트하는 순차 회로
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // 리셋 신호가 들어오면 모두 0으로 초기화
            state_q     <= ST_IDLE;
            req_addr_q  <= '0;
            req_wdata_q <= '0;
            req_strb_q  <= '0;
            req_prot_q  <= 3'b000;
            req_write_q <= 1'b0;
            psel_q      <= '0;
        end else begin
            // 리셋이 아니면 d 값을 q에 덮어씌움 (기억)
            state_q     <= state_d;
            req_addr_q  <= req_addr_d;
            req_wdata_q <= req_wdata_d;
            req_strb_q  <= req_strb_d;
            req_prot_q  <= req_prot_d;
            req_write_q <= req_write_d;
            psel_q      <= psel_d;
        end
    end

endmodule
