`timescale 1ns / 1ps

module moore_0101_pattern (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);

    parameter S0 = 3'b000, S1 = 3'b001, S2 = 3'b010, S3 = 3'b011, S4 = 3'b100;

    reg [2:0] current_state, next_state;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= S0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            S0: begin
                if (din_bit == 1'b1) next_state = current_state;
                else next_state = S1;
            end
            S1: begin
                if (din_bit == 1'b1) next_state = S2;
                else next_state = current_state;
            end
            S2: begin
                if (din_bit == 1'b1) next_state = S0;
                else next_state = S3;
            end
            S3: begin
                if (din_bit == 1'b1) next_state = S4;
                else next_state = S1;
            end
            S4: begin
                if (din_bit == 1'b1) next_state = S0;
                else next_state = S1;
            end
            default: next_state = current_state;
        endcase
    end

    assign dout_bit = (current_state == S4) ? 1'b1 : 1'b0;

endmodule
