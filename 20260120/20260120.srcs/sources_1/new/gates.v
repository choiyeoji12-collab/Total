`timescale 1ns / 1ps

//top module
module gates(
    // input a,b,
    input a,
    input b,
    // output
    output y0, 
    output y1, 
    output y2, 
    output y3, 
    output y4, 
    output y5, 
    output y6
);

    // AND gate
    assign y0 = a & b;
    // NAND gate
    assign y1 = ~(a & b);
    // OR gate
    assign y2 = a | b;
    // NOR gate
    assign y3 = ~(a | b);
    // ExOR gate
    assign y4 = a ^ b;
    //ExNOR gate
    assign y5 = ~(a ^ b);
    // Not gate
    assign y6 = ~a;


endmodule
