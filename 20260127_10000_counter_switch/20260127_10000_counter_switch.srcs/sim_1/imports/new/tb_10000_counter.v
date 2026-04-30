`timescale 1ns / 1ps

module tb_10000_counter ();

    reg clk, reset;
    //   wire [7:0] fnd_data;
    //   wire [3:0] fnd_digit;
    //
    //   top_10000_counter dut (
    //       .clk      (clk),
    //       .reset    (reset),
    //       .fnd_digit(fnd_digit),
    //       .fnd_data (fnd_data)
    //   );

    reg mode, clear, run_stop;
    reg         i_tick;
    wire [13:0] counter;

    counter_10000 dut (
        .clk     (clk),
        .reset   (reset),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .i_tick  (i_tick),
        .counter (counter)
    );

    // generate clock
    always #5 clk = ~clk;

    //  always #10 i_tick = ~i_tick;

    initial begin
        #0;
        clk    = 0;
        reset  = 1;
        mode   = 0;
        run_stop = 0;
        clear = 0;
        i_tick = 1;

        #10;
        reset = 0;

        #1000;
        mode = 1;
        run_stop = 1;

        #1000;
        clear = 1;

        #1000;
        clear = 0;
        mode = 0;
        run_stop = 0;

        #1000;
        mode = 0;
        run_stop = 1;
        clear = 0;

        #1000;
        clear =1;

        #1000; 
        $stop;

    end

endmodule
