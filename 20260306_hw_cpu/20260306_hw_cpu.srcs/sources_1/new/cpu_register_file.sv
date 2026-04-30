`timescale 1ns / 1ps

module cpu_register_file (
    input        clk,
    input        rst,
    output [7:0] out
);

    logic rf_srcsel, we, outload, ilq10;
    logic [1:0] wa, ra0, ra1;

    control_unit U_CONTROL_UNIT (.*);

    datapath U_DATAPATH (.*);

endmodule

module control_unit (
    input              clk,
    input              rst,
    input              ilq10,
    output logic       rf_srcsel,
    output logic       we,
    output logic [1:0] wa,
    output logic [1:0] ra0,
    output logic [1:0] ra1,
    output logic       outload
);

    typedef enum logic [2:0] {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5,
        S6
    } state_t;

    state_t c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= S0;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        n_state   = c_state;
        rf_srcsel = 0;
        ra0       = 0;
        ra1       = 0;
        we        = 0;
        wa        = 0;
        outload   = 0;
        case (c_state)
            S0: begin
                rf_srcsel = 0;
                ra0       = 0;
                ra1       = 0;
                wa        = 3;
                we        = 1;
                n_state   = S1;
            end
            S1: begin
                rf_srcsel = 1;
                ra0       = 0;
                ra1       = 0;
                wa        = 1;
                we        = 1;
                n_state   = S2;
            end
            S2: begin
                rf_srcsel = 1;
                ra0       = 0;
                ra1       = 0;
                wa        = 2;
                we        = 1;
                n_state   = S3;
            end
            S3: begin
                rf_srcsel = 0;
                ra0       = 1;
                ra1       = 0;
                wa        = 0;
                we        = 0;
                if (ilq10) n_state = S4;
                else n_state = S6;
            end
            S4: begin
                rf_srcsel = 1;
                ra0       = 1;
                ra1       = 2;
                wa        = 2;
                we        = 1;
                n_state   = S5;
            end
            S5: begin
                rf_srcsel = 1;
                ra0       = 1;
                ra1       = 3;
                wa        = 1;
                we        = 1;
                n_state   = S3;
            end
            S6: begin
                rf_srcsel = 0;
                ra0       = 2;
                ra1       = 0;
                wa        = 0;
                we        = 0;
                outload   = 1;
            end
        endcase
    end

endmodule

module datapath (
    input        clk,
    input        rst,
    input        rf_srcsel,
    input  [1:0] ra0,
    input  [1:0] ra1,
    input  [1:0] wa,
    input        we,
    input        outload,
    output       ilq10,
    output [7:0] out
);

    logic [7:0] w_aluout, WD, rd0, rd1;

    mux_2x1 U_ASRCMUX (
        .a      (1),          // 0
        .b      (w_aluout),   // 1
        .asrcsel(rf_srcsel),
        .mux_out(WD)
    );

    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .ra0(ra0),
        .ra1(ra1),
        .wa (wa),
        .we (we),
        .WD (WD),
        .rd0(rd0),
        .rd1(rd1)
    );

    alu U_ALU (
        .a      (rd0),
        .b      (rd1),
        .alu_out(w_aluout)
    );

    ilq10_comp U_ILQ10 (
        .in_data(rd0),
        .ilq10  (ilq10)
    );

    register U_OUTREG (
        .clk     (clk),
        .rst     (rst),
        .load    (outload),
        .in_data (rd0),
        .out_data(out)
    );

endmodule

module register_file (
    input              clk,
    input              rst,
    input        [1:0] ra0,
    input        [1:0] ra1,
    input        [1:0] wa,
    input              we,
    input        [7:0] WD,
    output logic [7:0] rd0,
    output logic [7:0] rd1
);

    logic [7:0] areg[0:3];

    assign rd0 = (ra0 == 0) ? 0 : areg[ra0];
    assign rd1 = (ra1 == 0) ? 0 : areg[ra1];

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            areg[1] <= 0;
            areg[2] <= 0;
            areg[3] <= 0;
        end else begin
            if (we) begin
                areg[wa] <= WD;
            end
        end
    end
endmodule

module register (
    input              clk,
    input              rst,
    input              load,
    input        [7:0] in_data,
    output logic [7:0] out_data
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) out_data <= 0;
        else if (load) out_data <= in_data;
    end

endmodule

module alu (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);

    assign alu_out = a + b;

endmodule

module mux_2x1 (
    input  [7:0] a,
    input  [7:0] b,
    input        asrcsel,
    output [7:0] mux_out
);

    assign mux_out = (asrcsel) ? b : a;

endmodule

module ilq10_comp (
    input  [7:0] in_data,
    output       ilq10
);

    assign ilq10 = (in_data <= 10);

endmodule
