`timescale 1ns / 1ps

module fsm_0 (
    input            clk,
    input            reset,
    input      [2:0] sw,
    output reg [1:0] led
);

    // state define
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;

    // state reg veriable
    reg [1:0] current_state, next_state;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= S0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        // this always initialize
        next_state = current_state;
        case (current_state)
            S0: begin
                if (sw == 3'b001) begin
                    next_state = S1;
                end else begin
                    next_state = current_state;
                end
            end
            S1: begin
                if (sw == 3'b010) begin
                    next_state = S2;
                end else begin
                    next_state = current_state;
                end
            end
            S2: begin
                if (sw == 3'b100) begin
                    next_state = S0;
                end
            end
            default: next_state = current_state;
        endcase
    end

    // output CL
    // assign led = (current_state == S1) ? 2'b01:
    //              (current_state == S2) ? 2'b11:2'b00;

    always @(*) begin
        case (current_state)
            S0: led = 2'b00;
            S1: led = 2'b01;
            S2: led = 2'b11;
            default: led = 2'b00;
        endcase
    end

endmodule
