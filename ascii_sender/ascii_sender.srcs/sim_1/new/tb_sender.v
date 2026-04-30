`timescale 1ns / 1ps

module tb_sender ();

    parameter BAUD = 9600;
    parameter BAUD_PERIOD = (100_000_000 / BAUD) * 10;  // 104_160

    reg clk, rst;
    reg [2:0] sw;
    reg btn_r, btn_l, btn_u, btn_d;

    // PC -> FPGA (DUT RX)
    reg  uart_rx;

    // FPGA (DUT TX) -> PC
    wire uart_tx;

    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    reg     [7:0] test_data;
    integer       i;

    reg  [23:0] pc_uart;
    reg         mode_sel;
    wire        ascii_r, ascii_l, ascii_u, ascii_d, ascii_s;

    uart_top dut (
        .clk     (clk),
        .rst     (rst),
        .uart_rx (uart_rx),
        .uart_tx (uart_tx),
        .pc_uart (pc_uart),
        .mode_sel(mode_sel),
        .ascii_r (ascii_r),
        .ascii_l (ascii_l),
        .ascii_u (ascii_u),
        .ascii_d (ascii_d),
        .ascii_s (ascii_s)
    );

    // 100MHz clock
    always #5 clk = ~clk;

    task uart_sender();
        begin
            // start bit
            uart_rx = 1'b0;
            #(BAUD_PERIOD);

            // data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = test_data[i];
                #(BAUD_PERIOD);
            end

            // stop bit
            uart_rx = 1'b1;
            #(BAUD_PERIOD);
        end
    endtask

    task press_btn();
        begin
            btn_r = 1; #1_000_000; btn_r = 0; #1_000_000;
            btn_l = 1; #1_000_000; btn_l = 0; #1_000_000;
            btn_u = 1; #1_000_000; btn_u = 0; #1_000_000;
            btn_d = 1; #1_000_000; btn_d = 0;
        end
    endtask

    wire       pc_rx_done;
    wire [7:0] pc_rx_data;

    uart_rx U_PC_RX (
        .clk    (clk),
        .rst    (rst),
        .rx     (uart_tx),    
        .b_tick (dut.w_b_tick), 
        .rx_data(pc_rx_data),
        .rx_done(pc_rx_done)
    );

    always @(posedge clk) begin
        if (pc_rx_done) begin
            $write("%c", pc_rx_data);
        end
    end

    initial begin
        clk     = 1'b0;
        rst     = 1'b1;

        // UART RX idle high
        uart_rx = 1'b1;

        sw      = 3'b000;
        btn_r   = 0;
        btn_l   = 0;
        btn_u   = 0;
        btn_d   = 0;

        pc_uart  = 24'h00_0000; 
        mode_sel = 1'b0; 

        repeat (5) @(posedge clk);
        rst = 1'b0;

        test_data = 8'h72; uart_sender(); // 'r'
        test_data = 8'h6C; uart_sender(); // 'l'
        test_data = 8'h75; uart_sender(); // 'u'
        test_data = 8'h64; uart_sender(); // 'd'

        #(BAUD_PERIOD * 10);
        press_btn();
        #(BAUD_PERIOD * 10);

        pc_uart  = {5'd1, 6'd23, 6'd45, 7'd67}; // 01:23:45.67
        mode_sel = 1'b0; // "S"

        test_data = 8'h73; uart_sender(); // 's'

        #50_000_000;

        mode_sel = 1'b1; // "W"
        pc_uart  = {5'd12, 6'd34, 6'd56, 7'd78}; // 12:34:56.78

        test_data = 8'h73; uart_sender(); // 's'
        #50_000_000;

        press_btn();

        #(BAUD_PERIOD * 10);

        $stop;
    end

endmodule