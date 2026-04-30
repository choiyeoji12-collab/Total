`timescale 1ns / 1ps

module stopwatch_watch (
    input        clk,
    input        reset,
    input  [2:0] sw,         // sw[0] up/down, sw[1] watch/stopwatch select
    //input        btn_r_db,      // stopwatch: i_run_stop, watch: right
    //input        btn_l_db,      // stopwatch: i_clear, watch: left
    //input        btn_u_db,      // watch: up
    //input        btn_d_db,      // watch: down
    input       final_r,
    input       final_l,
    input       final_u,
    input       final_d,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [23:0] pc_uart
);

    wire w_mode, w_run_stop, w_clear;
    wire [23:0] w_stopwatch_time, w_watch_time, w_display_time;

    wire btn_watch_sel_r, btn_watch_sel_l, btn_watch_u, btn_watch_d;

    assign w_display_time = (sw[1]) ? w_watch_time : w_stopwatch_time;
    assign pc_uart = w_display_time;
   

    control_unit U_CONTROL_UNIT (
        .clk              (clk),
        .reset            (reset),
        .i_sw             (sw),
        .i_btn_r          (final_r),
        .i_btn_l          (final_l),
        .i_btn_u          (final_u),
        .i_btn_d          (final_d),
        .o_stopwatch_mode (w_mode),
        .o_stopwatch_run  (w_run_stop),
        .o_stopwatch_clear(w_clear),
        .o_watch_sel_r    (btn_watch_sel_r),
        .o_watch_sel_l    (btn_watch_sel_l),
        .o_watch_up       (btn_watch_u),
        .o_watch_down     (btn_watch_d)
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_mode),
        .clear   (w_clear),
        .run_stop(w_run_stop),
        .msec    (w_stopwatch_time[6:0]),    // 7 bit
        .sec     (w_stopwatch_time[12:7]),   // 6 bit     
        .min     (w_stopwatch_time[18:13]),  // 6 bit
        .hour    (w_stopwatch_time[23:19])   // 5 bit
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk    (clk),
        .reset  (reset),
        .i_sel_r(btn_watch_sel_r),
        .i_sel_l(btn_watch_sel_l),
        .i_up   (btn_watch_u),
        .i_down (btn_watch_d),
        .msec   (w_watch_time[6:0]),
        .sec    (w_watch_time[12:7]),
        .min    (w_watch_time[18:13]),
        .hour   (w_watch_time[23:19])
    );

    fnd_controller U_FND_cNTL (
        .clk        (clk),
        .reset      (reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_display_time),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule

module stopwatch_datapath (
    input        clk,
    input        reset,
    input        mode,
    input        clear,
    input        run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES    (24)
    ) hour_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_hour_tick),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .o_count (hour),
        .o_tick  ()
    );
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) min_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_min_tick),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .o_count (min),
        .o_tick  (w_hour_tick)
    );
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) sec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_sec_tick),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .o_count (sec),
        .o_tick  (w_min_tick)
    );
    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES    (100)
    ) msec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_tick_100hz),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .o_count (msec),
        .o_tick  (w_sec_tick)
    );
    tick_gen_100hz U_TICK_GEN (
        .clk         (clk),
        .reset       (reset),
        .i_run_stop  (run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

// msec, sec, min, hour
// tick counter
module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input                      clk,
    input                      reset,
    input                      i_tick,
    input                      mode,
    input                      clear,
    input                      run_stop,
    output     [BIT_WIDTH-1:0] o_count,
    output reg                 o_tick
);

    //counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick & run_stop) begin
            if (mode == 1'b1) begin
                // down
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
            end else begin
                // up
                if (counter_reg == (TIMES - 1)) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule

module tick_gen_100hz (
    input      clk,
    input      reset,
    input      i_run_stop,
    output reg o_tick_100hz
);

    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_run_stop) begin
                r_counter <= r_counter + 1;
                if (r_counter == (F_COUNT - 1)) begin
                    r_counter <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    o_tick_100hz <= 1'b0;
                end
            end
        end
    end

endmodule

module watch_datapath (
    input        clk,
    input        reset,
    input        i_sel_r,
    input        i_sel_l,
    input        i_up,
    input        i_down,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    // 00=sec, 01=min, 10=hour
    reg [1:0] sel;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            sel <= 2'b00;
        end else begin
            if (i_sel_r) begin
                if (sel == 2'b00) sel <= 2'b10;
                else sel <= sel - 1'b1;
            end else if (i_sel_l) begin
                if (sel == 2'b10) sel <= 2'b00;
                else sel <= sel + 1'b1;
            end
        end
    end

    wire sec_up = (sel == 2'b00) & i_up;
    wire sec_down = (sel == 2'b00) & i_down;

    wire min_up = (sel == 2'b01) & i_up;
    wire min_down = (sel == 2'b01) & i_down;

    wire hour_up = (sel == 2'b10) & i_up;
    wire hour_down = (sel == 2'b10) & i_down;

    tick_gen_100hz U_WATCH_TICK (
        .clk(clk),
        .reset(reset),
        .i_run_stop(1'b1),
        .o_tick_100hz(w_tick_100hz)
    );

    watch_counter #(
        .TIMES(24),
        .BIT_WIDTH(5),
        .START(12)
    ) w_hour_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .i_up(hour_up),
        .i_down(hour_down),
        .o_tick(),
        .o_time(hour)
    );
    watch_counter #(
        .TIMES(60),
        .BIT_WIDTH(6),
        .START(0)
    ) w_min_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .i_up(min_up),
        .i_down(min_down),
        .o_tick(w_hour_tick),
        .o_time(min)
    );
    watch_counter #(
        .TIMES(60),
        .BIT_WIDTH(6),
        .START(0)
    ) w_sec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .i_up(sec_up),
        .i_down(sec_down),
        .o_tick(w_min_tick),
        .o_time(sec)
    );
    watch_counter #(
        .TIMES(100),
        .BIT_WIDTH(7),
        .START(0)
    ) w_msec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .i_up(1'b0),
        .i_down(1'b0),
        .o_tick(w_sec_tick),
        .o_time(msec)
    );

endmodule

module watch_counter #(
    parameter TIMES = 100,
    BIT_WIDTH = 7,
    START = 0
) (
    input                      clk,
    input                      reset,
    input                      i_tick,
    input                      i_up,
    input                      i_down,
    output reg                 o_tick,
    output reg [BIT_WIDTH-1:0] o_time
);

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            o_time <= START[BIT_WIDTH-1:0];
            o_tick <= 1'b0;
        end else begin
            o_tick <= 1'b0;

            if (i_tick) begin
                if (o_time == TIMES - 1) begin
                    o_time <= {BIT_WIDTH{1'b0}};
                    o_tick <= 1'b1;  // carry
                end else begin
                    o_time <= o_time + 1'b1;
                end
            end else if (i_up) begin
                if (o_time == TIMES - 1) o_time <= {BIT_WIDTH{1'b0}};
                else o_time <= o_time + 1'b1;

            end else if (i_down) begin
                if (o_time == 0) o_time <= TIMES - 1;
                else o_time <= o_time - 1'b1;
            end
        end
    end

endmodule

//module counter_10000 (
//    input         clk,
//    input         reset,
//    input         i_tick,
//    input         mode,
//    input         run_stop,
//    input         clear,
//    output [13:0] counter
//);
//
//    reg [13:0] r_counter;
//
//    assign counter = r_counter;
//
//    always @(posedge clk, posedge reset) begin
//        if (reset || clear) begin
//            //reset init
//            r_counter <= 14'd0;
//        end else begin
//            //to do
//            if (run_stop) begin
//                if (mode == 0) begin
//                    if (i_tick == 1) begin
//                        r_counter <= r_counter + 1;
//                        if (r_counter == (10000 - 1)) r_counter <= 0;
//                    end
//                end else begin
//                    if (i_tick == 1) begin
//                        r_counter <= r_counter - 1;
//                        if (r_counter == 0) r_counter <= 9999;
//                    end
//                end
//            end
//        end
//    end
//endmodule
