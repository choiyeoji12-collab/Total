`timescale 1ns / 1ps
module top_sensor2_uart_fifo_stopwatch_watch (
    input        clk,
    input        rst,
    input  [3:0] sw,
    input        btn_r,
    input        btn_l,
    input        btn_u,
    input        btn_d,
    input        echo,
    input        uart_rx,
    output       trigger,
    output       uart_tx,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    inout        dhtio
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

    wire ascii_r, ascii_l, ascii_u, ascii_d, ascii_s;
    wire [23:0] watch_time;

    uart_top U_UART (
        .clk     (clk),
        .rst     (rst),
        .uart_rx (uart_rx),
        .uart_tx (uart_tx),
        .pc_uart (watch_time),
        .mode_sel(sw[1]),
        .ascii_r (ascii_r),
        .ascii_l (ascii_l),
        .ascii_u (ascii_u),
        .ascii_d (ascii_d),
        .ascii_s (ascii_s)
    );

    wire final_r = btn_r_db | ascii_r;
    wire final_l = btn_l_db | ascii_l;
    wire final_u = btn_u_db | ascii_u;
    wire final_d = btn_d_db | ascii_d;

    stopwatch_watch U_STOPWATCH_DATAPATH (
        .clk      (clk),
        .reset    (rst),
        .sw       (sw[2:0]),
        .final_r  (final_r),
        .final_l  (final_l),
        .final_u  (final_u),
        .final_d  (final_d),
        .pc_uart  (watch_time)
    );

    wire [23:0] dist_cm;

    SR04 U_SR04 (
        .clk    (clk),
        .rst    (rst),
        .btn_r  (btn_r),
        .echo   (echo),
        .trigger(trigger),
        .dist   (dist_cm)
    );

     wire [13:0] dist = (dist_cm > 9999) ? 14'd9999 : dist_cm[13:0];

    wire [3:0] dist_1000 = (dist / 1000) % 10;
    wire [3:0] dist_100 = (dist / 100) % 10;
    wire [3:0] dist_10 = (dist / 10) % 10;
    wire [3:0] dist_1 = (dist / 1) % 10;

    wire [15:0] dist_bcd4 = {dist_1000, dist_100, dist_10, dist_1};

    wire [15:0] humidity, temperature;
    wire dht11_done, dht11_valid;
    wire [2:0] dht11_debug;

    wire dht11_start = ascii_s | btn_d_db;

    dht11_countroller U_DHT11_CONTROLLER (
        .clk  (clk),
        .rst  (rst),
        .start(dht11_start),
        .humidity(humidity),
        .temperature(temperature),
        .dht11_done(dht11_done),
        .dht11_valid(dht11_valid),
        .debug(dht11_debug),
        .dhtio(dhtio)
    );

    wire [7:0] temp_int = temperature[15:8];
    wire [7:0] hum_int  = humidity[15:8];

    wire [15:0] temp_bcd4 = {4'd0, 4'd0, (temp_int/10)%10, temp_int%10};
    wire [15:0] hum_bcd4  = {4'd0, 4'd0, (hum_int/10)%10, hum_int%10};

    wire show_sensor;
    wire [1:0] sensor_page;

    display_control_unit U_DISP_CTRL (
        .clk        (clk),
        .rst        (rst),
        .sw         (sw),
        .btn_u      (btn_u_db),
        .btn_d      (btn_d_db),
        .show_sensor(show_sensor),
        .sensor_page(sensor_page)
    );

    reg [15:0] sensor;
    always @(*) begin
        case (sensor_page)
            2'd0: sensor = dist_bcd4;
            2'd1: sensor = temp_bcd4;
            2'd2: sensor = hum_bcd4;
            default: sensor = 16'hffff;
        endcase
    end
    
    fnd_controller U_FND_cNTL (
        .clk        (clk),
        .reset(rst),
        .sel_display(sw[2]),
        .display_mode(show_sensor),
        .display_bcd_data(sensor),
        .fnd_in_data(watch_time),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule
