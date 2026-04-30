`timescale 1ns / 1ps

module Top_module_tb;

    logic        clk;
    logic        rst;
    logic        i_uart_rx;
    logic [7:0]  i_dbg_result_idx;
    logic        o_uart_tx;

    Top_module U_DUT (
        .clk             (clk),
        .rst             (rst),
        .i_uart_rx       (i_uart_rx),
        .o_uart_tx       (o_uart_tx),
        .i_dbg_result_idx(i_dbg_result_idx)
    );

    always #5 clk = ~clk;

    initial begin
        clk              = 1'b0;
        rst              = 1'b1;
        i_uart_rx        = 1'b1;
        i_dbg_result_idx = 8'h00;

        repeat (20) @(posedge clk);
        rst = 1'b0;
    end

    initial begin
        $display("[%0t] TB start", $time);

        wait (!rst);
        $display("[%0t] Reset released", $time);

        wait (U_DUT.w_cpu_mem_valid);
        $display("[%0t] CPU mem request addr=%08h write=%0d funct3=%0h",
                 $time,
                 U_DUT.w_cpu_mem_addr,
                 U_DUT.w_cpu_mem_write,
                 U_DUT.w_cpu_mem_funct3);

        wait (U_DUT.w_apb_req_valid);
        $display("[%0t] APB request addr=%08h write=%0d wdata=%08h",
                 $time,
                 U_DUT.w_apb_req_addr,
                 U_DUT.w_apb_req_write,
                 U_DUT.w_apb_req_wdata);

        wait (U_DUT.U_APB.w_psel5 && U_DUT.U_APB.w_penable && U_DUT.U_APB.w_pwrite);
        $display("[%0t] UART APB access paddr=%08h pwdata=%08h",
                 $time,
                 U_DUT.U_APB.w_paddr,
                 U_DUT.U_APB.w_pwdata);

        wait (U_DUT.U_APB.U_UART.tx_push);
        $display("[%0t] UART tx_push data=%02h",
                 $time,
                 U_DUT.U_APB.w_pwdata[7:0]);

        wait (o_uart_tx == 1'b0);
        $display("[%0t] UART TX start bit observed", $time);

        repeat (200000) @(posedge clk);
        $display("[%0t] TB done", $time);
        $finish;
    end

    initial begin
        repeat (5000000) @(posedge clk);
        $fatal(1, "[%0t] Timeout waiting for UART activity", $time);
    end

endmodule
