`timescale 1ns / 1ps

module ascii_sender (
    input             clk,
    input             rst,
    input             ascii_s,
    input             mode_sel,
    input      [23:0] pc_uart,
    input             tx_busy,
    input             tx_done,
    output reg        tx_start,
    output reg [ 7:0] tx_data
);

    wire [4:0] hour = pc_uart[23:19];
    wire [5:0] min = pc_uart[18:13];
    wire [5:0] sec = pc_uart[12:7];
    wire [6:0] msec = pc_uart[6:0];

    wire [3:0] h10 = hour / 10;
    wire [3:0] h01 = hour % 10;

    wire [3:0] m10 = min / 10;
    wire [3:0] m01 = min % 10;

    wire [3:0] s10 = sec / 10;
    wire [3:0] s01 = sec % 10;

    wire [3:0] ms10 = msec / 10;
    wire [3:0] ms01 = msec % 10;

    wire [7:0] send_buf [0:13];

    assign send_buf[0] = (mode_sel) ? "W" : "S";
    assign send_buf[1] = 8'h20;
    assign send_buf[2] = 8'h30 + h10;
    assign send_buf[3] = 8'h30 + h01;
    assign send_buf[4] = 8'h3A;
    assign send_buf[5] = 8'h30 + m10;
    assign send_buf[6] = 8'h30 + m01;
    assign send_buf[7] = 8'h3A;
    assign send_buf[8] = 8'h30 + s10;
    assign send_buf[9] = 8'h30 + s01;
    assign send_buf[10] = 8'h2E;
    assign send_buf[11] = 8'h30 + ms10;
    assign send_buf[12] = 8'h30 + ms01;
    assign send_buf[13] = 8'h0A;

    localparam IDLE = 2'd0, SEND = 2'd1, WAIT = 2'd2;

    reg [1:0] c_state, n_state;
    reg [3:0] send_cnt_reg, send_cnt_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            send_cnt_reg <= 4'b0;
        end else begin
            c_state <= n_state;
            send_cnt_reg <= send_cnt_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        send_cnt_next = send_cnt_reg;
        tx_start = 0;
        tx_data = 8'h00;

        case (c_state)
            IDLE: begin
                send_cnt_next = 0;
                if (ascii_s) begin
                    n_state = SEND;
                end
            end

            SEND: begin
                if (tx_busy == 0) begin
                    tx_start = 1;
                    tx_data = send_buf[send_cnt_reg];
                    n_state = WAIT;
                end
            end

            WAIT: begin
                if (tx_done) begin
                    if(send_cnt_reg == 4'd13) begin
                        n_state = IDLE;
                        send_cnt_next = 4'd0;
                    end else begin
                        send_cnt_next = send_cnt_reg + 1;
                        n_state = SEND;
                    end
                end
                end

        endcase
    end



endmodule
