`timescale 1ns / 1ps

module tb_fsm_moore ();

    reg clk, reset, sw;
    wire led;

    fsm_moore dut (
        .clk(clk), 
        .reset(reset), 
        .sw(sw), 
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        reset = 1;
        sw = 0;

        #5;
        reset = 0;

        #20;
        sw = 1;

        #20;
        sw = 0;

        #20;
        $stop;

    end

endmodule
