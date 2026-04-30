`timescale 1ns / 1ps

module tb_twice_01_fsm_mealy ();

    reg clk, rst, din_bit;
    wire dout_bit;

    seq_det_mealy dut(
    .clk(clk),
    .rst(rst),
    .din_bit(din_bit),
    .dout_bit(dout_bit)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        din_bit = 0;
        #30;
        rst=0;
        #10;
        din_bit = 1;
        #30;
        din_bit = 0;
        #20;
        din_bit = 1;
        #40;
        din_bit = 0;
        #80;
        din_bit = 1;
        #20;
        din_bit = 0;
        #60;
        din_bit = 1;
        #80;
        din_bit = 0;
        #10;
        $stop;


    end



endmodule
