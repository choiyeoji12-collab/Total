`timescale 1ns / 1ps

// 1. Interface: 설계와 테스트벤치를 잇는 통로
interface stopwatch_if (
    input logic clk
);
    logic rst;
    logic mode;
    logic sw_updown, sw_runstop, sw_clear;
    logic w_r, w_l, w_u, w_d;
    logic [23:0] d_time;

    // 내부 tick 관찰용 (Hierarchical reference로 연결 예정)
    logic tick_stopwatch;
    logic tick_watch;
endinterface

// 2. Transaction: 한 번의 동작 단위
class transaction;
    rand bit mode;
    rand bit sw_updown, sw_runstop, sw_clear;
    rand bit w_r, w_l, w_u, w_d;

    // 모니터링용 결과값
    logic tick;
    logic [23:0] d_time;

    function void display(string name);
        $display("%t : [%s] Mode=%b, Clear=%b, Tick=%b, Time=%h", $time, name,
                 mode, sw_clear, tick, d_time);
    endfunction
endclass

// 3. Generator: 랜덤 데이터 생성
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            @(gen_next_ev);
        end
    endtask
endclass

// 4. Driver: 인터페이스에 신호 주입
class driver;
    virtual stopwatch_if   sif;
    mailbox #(transaction) gen2drv_mbox;

    function new(virtual stopwatch_if sif, mailbox#(transaction) gen2drv_mbox);
        this.sif = sif;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    task run();
        forever begin
            transaction tr;
            gen2drv_mbox.get(tr);
            @(negedge sif.clk);
            sif.mode       <= tr.mode;
            sif.sw_updown  <= tr.sw_updown;
            sif.sw_runstop <= tr.sw_runstop;
            sif.sw_clear   <= tr.sw_clear;
            sif.w_r        <= tr.w_r;
            sif.w_l        <= tr.w_l;
            sif.w_u        <= tr.w_u;
            sif.w_d        <= tr.w_d;
        end
    endtask
endclass

// 5. Monitor: 인터페이스 신호 채집
class monitor;
    virtual stopwatch_if   sif;
    mailbox #(transaction) mon2scb_mbox;

    function new(virtual stopwatch_if sif, mailbox#(transaction) mon2scb_mbox);
        this.sif = sif;
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    task run();
        forever begin
            transaction tr;
            @(posedge sif.clk);
            #1;  // Hold time
            tr = new();
            tr.mode = sif.mode;
            tr.sw_clear = sif.sw_clear;
            tr.sw_updown = sif.sw_updown;
            tr.d_time = sif.d_time;
            // 현재 모드에 맞는 tick 선택
            tr.tick = (sif.mode == 0) ? sif.tick_stopwatch : sif.tick_watch;
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

// 6. Scoreboard: Tick 기반 검증 (핵심)
class scoreboard;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    // 내부 Reference 카운터
    int exp_ms = 0, exp_s = 0, exp_m = 0, exp_h = 0;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run();
        forever begin
            transaction tr;
            mon2scb_mbox.get(tr);

            // [로직] Tick이 발생했을 때만 예상값 업데이트
            if (tr.sw_clear && tr.mode == 0) begin
                exp_h  = 0;
                exp_m  = 0;
                exp_s  = 0;
                exp_ms = 0;
            end else if (tr.tick) begin
                if (!tr.sw_updown) begin  // Up-count
                    exp_ms++;
                    if (exp_ms == 100) begin
                        exp_ms = 0;
                        exp_s++;
                    end
                    if (exp_s == 60) begin
                        exp_s = 0;
                        exp_m++;
                    end
                    if (exp_m == 60) begin
                        exp_m = 0;
                        exp_h = (exp_h + 1) % 24;
                    end
                end else begin  // Down-count
                    exp_ms--;
                    if (exp_ms < 0) begin
                        exp_ms = 99;
                        exp_s--;
                    end
                    if (exp_s < 0) begin
                        exp_s = 59;
                        exp_m--;
                    end
                    if (exp_m < 0) begin
                        exp_m = 59;
                        exp_h = (exp_h == 0) ? 23 : exp_h - 1;
                    end
                end
            end

            // [비교] 결과 출력 및 검증
            if (tr.tick) begin
                $display("[CHECK] Time: %02d:%02d:%02d.%02d | DUT: %h", exp_h,
                         exp_m, exp_s, exp_ms, tr.d_time);
            end

            ->gen_next_ev;
        end
    endtask
endclass

// 7. Environment: 클래스 조립
class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) g2d,  m2s;
    event                  next;
    virtual stopwatch_if   sif;

    function new(virtual stopwatch_if sif);
        this.sif = sif;
        g2d = new();
        m2s = new();
        gen = new(g2d, next);
        drv = new(sif, g2d);
        mon = new(sif, m2s);
        scb = new(m2s, next);
    endfunction

    task run();
        fork
            gen.run(1000);  // 1000번의 랜덤 테스트
            drv.run();
            mon.run();
            scb.run();
        join_any
        #100;
        $finish;
    endtask
endclass

// 8. Testbench Top: 최상위 모듈
module tb_stopwatch_system_sv ();
    logic clk = 0;
    always #5 clk = ~clk;  // 100MHz

    stopwatch_if sif (clk);
    environment env;

    // DUT 연결
    stopwatch_watch_sv #(
        .F_COUNT(5)
    ) dut (  // 시뮬레이션을 위해 F_COUNT 낮춤
        .clk(clk),
        .rst(sif.rst),
        .mode_stopwatch_watch(sif.mode),
        .stopwatch_updown(sif.sw_updown),
        .stopwatch_runstop(sif.sw_runstop),
        .stopwatch_clear(sif.sw_clear),
        .watch_r(sif.w_r),
        .watch_l(sif.w_l),
        .watch_u(sif.w_u),
        .watch_d(sif.w_d),
        .display_time(sif.d_time),
        .stopwatch_time(),
        .watch_time()
    );

    // 내부 Tick 신호 연결 (Hierarchical Access)
    assign sif.tick_stopwatch = dut.U_STOPWATCH_DATAPATH.w_tick_100hz;
    assign sif.tick_watch     = dut.U_WATCH_DATAPATH.w_tick_100hz;

    initial begin
        sif.rst = 1;
        #20 sif.rst = 0;
        env = new(sif);
        env.run();
    end
endmodule
