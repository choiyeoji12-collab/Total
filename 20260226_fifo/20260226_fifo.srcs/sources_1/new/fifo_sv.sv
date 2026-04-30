`timescale 1ns / 1ps

module fifo_sv (
    input  logic       clk,
    input  logic       rst,
    input  logic       we,     //push
    input  logic       re,     //pop
    input  logic [7:0] wdata,  // push_data
    output logic [7:0] rdata,  // pop_data
    output logic       full,
    output logic       empty
);

    logic [3:0] w_addr, r_addr;

    register_file U_REG_FILE (
        .clk   (clk),
        .wdata (wdata),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .we    (we & (~full)),
        .rdata (rdata)
    );

    control_unit U_CONTROL_UNIT (
        .clk  (clk),
        .rst  (rst),
        .we   (we),
        .re   (re),
        .wptr (w_addr),
        .rptr (r_addr),
        .full (full),
        .empty(empty)
    );

endmodule


module register_file (
    input  logic       clk,
    input  logic [7:0] wdata,
    input  logic [3:0] w_addr,
    input  logic [3:0] r_addr,
    input  logic       we,
    output logic [7:0] rdata
);

    // ram 
    reg [7:0] ram[0:15];

    // we, to register_file
    always_ff @(posedge clk) begin
        if (we) begin
            ram[w_addr] <= wdata;
        end
    end

    // re
    assign rdata = ram[r_addr];

endmodule

module control_unit (
    input  logic       clk,
    input  logic       rst,
    input  logic       we,    // push
    input  logic       re,    // pop
    output logic [3:0] wptr,
    output logic [3:0] rptr,
    output logic       full,
    output logic       empty
);

    logic [3:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    logic full_reg, full_next, empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    // state
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    // next st, output CL
    always_comb begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            we, re
        })
            // re
            2'b01: begin
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            // we
            2'b10: begin
                if (!full_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            // we, re
            2'b11: begin
                if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end

endmodule
