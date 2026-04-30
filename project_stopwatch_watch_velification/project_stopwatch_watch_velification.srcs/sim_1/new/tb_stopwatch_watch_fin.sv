`timescale 1ns / 1ps

interface watch_interface (
    input clk
);
    logic rst;
    logic mode_stopwatch_watch;
    logic stopwatch_updown;
    logic stopwatch_runstop;
    logic stopwatch_clear;
    logic watch_r, watch_l, watch_u, watch_d;

    logic [23:0] stopwatch_time;
    logic [23:0] watch_time;
    logic [23:0] display_time;

    logic tick_100hz;
endinterface

class transaction;

    rand logic rst;
    rand logic mode_stopwatch_watch;
    rand logic stopwatch_updown;
    rand logic stopwatch_runstop;
    rand logic stopwatch_clear;
    rand logic watch_r, watch_l, watch_u, watch_d;

    logic [23:0] stopwatch_time;
    logic [23:0] watch_time;
    logic [23:0] display_time;
    logic tick_100hz;

    constraint c_run {
        rst == 0;
        stopwatch_clear == 0;
        stopwatch_runstop == 1;
        stopwatch_updown == 0;

        watch_r == 0;
        watch_l == 0;
        watch_u == 0;
        watch_d == 0;

        mode_stopwatch_watch dist {
            0 := 50,
            1 := 50
        };
    }
endclass

//     function void display(string name);
//         $display(
//             "%t : [%s] runstop=%b, clear=%b, tick=%b | SW_Time = %02d:%02d:%02d.%02d",
//             $time, name, stopwatch_runstop, stopwatch_clear, tick_100hz,
//             stopwatch_time[23:19],  // hour
//             stopwatch_time[18:13],  // min
//             stopwatch_time[12:7],  // sec
//             stopwatch_time[6:0]);  // msec
//     endfunction
// endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int run_count);
        repeat (run_count) begin

            tr = new();
            if (!tr.randomize()) begin
                $display("Randomization Failed");
            end
            gen2drv_mbox.put(tr);
            @(gen_next_ev);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual watch_interface watch_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual watch_interface watch_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.watch_if     = watch_if;
    endfunction

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge watch_if.clk);
            watch_if.rst                  = tr.rst;
            watch_if.mode_stopwatch_watch = tr.mode_stopwatch_watch;
            watch_if.stopwatch_updown     = tr.stopwatch_updown;
            watch_if.stopwatch_runstop    = tr.stopwatch_runstop;
            watch_if.stopwatch_clear      = tr.stopwatch_clear;
            watch_if.watch_r              = tr.watch_r;
            watch_if.watch_l              = tr.watch_l;
            watch_if.watch_u              = tr.watch_u;
            watch_if.watch_d              = tr.watch_d;
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual watch_interface watch_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual watch_interface watch_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.watch_if     = watch_if;
    endfunction

    task run();
        forever begin
            @(posedge watch_if.clk);
            #1;
            tr                   = new();
            tr.rst               = watch_if.rst;
            tr.stopwatch_runstop = watch_if.stopwatch_runstop;
            tr.stopwatch_clear   = watch_if.stopwatch_clear;
            tr.stopwatch_time    = watch_if.stopwatch_time;
            tr.watch_time        = watch_if.watch_time;
            tr.display_time      = watch_if.display_time;
            tr.tick_100hz        = watch_if.tick_100hz;

            mon2scb_mbox.put(tr);
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    logic prev_tick;
    int expected_stopwatch;
    int expected_watch;
    int actual_display;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
        prev_tick = 0;
        expected_stopwatch = 0;
        expected_watch = 12 * 360000;
    endfunction

    task run();
        int h, m, s, ms;
        string mode_str;
        int expected_val;

        forever begin
            mon2scb_mbox.get(tr);

            h = tr.stopwatch_time[23:19];
            m = tr.stopwatch_time[18:13];
            s = tr.stopwatch_time[12:7];
            ms = tr.stopwatch_time[6:0];
            actual_display = h * 360000 + m * 6000 + s * 100 + ms;

            if (tr.rst) begin
                expected_stopwatch = 0;
                expected_watch = 12 * 360000;
            end else if (tr.stopwatch_clear) begin
                expected_stopwatch = 0;
            end

            if (prev_tick == 1'b1 && tr.tick_100hz == 1'b0) begin
                if (tr.stopwatch_runstop) begin
                    if (tr.stopwatch_updown == 0) expected_stopwatch++;
                end
                expected_stopwatch--;
                if (expected_stopwatch >= 8640000) expected_stopwatch = 0;
                if (expected_stopwatch < 0) expected_stopwatch = 8640000 - 1;
            end
            expected_stopwatch++;

            if (expected_watch >= 8640000) expected_watch = 0;
            mode_str = tr.mode_stopwatch_watch ? "WATCH" : "STOPWATCH";
            expected_val = tr.mode_stopwatch_watch ? expected_watch : expected_stopwatch;

            if (expected_val === actual_display) begin
                $display(
                    "[PASS] mode:%9s, run:%b, clear:%b, tick:1, exp:%08d, act:%08d, time:%02d:%02d:%02d.%02d",
                    mode_str, tr.stopwatch_runstop, tr.stopwatch_clear,
                    expected_val, actual_display, h, m, s, ms);
            end else begin
                $display(
                    "[FAIL] mode:%9s, run:%b, clear:%b, tick:1, exp:%08d, act:%08d, time:%02d:%02d:%02d.%02d",
                    mode_str, tr.stopwatch_runstop, tr.stopwatch_clear,
                    expected_val, actual_display, h, m, s, ms);
            end
            prev_tick = tr.tick_100hz;
            ->gen_next_ev;
        end
    endtask
endclass

class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event                  gen_next_ev;

    function new(virtual watch_interface watch_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, watch_if);
        mon = new(mon2scb_mbox, watch_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction

    task run();
        fork
            gen.run(500);
            drv.run();
            mon.run();
            scb.run();
        join_any

        #10;

        $stop;
    endtask
endclass

module tb_stopwatch_watch_fin ();
    logic clk;

    localparam F_COUNT_TB = 10;

    watch_interface watch_if (clk);
    environment env;

    stopwatch_watch_sv #(
        .F_COUNT(F_COUNT_TB)
    ) dut (
        .clk                 (clk),
        .rst                 (watch_if.rst),
        .mode_stopwatch_watch(watch_if.mode_stopwatch_watch),
        .stopwatch_updown    (watch_if.stopwatch_updown),
        .stopwatch_runstop   (watch_if.stopwatch_runstop),
        .stopwatch_clear     (watch_if.stopwatch_clear),
        .watch_r             (watch_if.watch_r),
        .watch_l             (watch_if.watch_l),
        .watch_u             (watch_if.watch_u),
        .watch_d             (watch_if.watch_d),
        .stopwatch_time      (watch_if.stopwatch_time),
        .watch_time          (watch_if.watch_time),
        .display_time        (watch_if.display_time)
    );

    assign watch_if.tick_100hz = dut.U_STOPWATCH_DATAPATH.w_tick_100hz;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(watch_if);
        env.run();
    end
endmodule
