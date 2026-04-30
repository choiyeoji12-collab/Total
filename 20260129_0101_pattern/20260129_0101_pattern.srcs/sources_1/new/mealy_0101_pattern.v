`timescale 1ns / 1ps

module mealy_0101_pattern (
    input  clk,
    input  rst,
    input  din_bit,
    output reg dout_bit
);

    reg [1:0] current_state, next_state;

    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= S0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        dout_bit = 1'b0;
        case (current_state)
            S0: begin
                dout_bit = 1'b0;
                if (din_bit == 1'b1) next_state = current_state;
                else next_state = S1;
            end
            S1: begin
                dout_bit = 1'b0;
                if (din_bit == 1'b1) next_state = S2;
                else next_state = current_state;
            end
            S2: begin
                dout_bit = 1'b0;
                if (din_bit == 1'b1) next_state = S0;
                else next_state = S3;
            end
            S3: begin
                if (din_bit == 1'b1) begin
                    next_state = S0;
                    dout_bit = 1'b1;
                end else begin
                    next_state = S1;
                    dout_bit = 1'b0;
            end
            end
            default: begin
                next_state = S0;
                dout_bit = 1'b0;
            end
        endcase
    end


    

endmodule
