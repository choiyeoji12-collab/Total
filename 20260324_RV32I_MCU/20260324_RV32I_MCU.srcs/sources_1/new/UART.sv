`timescale 1ns / 1ps

// CPU가 APB 버스를 통해 UART를 제어할 수 있도록 하는 Wrapper 모듈
module UART (
    input               PCLK,
    input               PRESET,
    // APB Interface
    input        [31:0] PADDR,
    input        [31:0] PWDATA,
    input               PWRITE,
    input               PENABLE,
    input               PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // 외부 UART 핀
    input               uart_rx,
    output              uart_tx
);

    localparam [11:0] UART_TX_ADDR   = 12'h000;  // Write: TX 데이터 전송
    localparam [11:0] UART_RX_ADDR   = 12'h004;  // Read: RX 데이터 수신
    localparam [11:0] UART_STAT_ADDR = 12'h008;  // Read: FIFO 상태 확인 (Full/Empty)

    logic        tx_push;
    logic [ 7:0] tx_data_in;
    logic        tx_full;
    logic        tx_empty;

    logic        rx_pop;
    logic [ 7:0] rx_data_out;
    logic        rx_full;
    logic        rx_empty;

    // APB Ready 신호: 항상 준비 완료
    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    // ----------------------------------------------------
    // Write 로직: CPU -> UART (TX)
    // ----------------------------------------------------
    // CPU가 TX_ADDR에 데이터를 '쓸(Write)' 때, PENABLE 타이밍에 맞춰 TX FIFO에 Push(1) 신호를 줍니다.
    assign tx_push    = (PSEL & PENABLE & PWRITE & (PADDR[11:0] == UART_TX_ADDR)) ? 1'b1 : 1'b0;
    assign tx_data_in = PWDATA[7:0];

    // ----------------------------------------------------
    // Read 로직: UART (RX & Status) -> CPU
    // ----------------------------------------------------
    // CPU가 RX_ADDR에서 데이터를 '읽을(Read)' 때, PENABLE 타이밍에 맞춰 RX FIFO에서 Pop(1) 신호를 줍니다.
    assign rx_pop = (PSEL & PENABLE & ~PWRITE & (PADDR[11:0] == UART_RX_ADDR)) ? 1'b1 : 1'b0;

    always_comb begin
        PRDATA = 32'd0;
        if (PSEL & ~PWRITE) begin
            case (PADDR[11:0])
                UART_RX_ADDR:   PRDATA = {24'd0, rx_data_out}; // 받은 데이터 출력
                UART_STAT_ADDR: PRDATA = {30'd0, rx_empty, tx_full}; // 상태 출력 ([1]: RX 빔?, [0]: TX 꽉참?)
                default:        PRDATA = 32'hxxxx_xxxx;
            endcase
        end
    end

    // ----------------------------------------------------
    // UART 내부 모듈 인스턴스화
    // ----------------------------------------------------
    wire w_b_tick;
    wire w_rx_done;
    wire [7:0] w_rx_data;
    wire [7:0] w_tx_fifo_pop_data;
    wire w_tx_busy;

    // Baudrate 생성기
    baud_tick U_BAUD_TICK (
        .clk   (PCLK),
        .rst   (PRESET),
        .b_tick(w_b_tick)
    );

    // UART RX 모듈 (수신)
    uart_rx U_UART_RX (
        .clk    (PCLK),
        .rst    (PRESET),
        .rx     (uart_rx),
        .b_tick (w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    // RX FIFO (수신된 데이터를 임시 저장)
    // uart_rx에서 완료(done) 신호가 오면 넣고(push), CPU가 읽어갈 때 뺍니다(pop).
    fifo U_FIFO_RX (
        .clk      (PCLK),
        .rst      (PRESET),
        .push     (w_rx_done),
        .pop      (rx_pop),           // CPU가 값을 읽어가면 Pop!
        .push_data(w_rx_data),
        .pop_data (rx_data_out),      // CPU로 전달
        .full     (rx_full),
        .empty    (rx_empty)
    );

    // TX FIFO (보낼 데이터를 임시 저장)
    // CPU가 값을 쓰면 넣고(push), uart_tx가 한가할 때 뺍니다(pop).
    fifo U_FIFO_TX (
        .clk      (PCLK),
        .rst      (PRESET),
        .push     (tx_push),          // CPU가 값을 쓰면 Push!
        .pop      (~w_tx_busy),       // TX 모듈이 한가해지면 Pop해서 전송
        .push_data(tx_data_in),       // CPU에서 전달
        .pop_data (w_tx_fifo_pop_data),
        .full     (tx_full),
        .empty    (tx_empty)
    );

    // UART TX 모듈 (송신)
    uart_tx U_UART_TX (
        .clk     (PCLK),
        .rst     (PRESET),
        .tx_start(~tx_empty),         // TX FIFO에 보낼 게 있으면 시작
        .b_tick  (w_b_tick),
        .tx_data (w_tx_fifo_pop_data),
        .tx_busy (w_tx_busy),
        .tx_done (),
        .uart_tx (uart_tx)
    );

endmodule