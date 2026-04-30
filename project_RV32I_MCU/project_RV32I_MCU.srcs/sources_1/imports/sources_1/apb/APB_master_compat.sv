`timescale 1ns / 1ps

// 주소록을 작성해서 브릿지에 꽂아주는 역할
// APB 마스터를 세팅하는 모듈 선언
module APB_master #(
    // 기본 도로 폭 설정
    parameter int ADDR_WIDTH = 32,  // 주소 폭 32비트
    parameter int DATA_WIDTH = 32,  // 데이터 폭 32비트
    // 장치 개수 설정
    parameter int NUM_SLAVES = 6,   // 주변 장치 6개

    // 6개 장치의 시작 주소록을 6칸짜리 배열로 묶어서 정의
    parameter logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] SLAVE_BASE = {
        32'h1000_0000,  // [0] RAM
        32'h2000_0000,  // [1] GPO
        32'h2000_1000,  // [2] GPI
        32'h2000_2000,  // [3] GPIO
        32'h2000_3000,  // [4] FND
        32'h2000_4000   // [5] UART
    },

    // 6개 장치의 주소 마스크(필터)를 6칸짜리 배열로 정의 
    parameter logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] SLAVE_MASK = {
        32'hFFFF_F000,  // [0] 장치 마스크 (앞자리 5개 FFFF_F 검사)  
        32'hFFFF_F000,  // [1] 장치 마스크
        32'hFFFF_F000,  // [2] 장치 마스크
        32'hFFFF_F000,  // [3] 장치 마스크
        32'hFFFF_F000,  // [4] 장치 마스크
        32'hFFFF_F000   // [5] 장치 마스크
    }
) (
    input logic PCLK,
    input logic PRESET,

    // CPU쪽 인터페이스
    input  logic [ADDR_WIDTH-1:0] Addr,     // CPU가 요청한 주소
    input  logic [DATA_WIDTH-1:0] Wdata,    // CPU가 쓸 데이터 
    input  logic                  WREQ,     // 쓰기 요청 신호
    input  logic                  RREQ,     // 읽기 요청 신호
    output logic [DATA_WIDTH-1:0] Rdata,    // CPU에게 돌려줄 읽은 데이터
    output logic                  Ready,    // CPU에게 "작업 완료" 알려줄 신호
    output logic                  SlvERR,   // CPU에게 "에러 발생" 알려줄 신호

    // APB 버스 쪽 인터페이스 (주변 장치들로 뻗어 나가는 선들)
    output logic [  ADDR_WIDTH-1:0] PADDR,      // APB 주소
    output logic [  DATA_WIDTH-1:0] PWDATA,     // APB 쓸 데이터
    output logic                    PENABLE,    // APB Enable 신호
    output logic                    PWRITE,     // APB 쓰기 여부 신호
    output logic [DATA_WIDTH/8-1:0] PSTRB,      // APB Strobe 신호
    output logic [             2:0] PPROT,      // APB 보호 신호

    // 각 장치별 전용 PSEL 스위치 선언
    output logic                    PSEL0,
    output logic                    PSEL1,
    output logic                    PSEL2,
    output logic                    PSEL3,
    output logic                    PSEL4,
    output logic                    PSEL5,

    // 장치별 전용으로 읽어오는 데이터 선들
    input logic [DATA_WIDTH-1:0] PRDATA0,
    input logic [DATA_WIDTH-1:0] PRDATA1,
    input logic [DATA_WIDTH-1:0] PRDATA2,
    input logic [DATA_WIDTH-1:0] PRDATA3,
    input logic [DATA_WIDTH-1:0] PRDATA4,
    input logic [DATA_WIDTH-1:0] PRDATA5,

    // 장치별 전용 PREADY(준비 완료) 신호 선들
    input logic                  PREADY0,
    input logic                  PREADY1,
    input logic                  PREADY2,
    input logic                  PREADY3,
    input logic                  PREADY4,
    input logic                  PREADY5,

    // 장치별 전용 PSLVERR(에러) 신호 선들
    input logic                  PSLVERR0,
    input logic                  PSLVERR1,
    input logic                  PSLVERR2,
    input logic                  PSLVERR3,
    input logic                  PSLVERR4,
    input logic                  PSLVERR5
);

    // 내부에서 브릿지와 연결하기 위한 임시 선들 선언
    logic                                  req_valid;       // CPU 요청이 들어왔는지 묶을 변수
    logic                                  req_ready;
    logic                                  rsp_valid;
    logic                                  rsp_err;
    logic [NUM_SLAVES-1:0]                 psel_bus;        // 6가닥짜리 PSEL 묶음
    logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0] prdata_bus;      // 6개 장치의 데이터 묶음
    logic [NUM_SLAVES-1:0]                 pready_bus;      // 6개 장치의 준비 묶음
    logic [NUM_SLAVES-1:0]                 pslverr_bus;     // 6개 장치의 에러 묶음

    // 쓰기(WREQ)나 읽기(RREQ) 중 하나라도 1이면 req_valid를 1로 만듦
    assign req_valid      = WREQ | RREQ;
    assign Ready          = rsp_valid;  // 브릿지가 끝났다고 하면 CPU Ready도 1로 켬
    assign SlvERR         = rsp_err;    // 브릿지가 에러 났다고 하면 CPU 에러도 1로 켬

    // 6가닥짜리 묶음선(psel_bus)의 각 비트를 개별 PESL 핀으로 쪼개서 연결
    assign PSEL0          = psel_bus[0];
    assign PSEL1          = psel_bus[1];
    assign PSEL2          = psel_bus[2];
    assign PSEL3          = psel_bus[3];
    assign PSEL4          = psel_bus[4];
    assign PSEL5          = psel_bus[5];

    // 개별 PRDATA 핀으로 들어온 데이터를 묶음선(prdata_bus)으로 합침
    assign prdata_bus[0]  = PRDATA0;
    assign prdata_bus[1]  = PRDATA1;
    assign prdata_bus[2]  = PRDATA2;
    assign prdata_bus[3]  = PRDATA3;
    assign prdata_bus[4]  = PRDATA4;
    assign prdata_bus[5]  = PRDATA5;

    // 개별 PREADY 핀을 묶음선(pready_bus)으로 합침
    assign pready_bus[0]  = PREADY0;
    assign pready_bus[1]  = PREADY1;
    assign pready_bus[2]  = PREADY2;
    assign pready_bus[3]  = PREADY3;
    assign pready_bus[4]  = PREADY4;
    assign pready_bus[5]  = PREADY5;

    // 개별 PSLVERR 핀을 묶음선(pslverr_bus)으로 합침
    assign pslverr_bus[0] = PSLVERR0;
    assign pslverr_bus[1] = PSLVERR1;
    assign pslverr_bus[2] = PSLVERR2;
    assign pslverr_bus[3] = PSLVERR3;
    assign pslverr_bus[4] = PSLVERR4;
    assign pslverr_bus[5] = PSLVERR5;

    // apb_mmio_bridge 붙이기
    apb_mmio_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),        // 설정값 넘겨줌
        .DATA_WIDTH(DATA_WIDTH),        // 설정값 넘겨줌    
        .STRB_WIDTH(DATA_WIDTH / 8),    // 설정값 넘겨줌
        .NUM_SLAVES(NUM_SLAVES),        // 장치 개수 넘겨줌        
        .SLAVE_BASE(SLAVE_BASE),        // 6개의 주소록 배열을 통째로 넘겨줌
        .SLAVE_MASK(SLAVE_MASK)         // 6개의 마스크 배열을 통째로 넘겨줌
    ) u_bridge (
        .PCLK     (PCLK),
        .PRESETn  (~PRESET),
        .req_valid(req_valid),
        .req_ready(req_ready),
        .req_addr (Addr),   
        .req_write(WREQ),
        .req_wdata(Wdata),
        .req_strb (WREQ ? '1 : '0),  // 쓰기일 땐 Strobe를 모두 1로 채움
        .req_prot (3'b000),          // 보호 신호 기본값 0
        .rsp_valid(rsp_valid),
        .rsp_rdata(Rdata),
        .rsp_err  (rsp_err),

        .PADDR    (PADDR),
        .PWRITE   (PWRITE),
        .PENABLE  (PENABLE),
        .PWDATA   (PWDATA),
        .PSTRB    (PSTRB),
        .PPROT    (PPROT),

        .PSEL     (psel_bus),   // 타겟 선택 신호
        .PRDATA   (prdata_bus), // 읽은 데이터들
        .PREADY   (pready_bus), // 장치 준비 상태
        .PSLVERR  (pslverr_bus) // 장치 에러 상태
    );

endmodule
