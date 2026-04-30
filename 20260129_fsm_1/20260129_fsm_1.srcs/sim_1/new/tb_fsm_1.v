`timescale 1ns / 1ps

module tb_fsm_1 ();

    reg clk, reset;
    reg  [2:0] sw;
    wire [2:0] led;


    fsm_1 dut (
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
        sw = 3'b000;
        #10;
        reset = 0;
        #10;
        sw = 3'b001;
        #10;
        sw = 3'b010;
        #10;
        sw = 3'b100;
        #10;  // s3
        sw = 3'b011;
        #10;  // s1
        sw = 3'b010;
        #10;  // s2
        sw = 3'b100;
        #10;  // s3
        sw = 3'b000;
        #10;  //s0
        sw = 3'b010;
        #10;  //s2
        sw = 3'b100;
        #10;  //s3
        sw = 3'b111;
        #10;  // s4
        sw = 3'b000;
        #10;  //s0
        $stop;
    end

endmodule
