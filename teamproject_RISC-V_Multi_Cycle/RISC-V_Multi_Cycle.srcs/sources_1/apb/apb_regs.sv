`timescale 1ns / 1ps

module apb_regs #(
    parameter int DW = 32,
    parameter int AW = 8,
    parameter logic [31:0] ID_VALUE = 32'h4150_4230
) (
    input  logic              pclk,
    input  logic              presetn,

    input  logic [AW-1:0]     paddr,
    input  logic              psel,
    input  logic              penable,
    input  logic              pwrite,
    output logic              pready,
    input  logic [DW-1:0]     pwdata,
    input  logic [DW/8-1:0]   pstrb,
    output logic [DW-1:0]     prdata,
    output logic              pslverr,

    input  logic [31:0]       status32,
    input  logic [15:0]       status16,
    input  logic [7:0]        status8,
    output logic [31:0]       control32,
    output logic [15:0]       control16,
    output logic [7:0]        control8
);

    localparam logic [AW-1:0] ADDR_ID        = 'h00;
    localparam logic [AW-1:0] ADDR_CONTROL32 = 'h04;
    localparam logic [AW-1:0] ADDR_CONTROL16 = 'h08;
    localparam logic [AW-1:0] ADDR_CONTROL8  = 'h0C;
    localparam logic [AW-1:0] ADDR_STATUS32  = 'h14;
    localparam logic [AW-1:0] ADDR_STATUS16  = 'h18;
    localparam logic [AW-1:0] ADDR_STATUS8   = 'h1C;

    logic apb_access;
    logic wr_en;
    logic rd_en;
    logic addr_is_known;
    logic wr_is_allowed;

    function automatic [31:0] apply_strb32(
        input [31:0] old_value,
        input [31:0] new_value,
        input [3:0]  strobe
    );
        apply_strb32 = old_value;
        if (strobe[0]) apply_strb32[7:0]   = new_value[7:0];
        if (strobe[1]) apply_strb32[15:8]  = new_value[15:8];
        if (strobe[2]) apply_strb32[23:16] = new_value[23:16];
        if (strobe[3]) apply_strb32[31:24] = new_value[31:24];
    endfunction

    assign apb_access = psel & penable;
    assign wr_en      = apb_access & pwrite;
    assign rd_en      = apb_access & ~pwrite;

    assign pready = 1'b1;

    always_comb begin
        unique case (paddr)
            ADDR_ID,
            ADDR_CONTROL32,
            ADDR_CONTROL16,
            ADDR_CONTROL8,
            ADDR_STATUS32,
            ADDR_STATUS16,
            ADDR_STATUS8: addr_is_known = 1'b1;
            default:      addr_is_known = 1'b0;
        endcase
    end

    always_comb begin
        unique case (paddr)
            ADDR_CONTROL32,
            ADDR_CONTROL16,
            ADDR_CONTROL8: wr_is_allowed = 1'b1;
            default:       wr_is_allowed = 1'b0;
        endcase
    end

    assign pslverr = apb_access & (~addr_is_known | (pwrite & ~wr_is_allowed));

    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            control32 <= '0;
            control16 <= '0;
            control8  <= '0;
        end else if (wr_en && !pslverr) begin
            unique case (paddr)
                ADDR_CONTROL32: control32 <= apply_strb32(control32, pwdata, pstrb);
                ADDR_CONTROL16: begin
                    if (pstrb[0]) control16[7:0]  <= pwdata[7:0];
                    if (pstrb[1]) control16[15:8] <= pwdata[15:8];
                end
                ADDR_CONTROL8: begin
                    if (pstrb[0]) control8 <= pwdata[7:0];
                end
                default: begin
                end
            endcase
        end
    end

    always_comb begin
        prdata = '0;
        unique case (paddr)
            ADDR_ID:        prdata = ID_VALUE;
            ADDR_CONTROL32: prdata = control32;
            ADDR_CONTROL16: prdata = {16'h0000, control16};
            ADDR_CONTROL8:  prdata = {24'h000000, control8};
            ADDR_STATUS32:  prdata = status32;
            ADDR_STATUS16:  prdata = {16'h0000, status16};
            ADDR_STATUS8:   prdata = {24'h000000, status8};
            default:        prdata = '0;
        endcase
    end

endmodule
