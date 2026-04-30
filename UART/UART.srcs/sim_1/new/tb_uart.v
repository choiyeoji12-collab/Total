`timescale 1ns / 1ps

module tb_uart ();

    parameter BAUD = 9600;
    parameter BAUD_PERIOD = (100_000_000 / BAUD) * 10;  // 104_160

    reg clk, rst;
    reg [2:0] sw;
    reg btn_r, btn_l, btn_u, btn_d;
    reg           uart_rx;
    wire          uart_tx;
    wire    [3:0] fnd_digit;
    wire    [7:0] fnd_data;

    reg     [7:0] test_data;
    integer       i;

    uart_top dut (
        .clk      (clk),
        .rst      (rst),
        .sw       (sw),
        .btn_r    (btn_r),
        .btn_l    (btn_l),
        .btn_d    (btn_d),
        .btn_u    (btn_u),
        .uart_rx  (uart_rx),
        .uart_tx  (uart_tx),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    always #5 clk = ~clk;

    task uart_sender();
        begin
            // start 
            uart_rx = 0;
            #(BAUD_PERIOD);
            // data
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = test_data[i];
                #(BAUD_PERIOD);
            end
            // stop
            uart_rx = 1'b1;
            #(BAUD_PERIOD);
        end
    endtask

    task press_btn();
        begin
            btn_r = 1;
            #1_000_000;
            btn_r = 0;
            #1_000_000;
            btn_l = 1;
            #1_000_000;
            btn_l = 0;
            #1_000_000;
            btn_u = 1;
            #1_000_000;
            btn_u = 0;
            #1_000_000;
            btn_d = 1;
            #1_000_000;
            btn_d = 0;
        end
    endtask


    initial begin
        #0;
        clk     = 1'b0;
        rst     = 1'b1;
        uart_rx = 1'b1;
        sw      = 3'b000;
        btn_r   = 0;
        btn_l   = 0;
        btn_u   = 0;
        btn_d   = 0;

        repeat (5) @(posedge clk);
        rst = 1'b0;

        sw[1] = 0;
        test_data = 8'h72;
        uart_sender();
        test_data = 8'h6C;
        uart_sender();
        test_data = 8'h75;
        uart_sender();
        test_data = 8'h64;
        uart_sender();

        #(BAUD_PERIOD * 10);
        press_btn();
        #(BAUD_PERIOD * 10);
        test_data = 8'h73;
        uart_sender();
        #50_000_000;
        sw[1] = 1;
        #20_000_000;
        test_data = 8'h72;
        uart_sender();
        test_data = 8'h75;
        uart_sender();
        #20_000_000;
        test_data = 8'h73;
        uart_sender();
        #20_000_000;

        press_btn();

        #(BAUD_PERIOD * 10);

        $stop;
    end

endmodule
