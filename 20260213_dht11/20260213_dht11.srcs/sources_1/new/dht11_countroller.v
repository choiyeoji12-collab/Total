`timescale 1ns / 1ps

module dht11_countroller (
    input         clk,
    input         rst,
    input         start,
//    output [15:0] humidity,
//    output [15:0] temperature,
//    output        dht11_done,
//    output        dht11_valid,
    output [ 2:0] debug,
    inout         dhtio
);

    wire tick_10u;
    wire [15:0] humidity, temperature;
    wire dht11_done, dht11_valid;

    tick_gen_10u U_TICK_10u (
        .clk     (clk),
        .rst     (rst),
        .tick_10u(tick_10u)
    );

//    ila_0 U_ILA0 (
//        .clk   (clk),
//        .probe0(dhtio),      // 1bit
//        .probe1(debug)       // 3bit
//    );

    //STATE
    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, SYNC_H=4, 
             DATA_SYNC = 5, DATA_C = 6, STOP = 7; // data_c = data collect

    reg [2:0] c_state, n_state;
    reg dhtio_reg, dhtio_next;
    reg io_sel_reg, io_sel_next;

    // for 19msec count by 10usec tick
    reg [$clog2(1900)-1:0] tick_cnt_reg, tick_cnt_next;

    reg [5:0] bit_cnt_reg, bit_cnt_next;
    reg [39:0] data_reg, data_next;
    reg [15:0] humidity_reg, humidity_next;
    reg [15:0] temperature_reg, temperature_next;
    reg dht11_done_reg, dht11_valid_reg;
    reg dht11_valid_next;

    assign dhtio       = (io_sel_reg) ? dhtio_reg : 1'bz;
    assign debug       = c_state;
    assign humidity    = humidity_reg;
    assign temperature = temperature_reg;
    assign dht11_done  = dht11_done_reg;
    assign dht11_valid = dht11_valid_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state         <= 3'b000;
            dhtio_reg       <= 1'b1;
            tick_cnt_reg    <= 0;
            io_sel_reg      <= 1'b1;
            bit_cnt_reg     <= 0;
            data_reg        <= 0;
            humidity_reg    <= 0;
            temperature_reg <= 0;
            dht11_done_reg  <= 0;
            dht11_valid_reg <= 0;
        end else begin
            c_state         <= n_state;
            dhtio_reg       <= dhtio_next;
            tick_cnt_reg    <= tick_cnt_next;
            io_sel_reg      <= io_sel_next;
            bit_cnt_reg     <= bit_cnt_next;
            data_reg        <= data_next;
            dht11_done_reg  <= 0;
            humidity_reg    <= humidity_next;
            temperature_reg <= temperature_next;
            dht11_valid_reg <= dht11_valid_next;
        end
    end

    // next, output 
    always @(*) begin
        n_state          = c_state;
        tick_cnt_next    = tick_cnt_reg;
        dhtio_next       = dhtio_reg;
        io_sel_next      = io_sel_reg;
        bit_cnt_next     = bit_cnt_reg;
        data_next        = data_reg;
        humidity_next    = humidity_reg;
        temperature_next = temperature_reg;
        dht11_valid_next = dht11_valid_reg;
        case (c_state)
            IDLE: begin
                if (start) begin
                    n_state = START;
                end
            end
            START: begin
                dhtio_next = 1'b0;
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 1900) begin
                        tick_cnt_next = 0;
                        n_state = WAIT;
                    end
                end
            end
            WAIT: begin
                dhtio_next = 1'b1;
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 3) begin
                        // for output to high-z
                        n_state     = SYNC_L;
                        io_sel_next = 1'b0;
                    end
                end
            end
            SYNC_L: begin
                if (tick_10u) begin
                    if (dhtio == 1) begin
                        n_state = SYNC_H;
                    end
                end
            end
            SYNC_H: begin
                if (tick_10u) begin
                    if (dhtio == 0) begin
                        n_state = DATA_SYNC;
                    end
                end
            end
            DATA_SYNC: begin
                if (tick_10u) begin
                    if (dhtio == 1) begin
                        tick_cnt_next = 0;
                        n_state = DATA_C;
                    end
                end
            end
            DATA_C: begin
                if (tick_10u) begin
                    if (dhtio == 1) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end else begin
                        if (tick_cnt_reg >= 5) begin
                            data_next = {data_reg[38:0], 1'b1};
                        end else begin
                            data_next = {data_reg[38:0], 1'b0};
                        end
                        if (bit_cnt_reg == 39) begin
                            bit_cnt_next = 0;
                            n_state = STOP;
                            humidity_next = {
                                data_next[39:32], data_next[31:24]
                            };
                            temperature_next = {
                                data_next[23:16], data_next[15:8]
                            };
                            dht11_valid_next = ((data_next[39:32] + data_next[31:24]+data_next[23:16]+data_next[15:8]) == data_next[7:0]);
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                            n_state      = DATA_SYNC;
                        end
                        tick_cnt_next = 0;
                    end
                end
            end
            STOP: begin
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 5) begin
                        dht11_done_reg = 1'b1;
                        // output mode
                        dhtio_next  = 1'b1;
                        io_sel_next = 1'b1;
                        n_state     = IDLE;
                    end
                end
            end
        endcase
    end
endmodule

module tick_gen_10u (
    input      clk,
    input      rst,
    output reg tick_10u
);

    parameter F_COUNT = 100_000_000 / 100_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_10u    <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_10u    <= 1'b1;
            end else begin
                tick_10u <= 1'b0;
            end
        end
    end

endmodule
