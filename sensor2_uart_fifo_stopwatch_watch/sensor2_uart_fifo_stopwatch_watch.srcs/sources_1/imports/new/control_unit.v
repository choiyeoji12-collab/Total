`timescale 1ns / 1ps

module control_unit (
    input            clk,
    input            reset,
    input      [2:0] i_sw,
    input            i_btn_r,
    input            i_btn_l,
    input            i_btn_u,
    input            i_btn_d,
    output           o_stopwatch_mode,
    output reg       o_stopwatch_run,
    output reg       o_stopwatch_clear,
    output           o_watch_sel_r,
    output           o_watch_sel_l,
    output           o_watch_up,
    output           o_watch_down
);

    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    // reg variable
    reg [1:0] current_st, next_st;

    wire sw_watch_mode = i_sw[1];

    assign o_watch_sel_r = i_btn_r & sw_watch_mode;
    assign o_watch_sel_l = i_btn_l & sw_watch_mode;
    assign o_watch_up    = i_btn_u & sw_watch_mode;
    assign o_watch_down  = i_btn_d & sw_watch_mode;

    wire sw_stopwatch_run = i_btn_r & (!sw_watch_mode);
    wire sw_stopwatch_clear = i_btn_l & (!sw_watch_mode);
    assign o_stopwatch_mode = i_sw[0];

    // state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= STOP;
        end else begin
            current_st <= next_st;
        end
    end


    // next CL
    always @(*) begin
        next_st    = current_st;
        o_stopwatch_run = 1'b0;
        o_stopwatch_clear    = 1'b0;
        case (current_st)
            STOP: begin
                // moore output
                o_stopwatch_run   = 1'b0;
                o_stopwatch_clear = 1'b0;
                if (sw_stopwatch_run) begin
                    next_st = RUN;
                end else if (sw_stopwatch_clear) begin
                    next_st = CLEAR;
                end
            end
            RUN: begin
                o_stopwatch_run   = 1'b1;
                o_stopwatch_clear = 1'b0;
                if (sw_stopwatch_run) begin
                    next_st = STOP;
                end
            end
            CLEAR: begin
                o_stopwatch_run = 1'b0;
                o_stopwatch_clear = 1'b1;
                next_st = STOP;
            end
            default: next_st = STOP;
        endcase
    end


endmodule
