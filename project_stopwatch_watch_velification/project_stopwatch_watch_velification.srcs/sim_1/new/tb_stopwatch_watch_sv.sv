`timescale 1ns / 1ps

// 1. Interface (내부 tick 신호 포함)
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
    
    // DUT 내부에서 뽑아올 tick 신호
    logic tick_100hz; 
endinterface

// 2. Transaction (데이터 묶음 및 출력 포맷)
class transaction;
    // Inputs (Generator가 제어할 신호들)
    logic rst;
    logic mode_stopwatch_watch;
    logic stopwatch_updown;
    logic stopwatch_runstop;
    logic stopwatch_clear;
    logic watch_r, watch_l, watch_u, watch_d;
    
    // Outputs (Monitor가 읽어올 신호들)
    logic [23:0] stopwatch_time;
    logic [23:0] watch_time;
    logic [23:0] display_time;
    logic tick_100hz;

    // 요구사항: TCL 콘솔에 runstop, clear, tick_gen, 시간값 띄우기
    function void display(string name);
        $display("%t : [%s] runstop=%b, clear=%b, tick=%b | SW_Time = %02d:%02d:%02d.%02d",
                 $time, name, stopwatch_runstop, stopwatch_clear, tick_100hz,
                 stopwatch_time[23:19], // hour
                 stopwatch_time[18:13], // min
                 stopwatch_time[12:7],  // sec
                 stopwatch_time[6:0]);  // msec
    endfunction
endclass

// 3. Generator (시나리오 생성)
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int run_count);
        // Step 1: 초기화 및 리셋 (1번 실행)
        tr = new();
        tr.rst = 1; tr.stopwatch_runstop = 0; tr.stopwatch_clear = 0; 
        tr.stopwatch_updown = 0; tr.mode_stopwatch_watch = 0;
        tr.watch_r = 0; tr.watch_l = 0; tr.watch_u = 0; tr.watch_d = 0;
        gen2drv_mbox.put(tr);
        @(gen_next_ev);

        // Step 2: 스톱워치 실행 유지 (run_count 만큼 클럭 진행)
        // (스톱워치는 신호를 가만히 유지해야 시간이 가므로 randomize 대신 고정값 전달)
        repeat (run_count) begin
            tr = new();
            tr.rst = 0; 
            tr.stopwatch_runstop = 1; // 스톱워치 RUN!
            tr.stopwatch_clear = 0;
            tr.stopwatch_updown = 0; 
            tr.mode_stopwatch_watch = 0;
            tr.watch_r = 0; tr.watch_l = 0; tr.watch_u = 0; tr.watch_d = 0;
            
            gen2drv_mbox.put(tr);
            // tr.display("gen"); // 너무 많이 출력되므로 주석 처리
            @(gen_next_ev);
        end
    endtask
endclass

// 4. Driver (Interface에 신호 인가)
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual watch_interface watch_if;

    function new(mailbox#(transaction) gen2drv_mbox, virtual watch_interface watch_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.watch_if     = watch_if;
    endfunction

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge watch_if.clk); // 교수님 코드와 동일하게 하강 에지에서 구동
            watch_if.rst = tr.rst;
            watch_if.mode_stopwatch_watch = tr.mode_stopwatch_watch;
            watch_if.stopwatch_updown = tr.stopwatch_updown;
            watch_if.stopwatch_runstop = tr.stopwatch_runstop;
            watch_if.stopwatch_clear = tr.stopwatch_clear;
            watch_if.watch_r = tr.watch_r;
            watch_if.watch_l = tr.watch_l;
            watch_if.watch_u = tr.watch_u;
            watch_if.watch_d = tr.watch_d;
        end
    endtask
endclass

// 5. Monitor (Interface에서 신호 읽기)
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual watch_interface watch_if;

    function new(mailbox#(transaction) mon2scb_mbox, virtual watch_interface watch_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.watch_if     = watch_if;
    endfunction

    task run();
        forever begin
            @(posedge watch_if.clk);
            #1; // 상승 에지 직후 값 읽기
            tr = new();
            tr.rst = watch_if.rst;
            tr.stopwatch_runstop = watch_if.stopwatch_runstop;
            tr.stopwatch_clear = watch_if.stopwatch_clear;
            tr.stopwatch_time = watch_if.stopwatch_time;
            tr.watch_time = watch_if.watch_time;
            tr.display_time = watch_if.display_time;
            tr.tick_100hz = watch_if.tick_100hz; // Tick 신호 읽기
            
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

// 6. Scoreboard (Tick 세기 및 결과 검증)
class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    // Tick 변화를 감지하기 위한 이전 값 저장용 변수
    logic prev_tick;
    int tick_count;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
        prev_tick = 0;
        tick_count = 0;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            
            // 리셋 시 카운트 초기화
            if (tr.rst || tr.stopwatch_clear) begin
                tick_count = 0;
            end

            // Tick이 0에서 1로 변하는 순간(Rising Edge) 캐치
            if (tr.tick_100hz == 1'b1 && prev_tick == 1'b0) begin
                if (tr.stopwatch_runstop) begin
                    tick_count++;
                    // Tick이 발생했을 때만 TCL 콘솔에 출력 (가독성 향상)
                    $display("==========================================================================");
                    $display("SCOREBOARD: 누적 Tick 개수 = %0d", tick_count);
                    tr.display("scb"); 
                end
            end
            
            prev_tick = tr.tick_100hz; // 이전 상태 업데이트

            // 다음 신호 생성 지시
            ->gen_next_ev;
        end
    endtask
endclass

// 7. Environment (클래스 인스턴스 조립)
class environment;
    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

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
            gen.run(500); // 클럭 500번 동안 테스트 진행 (F_COUNT_TB=10 이면 tick 50번 발생)
            drv.run();
            mon.run();
            scb.run();
        join_any
        
        #10;
        $display(">>> 시뮬레이션 완료 <<<");
        $stop;
    endtask
endclass

// 8. Top Module (최상위 연결)
module tb_watch_sv();
    logic clk;

    // 시뮬레이션 시간 단축용 (클럭 10번당 1 Tick 발생)
    localparam F_COUNT_TB = 10; 

    watch_interface watch_if(clk);
    environment env;

    // DUT 인스턴스
    stopwatch_watch_sv #(
        .F_COUNT(F_COUNT_TB)
    ) dut (
        .clk(clk),
        .rst(watch_if.rst),
        .mode_stopwatch_watch(watch_if.mode_stopwatch_watch),
        .stopwatch_updown(watch_if.stopwatch_updown),
        .stopwatch_runstop(watch_if.stopwatch_runstop),
        .stopwatch_clear(watch_if.stopwatch_clear),
        .watch_r(watch_if.watch_r),
        .watch_l(watch_if.watch_l),
        .watch_u(watch_if.watch_u),
        .watch_d(watch_if.watch_d),
        .stopwatch_time(watch_if.stopwatch_time),
        .watch_time(watch_if.watch_time),
        .display_time(watch_if.display_time)
    );

    // 핵심: DUT 내부의 100Hz 틱 신호를 인터페이스로 끄집어내어 연결
    assign watch_if.tick_100hz = dut.U_STOPWATCH_DATAPATH.w_tick_100hz;

    // 클럭 생성 (주기 10ns)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(watch_if);
        env.run();
    end
endmodule