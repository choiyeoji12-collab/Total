`timescale 1ns / 1ps

module tb_uart_all;

    parameter BAUD = 9600;
    parameter BAUD_PERIOD = (100_000_000 / BAUD) * 10;

    reg clk, rst;
    reg uart_rx;
    wire uart_tx;

    reg [23:0] pc_uart;
    reg mode_sel;

    wire ascii_r, ascii_l, ascii_u, ascii_d, ascii_s;

    integer i;
    reg [7:0] test_data;

    //--------------------------------------------------
    // DUT
    //--------------------------------------------------
    uart_top dut (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .pc_uart(pc_uart),
        .mode_sel(mode_sel),
        .ascii_r(ascii_r),
        .ascii_l(ascii_l),
        .ascii_u(ascii_u),
        .ascii_d(ascii_d),
        .ascii_s(ascii_s)
    );

    //--------------------------------------------------
    // Clock
    //--------------------------------------------------
    always #5 clk = ~clk;

    //--------------------------------------------------
    // PC → FPGA UART 전송 Task
    //--------------------------------------------------
    task uart_sender;
        begin
            uart_rx = 0;
            #(BAUD_PERIOD);

            for(i=0;i<8;i=i+1) begin
                uart_rx = test_data[i];
                #(BAUD_PERIOD);
            end

            uart_rx = 1;
            #(BAUD_PERIOD);
        end
    endtask

    //--------------------------------------------------
    // FPGA → PC 수신기 (UART RX 재사용)
    //--------------------------------------------------
    wire pc_rx_done;
    wire [7:0] pc_rx_data;

    uart_rx U_PC_RX (
        .clk(clk),
        .rst(rst),
        .rx(uart_tx),
        .b_tick(dut.w_b_tick),
        .rx_data(pc_rx_data),
        .rx_done(pc_rx_done)
    );

    always @(posedge clk)
        if(pc_rx_done)
            $write("%c", pc_rx_data);

    //--------------------------------------------------
    // Simulation
    //--------------------------------------------------
    initial begin
        clk=0; rst=1; uart_rx=1;

        mode_sel=0;
        pc_uart={5'd1,6'd23,6'd45,7'd67};

        #50 rst=0;

        //------------------------------------------
        // Stopwatch 출력 테스트 ('s')
        //------------------------------------------
        test_data=8'h73; // 's'
        uart_sender();

        #80_000_000;

        //------------------------------------------
        // Watch 출력 테스트 ('w')
        //------------------------------------------
        mode_sel=1;
        pc_uart={5'd12,6'd34,6'd56,7'd78};

        test_data=8'h77; // 'w'
        uart_sender();

        #100_000_000;
        $stop;
    end

endmodule