`timescale 1ns / 1ps

module ascii_decoder (
    input            clk,
    input            rst,
    input      [7:0] rx_data,
    input            rx_done,
    output reg       ascii_r,
    output reg       ascii_l,
    output reg       ascii_u,
    output reg       ascii_d,
    output reg       ascii_s
);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            ascii_r <= 0;
            ascii_l <= 0;
            ascii_u <= 0;
            ascii_d <= 0;
            ascii_s <= 0;
        end else begin
            ascii_r <= 0;
            ascii_l <= 0;
            ascii_u <= 0;
            ascii_d <= 0;
            ascii_s <= 0;
            if (rx_done == 1) begin
                case (rx_data)
                    8'h72: ascii_r <= 1;
                    8'h6C: ascii_l <= 1;
                    8'h75: ascii_u <= 1;
                    8'h64: ascii_d <= 1;
                    8'h73: ascii_s <= 1;
                endcase
            end
        end
    end


endmodule
