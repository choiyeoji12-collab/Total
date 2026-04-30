`timescale 1ns / 1ps

module data_mem (
    input               clk,
    input               rst,
    input               dwe,
    input        [ 2:0] i_funct3,
    input        [31:0] daddr,
    input        [31:0] dwdata,
    output logic [31:0] drdata
);

    // byte address
    //    logic [7:0] dmem[0:31];
    //
    //    always_ff @(posedge clk) begin
    //        if (dwe) begin
    //            dmem[daddr+0] <= ddata[7:0];
    //            dmem[daddr+1] <= ddata[15:8];
    //            dmem[daddr+2] <= ddata[23:16];
    //            dmem[daddr+3] <= ddata[31:24];
    //        end
    //    end
    //
    //    assign drdata = {
    //        dmem[daddr], dmem[daddr+1], dmem[daddr+2], dmem[daddr+3]
    //    };

    // word address
    logic [31:0] dmem[0:255];

    // S-Type
    always_ff @(posedge clk) begin
        if (dwe) begin
            case (i_funct3)
                3'b000: begin  // SB
                    case (daddr[1:0])
                        2'b00: dmem[daddr[31:2]][7:0] <= dwdata[7:0];
                        2'b01: dmem[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b10: dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: dmem[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end

                3'b001: begin  // SH
                    if (daddr[1] == 1'b0) begin
                        dmem[daddr[31:2]][15:0] <= dwdata[15:0];
                    end else begin
                        dmem[daddr[31:2]][31:16] <= dwdata[15:0];
                    end
                end

                3'b010: begin  // SW
                    dmem[daddr[31:2]] <= dwdata;
                end
            endcase
        end
    end

    // IL-Type
    always_comb begin
        drdata = dmem[daddr[31:2]];
        case (i_funct3)
            3'b000: begin  // LB
                case (daddr[1:0])
                    2'b00:
                    drdata = {
                        {24{dmem[daddr[31:2]][7]}}, dmem[daddr[31:2]][7:0]
                    };
                    2'b01:
                    drdata = {
                        {24{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:8]
                    };
                    2'b10:
                    drdata = {
                        {24{dmem[daddr[31:2]][23]}}, dmem[daddr[31:2]][23:16]
                    };
                    2'b11:
                    drdata = {
                        {24{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:24]
                    };
                endcase
            end
            3'b001: begin  // LH
                if (daddr[1] == 1'b0) begin
                    drdata = {
                        {16{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:0]
                    };
                end else begin
                    drdata = {
                        {16{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:16]
                    };
                end
            end
            3'b010: begin  // LW
                drdata = dmem[daddr[31:2]];
            end
            3'b100: begin  // LBU
                case (daddr[1:0])
                    2'b00: drdata = {24'b0, dmem[daddr[31:2]][7:0]};
                    2'b01: drdata = {24'b0, dmem[daddr[31:2]][15:8]};
                    2'b10: drdata = {24'b0, dmem[daddr[31:2]][23:16]};
                    2'b11: drdata = {24'b0, dmem[daddr[31:2]][31:24]};
                endcase
            end
            3'b101: begin  // LHU
                if (daddr[1] == 1'b0) begin
                    drdata = {16'b0, dmem[daddr[31:2]][15:0]};
                end else begin
                    drdata = {16'b0, dmem[daddr[31:2]][31:16]};
                end
            end
        endcase
    end

endmodule

//module data_ram (
//    input clk,
//    input dwe,
//    input [31:0] daddr,
//    input [31:0] data_in,
//    output [31:0] data_out
//);
//
//logic [31:0] dmem[0:255];
//always_ff @( posedge clk ) begin 
//    if (dwe) begin
//        dmem[daddr[31:2]] <= data_in;   // SW
//    end
//end
//
//assign data_out = dmem[daddr[31:2]];
//    
//endmodule