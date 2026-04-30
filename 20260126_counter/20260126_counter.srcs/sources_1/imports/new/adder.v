`timescale 1ns / 1ps

module top_adder (
    input        clk,
    input        reset,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [7:0] w_sum;
    wire w_c;
    wire [13:0] w_cnt;

    fnd_controller U_FND_CNTL (
        .clk      (clk),
        .reset    (reset),
        .sum      ({w_cnt}),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );
    counter U_COUNTER (
        .clk(clk),
        .reset(reset),
        .cnt(w_cnt)
    );

endmodule
