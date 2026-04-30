`timescale 1ns / 1ps

module tb_adder;

    // tb_adder local veriable
    reg [7:0] a, b;
    wire [7:0] sum;

    integer i = 0, j = 0;  // data type : 2 type, 32bit

    adder dut (
        .a  (a),
        .b  (b),
        .sum(sum),
        .c  (c)
    );

    // init
    initial begin
        #0;
        a = 8'b000_0000;
        b = 8'b000_0000;
        #10;

        for (i = 0; i < 256; i = i + 1) begin
          for (j = 0; j < 256; j = j + 1) begin
            a = i;
            b = j;
            #10; 
          end
        end

    $stop;
    end


endmodule
