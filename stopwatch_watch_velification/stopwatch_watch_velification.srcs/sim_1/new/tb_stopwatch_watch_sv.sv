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
    logic tick_out;
endinterface

class transaction;
    bit rst;
    rand bit mode_stopwatch_watch;
    rand bit stopwatch_updown;
    rand bit stopwatch_runstop;
    rand bit stopwatch_clear;
    bit watch_r, watch_l, watch_u, watch_d;

    logic [23:0] display_time;

    constraint c_normal_run {
        stopwatch_clear dist {
            0 := 99,
            1 := 1
        };
        stopwatch_runstop dist {
            1 := 95,
            0 := 5
        };
        stopwatch_updown dist {
            0 := 90,
            1 := 10
        };
    }
endclass


class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int run_count);
        tr = new();
        tr.rst = 1;
        tr.stopwatch_runstop = 0;
        tr.stopwatch_clear = 0;
        gen2drv_mbox.put(tr);
        @(gen_next_ev);

        $display(
            "\n===========================================================");
        $display("                 STOPWATCH Mode Test Start               ");
        $display("===========================================================");
        repeat (run_count / 2) begin
            tr = new();
            if (!tr.randomize() with {mode_stopwatch_watch == 0;})
                $display("Rand Failed");
            gen2drv_mbox.put(tr);
            @(gen_next_ev);
        end

        $display(
            "\n===========================================================");
        $display("                  WATCH Mode Test Start                 ");
        $display("===========================================================");
        repeat (run_count / 2) begin
            tr = new();
            if (!tr.randomize() with {mode_stopwatch_watch == 1;})
                $display("Rand Failed");
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
            tr                      = new();
            tr.rst                  = watch_if.rst;
            tr.stopwatch_clear      = watch_if.stopwatch_clear;
            tr.stopwatch_runstop    = watch_if.stopwatch_runstop;
            tr.mode_stopwatch_watch = watch_if.mode_stopwatch_watch;
            tr.stopwatch_updown     = watch_if.stopwatch_updown;
            tr.watch_r              = watch_if.watch_r;
            tr.watch_l              = watch_if.watch_l;
            tr.watch_u              = watch_if.watch_u;
            tr.watch_d              = watch_if.watch_d;
            tr.display_time         = watch_if.display_time;
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    int total_cnt = 0;
    int pass_cnt = 0;
    int fail_cnt = 0;

    int sw_tick_cnt, wt_tick_cnt;
    int expected_sw;
    int wt_h, wt_m, wt_s, wt_ms;
    logic [1:0] wt_sel;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
        sw_tick_cnt       = 0;
        wt_tick_cnt       = 0;
        expected_sw       = 0;
        wt_h              = 12;
        wt_m              = 0;
        wt_s              = 0;
        wt_ms             = 0;
        wt_sel            = 0;
    endfunction

    function void report();
        $display("\n---------------------------------------------------------");
        $display("------------------- Test Result -------------------------");
        $display("  Total Test Count : %0d", total_cnt);
        $display("  Pass Count       : %0d", pass_cnt);
        $display("  Fail Count       : %0d", fail_cnt);
        $display("---------------------------------------------------------");
        if (fail_cnt == 0) $display("  RESULT: [SUCCESS]");
        else $display("  RESULT: [FAILURE]");
        $display("---------------------------------------------------------\n");
    endfunction

    task run();
        int h, m, s, ms;
        int actual_display, expected_wt_total, expected_val;
        logic sw_tick, wt_tick;
        logic sec_u, sec_d, min_u, min_d, hr_u, hr_d;

        forever begin
            mon2scb_mbox.get(tr);
            total_cnt++;

            sw_tick = tr.stopwatch_runstop;
            wt_tick = 1;

            if (tr.rst) begin
                sw_tick_cnt = 0;
                wt_tick_cnt = 0;
            end else begin
                if (tr.stopwatch_runstop)
                    sw_tick_cnt = (sw_tick_cnt == 9) ? 0 : sw_tick_cnt + 1;
                wt_tick_cnt = (wt_tick_cnt == 9) ? 0 : wt_tick_cnt + 1;
            end

            if (tr.rst || tr.stopwatch_clear) begin
                expected_sw = 0;
            end else if (sw_tick) begin
                if (tr.stopwatch_updown == 0) expected_sw++;
                else expected_sw--;
                if (expected_sw >= 8640000) expected_sw = 0;
                if (expected_sw < 0) expected_sw = 8640000 - 1;
            end

            if (tr.rst) begin
                wt_sel = 0;
                wt_h   = 12;
                wt_m   = 0;
                wt_s   = 0;
                wt_ms  = 0;
            end else begin
                if (tr.watch_r) wt_sel = (wt_sel == 2'b00) ? 2'b10 : wt_sel - 1;
                else if (tr.watch_l)
                    wt_sel = (wt_sel == 2'b10) ? 2'b00 : wt_sel + 1;
                if (wt_tick) begin
                    wt_ms++;
                    if (wt_ms == 100) begin
                        wt_ms = 0;
                        wt_s++;
                        if (wt_s == 60) begin
                            wt_s = 0;
                            wt_m++;
                            if (wt_m == 60) begin
                                wt_m = 0;
                                wt_h = (wt_h == 23) ? 0 : wt_h + 1;
                            end
                        end
                    end
                end else begin
                    sec_u = (wt_sel == 2'b00) & tr.watch_u;
                    sec_d = (wt_sel == 2'b00) & tr.watch_d;
                    min_u = (wt_sel == 2'b01) & tr.watch_u;
                    min_d = (wt_sel == 2'b01) & tr.watch_d;
                    hr_u  = (wt_sel == 2'b10) & tr.watch_u;
                    hr_d  = (wt_sel == 2'b10) & tr.watch_d;
                    if (sec_u) wt_s = (wt_s == 59) ? 0 : wt_s + 1;
                    else if (sec_d) wt_s = (wt_s == 0) ? 59 : wt_s - 1;
                    if (min_u) wt_m = (wt_m == 59) ? 0 : wt_m + 1;
                    else if (min_d) wt_m = (wt_m == 0) ? 59 : wt_m - 1;
                    if (hr_u) wt_h = (wt_h == 23) ? 0 : wt_h + 1;
                    else if (hr_d) wt_h = (wt_h == 0) ? 23 : wt_h - 1;
                end
            end
            expected_wt_total = wt_h * 360000 + wt_m * 6000 + wt_s * 100 + wt_ms;

            h = tr.display_time[23:19];
            m = tr.display_time[18:13];
            s = tr.display_time[12:7];
            ms = tr.display_time[6:0];
            actual_display = h * 360000 + m * 6000 + s * 100 + ms;
            expected_val = tr.mode_stopwatch_watch ? expected_wt_total : expected_sw;

            if (expected_val === actual_display) begin
                pass_cnt++;
                if (tr.mode_stopwatch_watch == 0)
                    $display(
                        "[PASS] STOPWATCH | run/stop:%b, up/down:%b, clear:%b | Time: %02d:%02d:%02d.%02d | exp:%08d",
                        tr.stopwatch_runstop,
                        tr.stopwatch_updown,
                        tr.stopwatch_clear,
                        h,
                        m,
                        s,
                        ms,
                        expected_val
                    );
                else
                    $display(
                        "[PASS] WATCH | r:%b, l:%b, u:%b, d:%b | Time: %02d:%02d:%02d.%02d | exp:%08d",
                        tr.watch_r,
                        tr.watch_l,
                        tr.watch_u,
                        tr.watch_d,
                        h,
                        m,
                        s,
                        ms,
                        expected_val
                    );
            end else begin
                fail_cnt++;
                if (tr.mode_stopwatch_watch == 0)
                    $display(
                        "[FAIL] STOPWATCH | run/stop:%b, up/down:%b, clear:%b | Time: %02d:%02d:%02d.%02d | exp:%08d",
                        tr.stopwatch_runstop,
                        tr.stopwatch_updown,
                        tr.stopwatch_clear,
                        h,
                        m,
                        s,
                        ms,
                        expected_val
                    );
                else
                    $display(
                        "[FAIL] WATCH | r:%b, l:%b, u:%b, d:%b | Time: %02d:%02d:%02d.%02d | exp:%08d",
                        tr.watch_r,
                        tr.watch_l,
                        tr.watch_u,
                        tr.watch_d,
                        h,
                        m,
                        s,
                        ms,
                        expected_val
                    );
            end

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
        gen          = new(gen2drv_mbox, gen_next_ev);
        drv          = new(gen2drv_mbox, watch_if);
        mon          = new(mon2scb_mbox, watch_if);
        scb          = new(mon2scb_mbox, gen_next_ev);
    endfunction

    task run();
        fork
            gen.run(10000);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        scb.report();
        $display("\n>>> Simulation Completed <<<");
        $finish;
    endtask
endclass

module tb_stopwatch_watch_sv ();
    logic clk;
    watch_interface watch_if (clk);

    stopwatch_watch_sv #(
        .F_COUNT(1)
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
        .display_time        (watch_if.display_time),
        .tick_out            ()
    );

    always #5 clk = ~clk;

    initial begin
        environment env;
        clk = 0;
        env = new(watch_if);
        env.run();
    end
endmodule
