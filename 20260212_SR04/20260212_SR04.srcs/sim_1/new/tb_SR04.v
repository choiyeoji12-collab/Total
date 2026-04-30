`timescale 1ns / 1ps

module tb_SR04();

    reg clk;
    reg rst;
    reg btn_r;
    reg echo;
    wire trigger;
    wire [23:0] dist;

SR04 dut(
    .clk(clk),
    .rst(rst),
    .btn_r(btn_r),
    .echo(echo),
    .trigger(trigger),
    .dist(dist)
);

    always #5 clk = ~clk;

initial begin
    #0;
    clk = 0;
    rst = 1;
    btn_r = 0;
    echo = 0;

    #100;
    rst = 0;
    
    #1000;
    btn_r = 1;
    #200_000;
    btn_r = 0;

    #100_000
    echo = 1;
    #581_000;    
    echo = 0;

    #1000;
    $finish;
end

endmodule
