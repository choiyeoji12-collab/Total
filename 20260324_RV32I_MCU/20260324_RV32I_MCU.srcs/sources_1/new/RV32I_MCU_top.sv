`timescale 1ns / 1ps

module RV32I_MCU_top (
    input clk,
    input rst,

    input [7:0] GPI,  // 외부에서 들어오는 스위치/버튼 신호
    output [7:0] GPO,  // 외부로 나가는 LED 신호
    inout [15:0] GPIO,  // 양방향 제어가 가능한 외부 핀
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    input uart_rx,
    output uart_tx
);

    logic [2:0] o_funct3;
    // CPU와 APB Master(버스 컨트롤러) 사이를 연결하는 전용 신호선
    logic [31:0] instr_addr, instr_data, bus_addr, bus_wdata, bus_rdata;
    logic bus_wreq, bus_rreq, bus_ready;

    // APB 버스 표준 신호선들 (Master가 만들어서 Slave들에게 뿌려주는 공통 도로)
    logic [31:0] PADDR, PWDATA;
    logic PENABLE, PWRITE;
    // 주소 디코더가 만들어내는 모듈 선택 신호
    logic PSEL0, PSEL1, PSEL2, PSEL3, PSEL4, PSEL5;
    // 각 주변장치(Slave)들이 Master(CPU쪽)로 다시 보내는 데이터와 준비 신호
    logic [31:0] PRDATA0, PRDATA1, PRDATA2, PRDATA3, PRDATA4, PRDATA5;
    logic PREADY0, PREADY1, PREADY2, PREADY3, PREADY4, PREADY5;

    // 명령어 메모리 (ROM): CPU가 읽어갈 프로그램(기계어)이 들어있는 곳
    instruction_mem U_INSTRUCTION_MEM (.*);

    // RISC-V CPU 코어: 시스템의 두뇌
    RV32I_cpu U_RV32I (
        .*,
        .o_funct3(o_funct3)
    );

    // APB Master (버스 컨트롤러)
    // CPU의 단순한 Read/Write 요청을 APB 표준 규격(상태 머신)에 맞게 변환하여 주변장치에 전달
    APB_Master U_APB_MASTER (
        .PCLK   (clk),
        .PRESET (rst),
        // CPU쪽 연결
        .Addr   (bus_addr),   // from cpu
        .Wdata  (bus_wdata),  // from cpu
        .WREQ   (bus_wreq),   // from cpu, Write request, signal cpu : dwe
        .RREQ   (bus_rreq),   // from cpu, Read request, signal cpu : dre
        .Rdata  (bus_rdata),
        .Ready  (bus_ready),
        // APB Slave쪽 공통 연결 (Bus -> Peripherals)
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PENABLE(PENABLE),
        .PWRITE (PWRITE),
        // 각 주변장치로 뻗어나가는 개별 전용선들 (선택 신호, 데이터 수신)
        .PSEL0  (PSEL0),
        .PSEL1  (PSEL1),
        .PSEL2  (PSEL2),
        .PSEL3  (PSEL3),
        .PSEL4  (PSEL4),
        .PSEL5  (PSEL5),
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
        .PREADY5(PREADY5)

    );

    // 데이터 메모리 (RAM) 주소: PSEL0
    BRAM U_BRAM (
        .*,
        .PCLK  (clk),
        .PSEL  (PSEL0),
        .PRDATA(PRDATA0),
        .PREADY(PREADY0)
    );

    // 범용 출력 장치 (GPO): PSEL1
    GPO U_APB_GPO (
        .PCLK   (clk),
        .PRESET (rst),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PWRITE (PWRITE),
        .PENABLE(PENABLE),
        .PSEL   (PSEL1),
        .PRDATA (PRDATA1),
        .PREADY (PREADY1),
        .GPO_OUT(GPO)
    );

    // 범용 입력 장치 (GPI): PSEL2
    GPI U_APB_GPI (
        .PCLK   (clk),
        .PRESET (rst),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PENABLE(PENABLE),
        .PWRITE (PWRITE),
        .PSEL   (PSEL2),
        .GPI    (GPI),
        .PRDATA (PRDATA2),
        .PREADY (PREADY2)
    );

    // 양방향 입출력 장치 (GPIO): PSEL3
    GPIO U_APB_GPIO (
        .PCLK   (clk),
        .PRESET (rst),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PENABLE(PENABLE),
        .PWRITE (PWRITE),
        .PSEL   (PSEL3),
        .PRDATA (PRDATA3),
        .PREADY (PREADY3),
        .GPIO   (GPIO)
    );

    FND U_APB_FND (
        .PCLK     (clk),
        .PRESET   (rst),
        .PADDR    (PADDR),
        .PWDATA   (PWDATA),
        .PWRITE   (PWRITE),
        .PENABLE  (PENABLE),
        .PSEL     (PSEL4),
        .PRDATA   (PRDATA4),
        .PREADY   (PREADY4),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    UART U_APB_UART (
        .PCLK   (clk),
        .PRESET (rst),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PWRITE (PWRITE),
        .PENABLE(PENABLE),
        .PSEL   (PSEL5),
        .PRDATA (PRDATA5),
        .PREADY (PREADY5),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    // 원래는 CPU가 직접 data_mem과 소통했지만, 이제는 모든 통신이 'APB 버스'를 거쳐
    // BRAM과 소통하도록 아키텍처가 업그레이드 되었음
    //    data_mem U_DATA_MEM (
    //        .*,
    //        .i_funct3(o_funct3)
    //    );

endmodule
