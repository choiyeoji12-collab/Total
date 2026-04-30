`timescale 1ns / 1ps

module tb_fnd_controller;

    reg        clk, reset;
    reg  [7:0] a, b;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    // integer i = 0, j = 0;

    top_adder dut (
        .a        (a),
        .b        (b),
        .clk      (clk),
        .reset    (reset),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        a = 0;
        b = 0;
        clk = 0;
        reset = 1;

        #10;
        a = 8'd2;
        b = 8'd8;
        reset = 0;

        #2000;
        a = 8'd71;
        b = 8'd7;

        #2000;
        a = 8'd98;
        b = 8'd57;

        #2000;
        a = 8'd150;
        b = 8'd41;

        #3000;
        $stop;

    end
endmodule
