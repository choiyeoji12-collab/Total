`timescale 1ns / 1ps

module tb_rv32i();
    logic clk, rst;
    logic [15:0] GPI;
    wire [7:0] GPO;
    wire [15:0] GPIO;

    RV32I_MCU_top dut (
        .clk (clk),
        .rst (rst),
        .GPI (GPI),
        .GPO (GPO),
        .GPIO(GPIO)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        GPI = 8'h00;

        @(negedge clk);
        @(negedge clk);
        rst = 0;
        GPI = 8'haa;

        repeat (200) @(negedge clk);
        $stop;

    end

endmodule
