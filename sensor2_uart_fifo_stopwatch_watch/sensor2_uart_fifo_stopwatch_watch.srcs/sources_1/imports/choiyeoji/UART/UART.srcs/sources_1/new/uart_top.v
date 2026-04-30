`timescale 1ns / 1ps

module uart_top (
    input        clk,
    input        rst,
    input  [2:0] sw,
    input        btn_r,
    input        btn_l,
    input        btn_d,
    input        btn_u,
    input        uart_rx,
    output       uart_tx,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire btn_r_db, btn_l_db, btn_u_db, btn_d_db;

    btn_debounce U_BD_R (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_r),
        .o_btn(btn_r_db)
    );

    btn_debounce U_BD_L (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_l),
        .o_btn(btn_l_db)
    );

    btn_debounce U_BD_U (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_u),
        .o_btn(btn_u_db)
    );

    btn_debounce U_BD_D (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_d),
        .o_btn(btn_d_db)
    );

    wire w_b_tick;
    wire [7:0] rx_data;
    wire rx_done;

    baud_tick U_BAUD_TICK (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    wire ascii_r, ascii_l, ascii_u, ascii_d, ascii_s;

    ascii_decoder U_ASCII_DECODER (
        .clk    (clk),
        .rst    (rst),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .ascii_r(ascii_r),
        .ascii_l(ascii_l),
        .ascii_u(ascii_u),
        .ascii_d(ascii_d),
        .ascii_s(ascii_s)
    );

//    wire final_r, final_l, final_u, final_d;
//    assign final_r = btn_r_db | ascii_r;
//    assign final_l = btn_l_db | ascii_l;
//    assign final_u = btn_u_db | ascii_u;
//    assign final_d = btn_d_db | ascii_d;
//    wire [23:0] pc_uart;

//    stopwatch_watch U_STOPWATCH_WATCH (
//        .clk      (clk),
//        .reset    (rst),
//        .sw       (sw),
//        .final_r  (final_r),
//        .final_l  (final_l),
//        .final_u  (final_u),
//        .final_d  (final_d),
//        .fnd_digit(fnd_digit),
//        .fnd_data (fnd_data),
//        .pc_uart  (pc_uart)
//    );

    wire s_tx_start;
    wire [7:0] s_tx_data;
    wire tx_busy, tx_done;

    ascii_sender U_ASCII_SENDER (
        .clk(clk),
        .rst(rst),
        .ascii_s(ascii_s),
        .mode_sel(sw[1]),
        .pc_uart(pc_uart),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx_start(s_tx_start),
        .tx_data(s_tx_data)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(s_tx_start),
        .b_tick  (w_b_tick),
        .tx_data (s_tx_data),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        .uart_tx (uart_tx)
    );
endmodule
