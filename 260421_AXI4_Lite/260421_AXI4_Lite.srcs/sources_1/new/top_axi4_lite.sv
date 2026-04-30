`timescale 1ns / 1ps

module top_axi4_lite (
    input  logic        ACLK,
    input  logic        ARESETn,
    input  logic        transfer,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        write,
    output logic        ready,
    output logic [31:0] rdata
);

    // AW channel
    logic [31:0] axi_awaddr;
    logic        axi_awvalid;
    logic        axi_awready;
    // W channel 
    logic [31:0] axi_wdata;
    logic        axi_wvalid;
    logic        axi_wready;
    // B channel 
    logic [ 1:0] axi_bresp;
    logic        axi_bvalid;
    logic        axi_bready;
    // AR channel
    logic [31:0] axi_araddr;
    logic        axi_arvalid;
    logic        axi_arready;
    // R channel 
    logic [31:0] axi_rdata;
    logic        axi_rvalid;
    logic        axi_rready;
    logic [ 1:0] axi_rresp;

    axi4_lite_master u_master (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        .transfer(transfer),
        .ready   (ready),
        .addr    (addr),
        .wdata   (wdata),
        .write   (write),
        .rdata   (rdata),
        .AWADDR  (axi_awaddr),
        .AWVALID (axi_awvalid),
        .AWREADY (axi_awready),
        .WDATA   (axi_wdata),
        .WVALID  (axi_wvalid),
        .WREADY  (axi_wready),
        .BRESP   (axi_bresp),
        .BVALID  (axi_bvalid),
        .BREADY  (axi_bready),
        .ARADDR  (axi_araddr),
        .ARVALID (axi_arvalid),
        .ARREADY (axi_arready),
        .RDATA   (axi_rdata),
        .RVALID  (axi_rvalid),
        .RREADY  (axi_rready),
        .RRESP   (axi_rresp)
    );

    axi4_lite_slave u_slave (
        .ACLK   (ACLK),
        .ARESETn(ARESETn),
        .AWADDR (axi_awaddr),
        .AWVALID(axi_awvalid),
        .AWREADY(axi_awready),
        .WDATA  (axi_wdata),
        .WVALID (axi_wvalid),
        .WREADY (axi_wready),
        .BRESP  (axi_bresp),
        .BVALID (axi_bvalid),
        .BREADY (axi_bready),
        .ARADDR (axi_araddr),
        .ARVALID(axi_arvalid),
        .ARREADY(axi_arready),
        .RDATA  (axi_rdata),
        .RVALID (axi_rvalid),
        .RREADY (axi_rready),
        .RRESP  (axi_rresp)
    );

endmodule
