`timescale 1ns / 1ps

module tb_stopwatch_watch ();

    reg clk, reset;
    reg [2:0] sw;
    reg btn_r, btn_l, btn_u, btn_d;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    top_stopwatch_watch dut (
        .clk      (clk),
        .reset    (reset),
        .sw       (sw),
        .btn_r    (btn_r),
        .btn_l    (btn_l),
        .btn_u    (btn_u),
        .btn_d    (btn_d),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        reset = 1;
        sw = 3'b000;
        btn_r = 0;
        btn_l = 0;
        btn_u = 0;
        btn_d = 0;

        #1_000_000_000;
        reset = 0;
        #1_000_000_000;
        sw[1] = 1'b1;
        #1_000_000_000;
        btn_r = 1;
        #1_000_000_000;
        btn_r = 0;
        #1_000_000_000;
        btn_u = 1;
        #1_000_000_000;
        btn_u = 0;
        #1_000_000_000;
        btn_l = 1;
        #1_000_000_000;
        btn_l = 0;
        #1_000_000_000;
        btn_d = 1;
        #1_000_000_000;
        btn_d = 0;

        #1_000_000_000;
        sw[1] = 1'b0;
        #1_000_000_000;
        btn_r = 1;
        #1_000_000_000;
        btn_r = 0;
        #1_000_000_000;
        btn_r = 1;
        #1_000_000_000;
        btn_r = 0;
        #1_000_000_000;
        btn_l = 1;
        #1_000_000_000;
        btn_l = 0;
        #1_000_000_000 
        $stop;
    end


endmodule
