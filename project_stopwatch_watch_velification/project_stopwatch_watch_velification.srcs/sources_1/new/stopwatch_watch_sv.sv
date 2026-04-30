`timescale 1ns / 1ps
module stopwatch_watch_sv #(
    parameter int F_COUNT = 1_000_000
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        mode_stopwatch_watch,
    input  logic        stopwatch_updown,
    input  logic        stopwatch_runstop,
    input  logic        stopwatch_clear,
    input  logic        watch_r,
    input  logic        watch_l,
    input  logic        watch_u,
    input  logic        watch_d,
    output logic [23:0] stopwatch_time,
    output logic [23:0] watch_time,
    output logic [23:0] display_time
);

    stopwatch_datapath #(
        .F_COUNT(F_COUNT)
    ) U_STOPWATCH_DATAPATH (
        .clk              (clk),
        .rst              (rst),
        .stopwatch_updown (stopwatch_updown),
        .stopwatch_clear  (stopwatch_clear),
        .stopwatch_runstop(stopwatch_runstop),
        .msec             (stopwatch_time[6:0]),
        .sec              (stopwatch_time[12:7]),
        .min              (stopwatch_time[18:13]),
        .hour             (stopwatch_time[23:19])
    );

    watch_datapath #(
        .F_COUNT(F_COUNT)
    ) U_WATCH_DATAPATH (
        .clk    (clk),
        .rst    (rst),
        .watch_r(watch_r),
        .watch_l(watch_l),
        .watch_u(watch_u),
        .watch_d(watch_d),
        .msec   (watch_time[6:0]),
        .sec    (watch_time[12:7]),
        .min    (watch_time[18:13]),
        .hour   (watch_time[23:19])
    );

    assign display_time = mode_stopwatch_watch ? watch_time : stopwatch_time;

endmodule

module stopwatch_datapath #(
    parameter int F_COUNT = 1_000_000
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       stopwatch_updown,
    input  logic       stopwatch_clear,
    input  logic       stopwatch_runstop,
    output logic [6:0] msec,
    output logic [5:0] sec,
    output logic [5:0] min,
    output logic [4:0] hour
);
    logic w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    stopwatch_counter #(
        .BIT_WIDTH(5),
        .TIMES    (24)
    ) hour_counter (
        .clk              (clk),
        .rst              (rst),
        .i_tick           (w_hour_tick),
        .stopwatch_updown (stopwatch_updown),
        .stopwatch_clear  (stopwatch_clear),
        .stopwatch_runstop(stopwatch_runstop),
        .o_count          (hour),
        .o_tick           ()
    );
    stopwatch_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) min_counter (
        .clk              (clk),
        .rst              (rst),
        .i_tick           (w_min_tick),
        .stopwatch_updown (stopwatch_updown),
        .stopwatch_clear  (stopwatch_clear),
        .stopwatch_runstop(stopwatch_runstop),
        .o_count          (min),
        .o_tick           (w_hour_tick)
    );
    stopwatch_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) sec_counter (
        .clk              (clk),
        .rst              (rst),
        .i_tick           (w_sec_tick),
        .stopwatch_updown (stopwatch_updown),
        .stopwatch_clear  (stopwatch_clear),
        .stopwatch_runstop(stopwatch_runstop),
        .o_count          (sec),
        .o_tick           (w_min_tick)
    );
    stopwatch_counter #(
        .BIT_WIDTH(7),
        .TIMES    (100)
    ) msec_counter (
        .clk              (clk),
        .rst              (rst),
        .i_tick           (w_tick_100hz),
        .stopwatch_updown (stopwatch_updown),
        .stopwatch_clear  (stopwatch_clear),
        .stopwatch_runstop(stopwatch_runstop),
        .o_count          (msec),
        .o_tick           (w_sec_tick)
    );
    tick_gen_100hz #(
        .F_COUNT(20)
    ) U_TICK_GEN (
        .clk         (clk),
        .rst         (rst),
        .i_run_stop  (stopwatch_runstop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module stopwatch_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 i_tick,
    input  logic                 stopwatch_updown,
    input  logic                 stopwatch_clear,
    input  logic                 stopwatch_runstop,
    output logic [BIT_WIDTH-1:0] o_count,
    output logic                 o_tick
);

    //counter reg
    logic [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // State reg SL
    always_ff @(posedge clk, posedge rst) begin
        if (rst | stopwatch_clear) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next CL
    always_comb begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick) begin
            if (stopwatch_updown) begin
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

module watch_datapath #(
    parameter int F_COUNT = 1_000_000
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       watch_r,
    input  logic       watch_l,
    input  logic       watch_u,
    input  logic       watch_d,
    output logic [6:0] msec,
    output logic [5:0] sec,
    output logic [5:0] min,
    output logic [4:0] hour
);

    logic w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    // 00=sec, 01=min, 10=hour
    logic [1:0] sel;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            sel <= 2'b00;
        end else begin
            if (watch_r) begin
                if (sel == 2'b00) sel <= 2'b10;
                else sel <= sel - 1'b1;
            end else if (watch_l) begin
                if (sel == 2'b10) sel <= 2'b00;
                else sel <= sel + 1'b1;
            end
        end
    end

    logic sec_up = (sel == 2'b00) & watch_u;
    logic sec_down = (sel == 2'b00) & watch_d;

    logic min_up = (sel == 2'b01) & watch_u;
    logic min_down = (sel == 2'b01) & watch_d;

    logic hour_up = (sel == 2'b10) & watch_u;
    logic hour_down = (sel == 2'b10) & watch_d;

    tick_gen_100hz U_WATCH_TICK (
        .clk         (clk),
        .rst         (rst),
        .i_run_stop  (1'b1),
        .o_tick_100hz(w_tick_100hz)
    );

    watch_counter #(
        .TIMES    (24),
        .BIT_WIDTH(5),
        .START    (12)
    ) w_hour_counter (
        .clk   (clk),
        .rst (rst),
        .i_tick(w_hour_tick),
        .watch_u(hour_up),
        .watch_d(hour_down),
        .o_tick(),
        .o_time(hour)
    );
    watch_counter #(
        .TIMES    (60),
        .BIT_WIDTH(6),
        .START    (0)
    ) w_min_counter (
        .clk   (clk),
        .rst (rst),
        .i_tick(w_min_tick),
        .watch_u(min_up),
        .watch_d(min_down),
        .o_tick(w_hour_tick),
        .o_time(min)
    );
    watch_counter #(
        .TIMES    (60),
        .BIT_WIDTH(6),
        .START    (0)
    ) w_sec_counter (
        .clk   (clk),
        .rst (rst),
        .i_tick(w_sec_tick),
        .watch_u  (sec_up),
        .watch_d(sec_down),
        .o_tick(w_min_tick),
        .o_time(sec)
    );
    watch_counter #(
        .TIMES    (100),
        .BIT_WIDTH(7),
        .START    (0)
    ) w_msec_counter (
        .clk   (clk),
        .rst (rst),
        .i_tick(w_tick_100hz),
        .watch_u  (1'b0),
        .watch_d(1'b0),
        .o_tick(w_sec_tick),
        .o_time(msec)
    );

endmodule

module watch_counter #(
    parameter TIMES = 100,
    BIT_WIDTH = 7,
    START = 0
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 i_tick,
    input  logic                 watch_u,
    input  logic                 watch_d,
    output logic                 o_tick,
    output logic [BIT_WIDTH-1:0] o_time
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
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
            end else if (watch_u) begin
                if (o_time == TIMES - 1) o_time <= {BIT_WIDTH{1'b0}};
                else o_time <= o_time + 1'b1;

            end else if (watch_d) begin
                if (o_time == 0) o_time <= TIMES - 1;
                else o_time <= o_time - 1'b1;
            end
        end
    end

endmodule

module tick_gen_100hz #(
    parameter int F_COUNT = 1_000_000
) (
    input  logic clk,
    input  logic rst,
    input  logic i_run_stop,
    output logic o_tick_100hz
);

    logic [$clog2(F_COUNT)-1:0] r_counter;

    assign o_tick_100hz =i_run_stop && (r_counter == (F_COUNT -1));

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
           // o_tick_100hz <= 1'b0;
        end else begin
          //  o_tick_100hz <= 1'b0;
            if (!i_run_stop) begin
                r_counter <= r_counter;
            end else begin
                if (r_counter == (F_COUNT - 1)) begin
                    r_counter <= 0;
                 //   o_tick_100hz <= 1'b1;
                end else begin
                    r_counter <= r_counter + 1;
                end
            end
        end
    end

endmodule
