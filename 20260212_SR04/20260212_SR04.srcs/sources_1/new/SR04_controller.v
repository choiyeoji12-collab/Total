`timescale 1ns / 1ps

module SR04 (
    input  clk,
    input  rst,
    input  btn_r,
    input  echo,
    output trigger,
    output [23:0] dist
);

    wire w_sr_start, w_tick_1usec;

tick_gen_1usec U_TICK_GEN_1USEC(
    .clk(clk),
    .rst(rst),
    .tick_1usec(w_tick_1usec)
);

btn_debounce U_BTN_DEBOUNCE(
    .clk(clk),
    .reset(rst),
    .i_btn(btn_r),
    .o_btn(w_sr_start)
);

SR04_controller U_SR04_CONTROLLER (
    .clk(clk),
    .rst(rst),
    .tick_1usec(w_tick_1usec),
    .sr_start(w_sr_start),
    .sr_echo(echo),
    .sr_trigger(trigger),
    .dist(dist)
);

endmodule

module SR04_controller (
    input       clk,
    input  rst,
    input tick_1usec,
    input  sr_start,
    input  sr_echo,
    output sr_trigger,
    output [23:0] dist
);

    localparam IDLE=2'd0, TRIGGER=2'd1, WAIT=2'd2, COUNT=2'd3;
    reg [1:0] c_state, n_state;

    reg  trigger_reg, trigger_next;
    reg [23:0] dist_reg, dist_next;
    reg [ 3:0] trigger_cnt_reg, trigger_cnt_next;

    assign sr_trigger = trigger_reg;
    assign dist = dist_reg;
    
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            c_state <= IDLE;
            trigger_reg <= 0;
            dist_reg <= 0;
            trigger_cnt_reg <= 0;
        end else begin
            c_state <= n_state;
            trigger_reg <= trigger_next;
            dist_reg <= dist_next;
            trigger_cnt_reg <= trigger_cnt_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        trigger_next = trigger_reg;
        dist_next = dist_reg;
        trigger_cnt_next = trigger_cnt_reg;
               
       case (c_state)
           IDLE : begin
               trigger_next = 0;
               trigger_cnt_next = 0;
               if (sr_start) begin
                   trigger_next = 1;
                   n_state = TRIGGER;
               end
           end
           TRIGGER : begin
               if(tick_1usec) begin
                   trigger_next = 1;
                   if(trigger_cnt_reg == 12) begin
                    trigger_next = 0;
                    trigger_cnt_next = 0;
                    n_state = WAIT;
                   end else begin
                    trigger_cnt_next = trigger_cnt_reg + 1;
                   end
               end
           end
           WAIT : begin
            trigger_next = 0;
               if(sr_echo) begin
                   dist_next <= 0;
                   n_state <= COUNT;
               end
           end
           COUNT : begin
            if(tick_1usec) begin
               if (sr_echo) begin
                   dist_next = dist_reg + 1;
               end else begin
                   dist_next = dist_reg / 58;
                   n_state = IDLE;
               end
           end
           end
       endcase
    end
endmodule


module tick_gen_1usec (
    input      clk,
    input      rst,
    output reg tick_1usec
);

    reg [$clog2(100)-1:0] r_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            tick_1usec <= 1'b0;
        end else begin
            r_counter <= r_counter + 1;
            tick_1usec <= 1'b0;
            if (r_counter == (100 - 1)) begin
                r_counter <= 0;
                tick_1usec <= 1'b1;
            end else begin
                tick_1usec <= 1'b0;
            end
        end
    end

endmodule
