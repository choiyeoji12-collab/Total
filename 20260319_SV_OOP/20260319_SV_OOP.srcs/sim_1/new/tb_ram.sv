`timescale 1ns / 1ps

// 하드웨어 신호 묶음
interface ram_if (
    input logic clk
);
    logic       we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface

// 기본 클래스 (부모 클래스): 기본적인 read/write 기능을 가진 핸들러(리모컨)
class test;

    // virtual이 붙으면 소프트웨어의 인터페이스 
    // 하드웨어가 아니라는 것을 virtual을 붙임 
    // handler 느낌 
    virtual ram_if r_if;

    function new(virtual ram_if r_if);
        this.r_if = r_if;
    endfunction

    // virtual을 붙여두면 나중에 자식 클래스에서 이 기능을 덮어쓰기(override) 할 수 있음
    // virtual이 붙어있으면 override(덮어쓰기)가 가능하다 
    virtual task write(logic [7:0] waddr, logic [7:0] data);
        r_if.we    = 1;
        r_if.addr  = waddr;
        r_if.wdata = data;
        @(posedge r_if.clk);
    endtask

    virtual task read(logic [7:0] raddr);
        r_if.we   = 0;
        r_if.addr = raddr;
        @(posedge r_if.clk);
    endtask

endclass

// 자식 클래스1 (기능 확장): 기본 리모컨을 개조해 '연속 쓰기(Burst)' 기능을 추가
// test에서 read, write는 그대로 두지만 확장하고 싶음
// 상속(확장)
// extends:상속
// class '자식class' extends '부모class'
class test_burst extends test;

    function new(virtual ram_if r_if);
        //super-> 부모 class의 new
        super.new(
            r_if);    // 부모 클래스의 초기화(new) 함수를 그대로 가져와서 실행
    endfunction  //new()

    // 새로운 기능 추가: 지정한 길이(len)만큼 연속해서 쓰는 task
    task write_burst(logic [7:0] waddr, logic [7:0] data, int len);
        for (int i = 0; i < len; i++) begin
            super.write(waddr,
                        data);  // 부모class의 write 기능을 가져다 씀 
            waddr++;
        end
    endtask  //

    // 기존 기능 덮어쓰기(Override): 부모의 write를 무시하고 나만의 write 방식으로 재정의
    task write(logic [7:0] waddr, logic [7:0] data);  // 재정의
        r_if.we = 1;
        r_if.addr  = waddr + 1; // 주소에 항상 1을 더해서 쓰는 방식으로 개조됨
        r_if.wdata = data;
        @(posedge r_if.clk);
    endtask  //
endclass

// 데이터 바구니 (transaction): 한 번의 테스트에 필요한 신호들을 담는 상자
class transaction;
    logic            we;
    rand logic [7:0] addr;  // 랜덤으로 뽑을 주소 변수
    rand logic [7:0] wdata;  // 랜덤으로 뽑을 데이터 변수
    logic      [7:0] rdata;

    // 제약 조건 (constraint): 아무 숫자나 뽑지 말고 지정된 범위 안에서만 뽑도록 규칙 설정
    constraint c_addr {addr inside {[8'h00 : 8'h10]};}
    constraint c_wdata {wdata inside {[8'h10 : 8'h20]};}

    // 바구니에 담긴 값들을 화면에 예쁘게 출력해주는 기능
    function print(string name);
        $display("[name] we:%0d, addr:0x%0x, wdata:0x%0x, rdata:0x%0x", name,
                 we, addr, wdata, rdata);
    endfunction
endclass

// 자식 클래스2: 바구니(transaction)를 이용해 자동 랜덤 테스트를 수행하는 리모컨
class test_rand extends test;
    transaction tr;  // 바구니를 다룰 핸들 선언

    function new(virtual ram_if r_if);
        super.new(r_if);
    endfunction

    // 지정된 횟수(loop)만큼 랜덤한 값으로 쓰기 테스트를 하는 task
    task write_rand(int loop);
        repeat (loop) begin
            tr = new();     // ★ 매 루프마다 새로운 빈 바구니를 동적 생성 (heap 메모리 할당)
            tr.randomize(); // 바구니 안의 rand 변수들(addr, wdata)을 제약 조건에 맞춰 랜덤하게 채움

            r_if.we = 1;
            r_if.addr  = tr.addr;   // 꽉 찬 바구니에서 랜덤 주소를 꺼내 하드웨어에 전달
            r_if.wdata = tr.wdata;  // 꽉 찬 바구니에서 랜덤 데이터를 꺼내 하드웨어에 전달
            @(posedge r_if.clk);
        end
    endtask  //
endclass

// 최상위 TestBench: 실제 회로와 클래스들을 연결하고 테스트를 지휘하는 무대
module tb_ram ();
    logic clk;

    // 하드웨어 인터페이스 및 RAM(DUT) 생성
    ram_if r_if (clk);

    ram dut (
        .clk  (r_if.clk),
        .we   (r_if.we),
        .addr (r_if.addr),
        .wdata(r_if.wdata),
        .rdata(r_if.rdata)
    );

    // 초기화 하는 걸 따로 분리하는 경우도 있음
    initial clk = 0;
    always #5 clk = ~clk;

    // write 해야할 것들은 하나로 묶음 (캡슐화)
    //   task ram_write(logic [7:0] waddr, logic [7:0] data);
    //       we = 1;
    //       addr = waddr;
    //       wdata = data;
    //       @(posedge clk);
    //   endtask
    //
    //   task ram_read(logic [7:0] raddr);
    //       we   = 0;
    //       addr = raddr;
    //       @(posedge clk);
    //   endtask

    // 리모컨(핸들) 준비: 아직 실제 객체(TV)는 만들어지지 않은 상태
    // test는 객체를 만들기 위한 틀, BTS는 객체
    // BTS라는 건 핸들러
    test BTS;  // 기본 리모컨
    test_rand BlackPink;  // 랜덤 바구니 리모컨

    initial begin
        repeat (5) @(posedge clk);

        // 실체화(인스턴스화): 메모리(heap)에 실제 객체를 만들고 리모컨과 연결
        // new는 우리가 상상하고 있는 것을 실체화 하는 것 (인스턴스 하는 거)
        BTS = new(r_if);
        BlackPink = new(r_if);

        // 각 객체가 할당된 메모리 주소값 확인
        $display("addr = 0x%0h", BTS);
        $display("addr = 0x%0h", BlackPink);

        // 1. 기본 객체(BTS)를 이용한 수동 테스트 (직접 주소와 데이터를 입력)
        BTS.write(8'h00, 8'h01);
        BTS.write(8'h01, 8'h02);
        BTS.write(8'h02, 8'h03);
        BTS.write(8'h03, 8'h04);

        // 2. 확장된 객체(BlackPink)를 이용한 제약 기반 랜덤 테스트
        // 바구니(transaction)를 이용해 10번 알아서 제약 조건에 맞는 랜덤 값을 씀
        BlackPink.write_rand(10);

        // BlackPink.write(8'h01, 8'h02);
        // BlackPink.write(8'h02, 8'h03);
        // BlackPink.write(8'h03, 8'h04);

        // 객체 아님
        //ram_write(8'h00, 8'h01);
        //ram_write(8'h01, 8'h02);
        //ram_write(8'h02, 8'h03);
        //ram_write(8'h03, 8'h04);

        // 3. 수동으로 썼던 값들이 제대로 들어갔는지 확인 (Read)
        BTS.read(8'h00);
        BTS.read(8'h01);
        BTS.read(8'h02);
        BTS.read(8'h03);

        //ram_read(8'h00);
        //ram_read(8'h01);
        //ram_read(8'h02);
        //ram_read(8'h03);

        #20;
        $finish;
    end
endmodule
