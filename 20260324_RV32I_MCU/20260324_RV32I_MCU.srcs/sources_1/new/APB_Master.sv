`timescale 1ns / 1ps

// APB 버스 컨트롤러
module APB_Master (
    // BUS Global signal
    input PCLK,
    input PRESET,

    // CPU와 통신하는 신호들
    // Soc Internal signal with CPU
    input  logic [31:0] Addr,   // from cpu
    input  logic [31:0] Wdata,  // from cpu
    input  logic        WREQ,   // from cpu, Write request, signal cpu : dwe
    input  logic        RREQ,   // from cpu, Read request, signal cpu : dre
    // output logic        SlvERR,
    output logic [31:0] Rdata,
    output logic        Ready,

    // APB 버스 표준 신호들 (Slave로 감)
    // APB Interface signal
    output logic [31:0] PADDR,    // need register
    output logic [31:0] PWDATA,   // need register
    output logic        PENABLE,
    output logic        PWRITE,

    output logic        PSEL0,    // RAM
    output logic        PSEL1,    // GPO
    output logic        PSEL2,    // GPI
    output logic        PSEL3,    // GPIO
    output logic        PSEL4,    // FND
    output logic        PSEL5,    // UART

    input logic [31:0] PRDATA0,  // from RAM
    input logic [31:0] PRDATA1,  // from GPO
    input logic [31:0] PRDATA2,  // from GPI
    input logic [31:0] PRDATA3,  // from GPIO
    input logic [31:0] PRDATA4,  // from FND
    input logic [31:0] PRDATA5,  // from UART

    input logic PREADY0,  // from RAM
    input logic PREADY1,  // from GPO
    input logic PREADY2,  // from GPI
    input logic PREADY3,  // from GPIO
    input logic PREADY4,  // from FND
    input logic PREADY5   // from UART
);

    typedef enum {
        IDLE,   // 대기
        SETUP,  // 준비
        ACCESS  // 실행 
    } apb_state_e;

    apb_state_e c_state, n_state;

    logic [31:0] PADDR_next, PWDATA_next;
    logic decode_en, PWRITE_next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            c_state <= IDLE;
            PADDR   <= 32'd0;
            PWDATA  <= 32'd0;
            PWRITE  <= 1'b0;
        end else begin
            c_state <= n_state;
            PADDR   <= PADDR_next;
            PWDATA  <= PWDATA_next;
            PWRITE  <= PWRITE_next;
        end
    end

    // next
    always_comb begin
        decode_en   = 1'b0;
        PENABLE     = 1'b0;
        PADDR_next  = PADDR;
        PWDATA_next = PWDATA;
        PWRITE_next = PWRITE;
        n_state     = c_state;
        case (c_state)
            IDLE: begin
                decode_en   = 0;
                PENABLE     = 0;
                PADDR_next  = 32'd0;
                PWDATA_next = 32'd0;
                PWRITE_next = 1'b0;
                if (WREQ | RREQ) begin
                    PADDR_next  = Addr;     // CPU 주소를 버스 주소로 복사
                    PWDATA_next = Wdata;    // CPU 데이터를 버스 데이터로 복사
                    if (WREQ) begin
                        PWRITE_next = 1'b1; // Write mode ON
                    end else begin
                        PWRITE_next = 1'b0; // Read mode ON
                    end
                    n_state = SETUP;
                end
            end
            SETUP: begin
                decode_en = 1;  // 주소 디코딩하여 특정 장치의 PSEL ON
                PENABLE   = 0;  
                n_state   = ACCESS;
            end
            ACCESS: begin
                decode_en = 1;  // PSEL 계속 유지   
                PENABLE   = 1;  // Slave 활성화 명령
                //if (PREADY0|PREADY1|PREADY2|PREADY3|PREADY4|PREADY5) begin
                if (Ready) begin
                    n_state = IDLE;
                end
            end
        endcase
    end

    Address_Decoder U_ADDR_DECODER (
        .en   (decode_en),
        .addr (PADDR),
        .psel0(PSEL0),
        .psel1(PSEL1),
        .psel2(PSEL2),
        .psel3(PSEL3),
        .psel4(PSEL4),
        .psel5(PSEL5)
    );

    apb_mux U_APB_MUX (
        .sel    (PADDR),
        .PRDATA0(PRDATA0),
        .PRDATA1(PRDATA1),
        .PRDATA2(PRDATA2),
        .PRDATA3(PRDATA3),
        .PRDATA4(PRDATA4),
        .PRDATA5(PRDATA5),
        .PREADY0(PREADY0),
        .PREADY1(PREADY1),
        .PREADY2(PREADY2),
        .PREADY3(PREADY3),
        .PREADY4(PREADY4),
        .PREADY5(PREADY5),
        .Rdata  (Rdata),
        .Ready  (Ready)
    );

endmodule

module apb_mux (
    input        [31:0] sel,
    input        [31:0] PRDATA0,
    input        [31:0] PRDATA1,
    input        [31:0] PRDATA2,
    input        [31:0] PRDATA3,
    input        [31:0] PRDATA4,
    input        [31:0] PRDATA5,
    input               PREADY0,
    input               PREADY1,
    input               PREADY2,
    input               PREADY3,
    input               PREADY4,
    input               PREADY5,
    output logic [31:0] Rdata,
    output logic        Ready
);

    always_comb begin
        Rdata = 32'h000_0000;
        Ready = 1'b0;

        case (sel[31:28])  // instead of casex
            4'h1: begin
                Rdata = PRDATA0;
                Ready = PREADY0;
            end
            4'h2: begin
                case (sel[15:12])
                    4'h0: begin
                        Rdata = PRDATA1;
                        Ready = PREADY1;
                    end
                    4'h1: begin
                        Rdata = PRDATA2;
                        Ready = PREADY2;
                    end
                    4'h2: begin
                        Rdata = PRDATA3;
                        Ready = PREADY3;
                    end
                    4'h3: begin
                        Rdata = PRDATA4;
                        Ready = PREADY4;
                    end
                    4'h4: begin
                        Rdata = PRDATA5;
                        Ready = PREADY5;
                    end
                endcase
            end
            default: begin
                Rdata = 32'hxxxx_xxxx;
                Ready = 1'bx;
            end
        endcase
    end

endmodule
