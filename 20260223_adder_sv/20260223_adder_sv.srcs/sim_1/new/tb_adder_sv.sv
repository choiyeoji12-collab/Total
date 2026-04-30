`timescale 1ns / 1ps

interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] s;
    logic        c;
    logic        mode;
endinterface  //adder_interface

class transaction;

    rand bit [31:0] a;
    rand bit [31:0] b;
    bit             mode;

endclass  //transaction

class generator;

    // veriable declaration : data type transction
    transaction tr;
    virtual adder_interface adder_interf_gen;

    function new(virtual adder_interface adder_interf_ext);
        this.adder_interf_gen = adder_interf_ext;
        tr                    = new();
    endfunction

    task run();
        tr.randomize();
        tr.mode               = 0;
        adder_interf_gen.a    = tr.a;
        adder_interf_gen.b    = tr.b;
        adder_interf_gen.mode = tr.mode;

        // drive
        #10;
    endtask  //

endclass  //generator

module tb_adder_sv ();

    adder_interface adder_interf ();
    // class generator를 선언
    // gen:generator 객체를 관리하기 위한 handler
    generator gen;

    adder dut (
        .a   (adder_interf.a),
        .b   (adder_interf.b),
        .mode(adder_interf.mode),
        .s   (adder_interf.s),
        .c   (adder_interf.c)
    );

    initial begin
        // class generator를 생성
        // generator class의 function new가 실행됨
        // new 생성자
        gen = new(adder_interf);
        // 생성된 후 task run 실행
        gen.run();
        $stop;
    end

endmodule
