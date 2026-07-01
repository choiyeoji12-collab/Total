`timescale 1ns / 1ps

module tb_vga_sw ();

    logic       clk;
    logic       reset;
    logic [3:0] sw_red;
    logic [3:0] sw_green;
    logic [3:0] sw_blue;
    logic       h_sync;
    logic       v_sync;
    logic [3:0] port_red;
    logic [3:0] port_green;
    logic [3:0] port_blue;

    VGA_SW_top dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);

        sw_red   = 4'hf;
        sw_green = 4'hf;
        sw_blue  = 4'hf;
        wait (!v_sync);
        @(posedge clk);
        wait (v_sync);
        @(posedge clk);
        wait (!v_sync);
        @(posedge clk);
        
        $finish;
    end
endmodule
