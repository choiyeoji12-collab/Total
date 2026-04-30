`timescale 1ns / 1ps

module fsm_1 (
    input        clk,
    input        reset,
    input  [2:0] sw,
    output [2:0] led
);

    // state define
    parameter S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4;

    // state reg veriable
    reg [2:0] current_state, next_state;
    reg [2:0] current_led, next_led;

    // output 
    assign led = current_led;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= S0;
            current_led   <= 3'b000;
        end else begin
            current_state <= next_state;
            current_led   <= next_led;
        end
    end

    always @(*) begin
        next_state = current_state;
        // to init led CL output for full case
        next_led   = current_led;
        case (current_state)
            S0: begin
                // output
                next_led = 3'b000;
                if (sw == 3'b001) begin
                    next_state = S1;
                end else if (sw == 3'b010) begin
                    next_state = S2;
                end
            end
            S1: begin
                next_led = 3'b001;
                if (sw == 3'b010) begin
                    next_state = S2;
                end
            end
            S2: begin
                next_led = 3'b010;
                if (sw == 3'b100) begin
                    next_state = S3;
                end
            end
            S3: begin
                next_led = 3'b100;
                if (sw == 3'b000) begin
                    next_state = S0;
                end else if (sw == 3'b011) begin
                    next_state = S1;
                end else if (sw == 3'b111) begin
                    next_state = S4;
                end else begin
                    next_state = current_state;
                end
            end
            S4: begin
                next_led = 3'b111;
                if (sw == 3'b000) begin
                    next_state = S0;
                end
            end
        endcase
    end


endmodule
