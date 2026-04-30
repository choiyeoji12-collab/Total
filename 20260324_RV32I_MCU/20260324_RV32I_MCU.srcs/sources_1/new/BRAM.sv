`timescale 1ns / 1ps

// RAM_Slave, RAM
module BRAM (
    // BUS Global signal
    input               PCLK,
    // APB Interface signal
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);

    logic [31:0] bmem[0:1023];  // 1024 * 4byte : 4K

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    always_ff @(posedge PCLK) begin
        if (PSEL & PENABLE & PWRITE) begin
            bmem[PADDR[11:2]] <= PWDATA;
        end
    end


    assign PRDATA = bmem[PADDR[11:2]];

endmodule
