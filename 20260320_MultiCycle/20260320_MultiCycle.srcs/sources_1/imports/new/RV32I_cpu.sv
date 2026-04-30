`timescale 1ns / 1ps
`include "define.vh"

module RV32I_cpu (
    input               clk,
    input               rst,
    input        [31:0] instr_data,
    input        [31:0] drdata,
    output logic [31:0] instr_addr,
    output              dwe,
    output       [ 2:0] o_funct3,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);

    logic pc_en, rf_we, alu_src, jal, jalr;
    logic [2:0] rfwd_src;
    logic [3:0] alu_control;

    control_unit U_CONTROL_UNIT (
        .clk        (clk),
        .rst        (rst),
        .funct7     (instr_data[31:25]),
        .funct3     (instr_data[14:12]),
        .opcode     (instr_data[6:0]),
        .pc_en      (pc_en),              // for multi cycle Fetch : pc 
        .rf_we      (rf_we),
        .jal        (jal),
        .jalr       (jalr),
        .branch     (branch),
        .alu_src    (alu_src),
        .alu_control(alu_control),
        .rfwd_src   (rfwd_src),
        .o_funct3   (o_funct3),
        .dwe        (dwe)
    );

    RV32I_datapath U_DATAPATH (.*);

endmodule

module control_unit (
    input              clk,
    input              rst,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       pc_en,
    output logic       rf_we,
    output logic       jal,
    output logic       jalr,
    output logic       branch,
    output logic       alu_src,
    output logic [3:0] alu_control,
    output logic [2:0] rfwd_src,
    output logic [2:0] o_funct3,
    output logic       dwe
);

    // 
    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        //   EXE_R,
        //  EXE_I,
        //  EXE_S,
        //  EXE_B,
        //  EXE_IL,
        //  EXE_J,
        //  EXE_JL,
        //  EXE_LUI,
        //  EXE_AUIPC,
        MEM,
        //  MEM_S,
        //  MEM_IL,
        WB
    } state_e;

    state_e c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= FETCH;  // reset되면 무조건 FETCH부터 시작
        end else begin
            c_state <= n_state;  // 매 클럭마다 다음 상태로 이동
        end
    end

    // next CL
    always_comb begin
        n_state = c_state;  // Latch 방지
        case (c_state)
            FETCH: begin
                n_state = DECODE;
            end
            DECODE: begin
                n_state = EXECUTE;
            end
            EXECUTE: begin
                case (opcode)
                    `R_TYPE:     n_state = FETCH;
                    `I_TYPE:     n_state = FETCH;
                    `IL_TYPE:    n_state = MEM;
                    `S_TYPE:     n_state = MEM;
                    `B_TYPE:     n_state = FETCH;
                    `LUI_TYPE:   n_state = FETCH;
                    `AUIPC_TYPE: n_state = FETCH;
                    `J_TYPE:     n_state = FETCH;
                    `JL_TYPE:    n_state = FETCH;
                endcase
            end
            MEM: begin
                case (opcode)
                    `S_TYPE:  n_state = FETCH;
                    `IL_TYPE: n_state = WB;
                endcase
            end
            WB: begin
                n_state = FETCH;
            end
        endcase
    end

    //output CL
    always_comb begin
        pc_en       = 1'b0;
        rf_we       = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        branch      = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        rfwd_src    = 3'b000;
        o_funct3    = 3'b000;  // for S type, IL type
        dwe         = 1'b0;  // for S type, IL type
        case (c_state)
            FETCH: begin
                pc_en = 1'b1;   // PC 값을 업데이트 해서 다음번 PC를 준비해둠
            end

            DECODE: begin
                // 아무 신호도 켜지 않음
                // 명령어를 읽고 레지스터 파일에서 값 읽기
            end

            // 연산 단계 (ALU)
            EXECUTE: begin
                case (opcode)
                    `R_TYPE: begin
                        rf_we       = 1'b1;  // next state FETCH
                        alu_src     = 1'b0;
                        alu_control = {funct7[5], funct3};
                    end
                    `I_TYPE: begin
                        rf_we   = 1'b1;  // next state FETCH
                        alu_src = 1'b1;
                        if (funct3 == 3'b101)
                            alu_control = {funct7[5], funct3};  // SRL, SRA
                        else alu_control = {1'b0, funct3};
                    end
                    `B_TYPE: begin
                        branch      = 1'b1;
                        alu_src     = 1'b0;
                        alu_control = {1'b0, funct3};
                    end
                    `S_TYPE: begin
                        alu_src = 1'b1;
                        alu_control = 4'b0000;  // add for dwaddr
                    end
                    `IL_TYPE: begin
                        alu_src     = 1'b1;
                        alu_control = 4'b0000;  // add for dwaddr
                    end
                    `LUI_TYPE: begin
                        rf_we    = 1'b1;  // next state FETCH
                        rfwd_src = 3'b010;
                    end
                    `AUIPC_TYPE: begin
                        rf_we    = 1'b1;  // next state FETCH
                        rfwd_src = 3'b011;
                    end
                    `J_TYPE, `JL_TYPE: begin
                        rf_we = 1'b1;  // next state FETCH
                        jal   = 1'b1;
                        if (opcode == `JL_TYPE) jalr = 1'b1;  // JALR
                        else jalr = 1'b0;  // JAL
                        rfwd_src = 3'b100;
                    end
                endcase
            end

            MEM: begin
                o_funct3 = funct3;
                if (opcode == `S_TYPE) dwe = 1'b1;
            end

            WB: begin
                // IL type
                rf_we    = 1'b1;    // next state FETCH
                rfwd_src = 3'b001;
            end
        endcase
    end

    //    always_comb begin
    //        rf_we       = 1'b0;
    //        jal         = 1'b0;
    //        jalr        = 1'b0;
    //        branch      = 1'b0;
    //        alu_src     = 1'b0;
    //        alu_control = 4'b0000;
    //        rfwd_src    = 3'b000;
    //        o_funct3    = 3'b000;
    //        dwe         = 1'b0;
    //        case (opcode)
    //            `R_TYPE: begin      // R-type, to write register file, alu_control == {funct7[5], funct3}
    //                rf_we       = 1'b1;
    //                jal         = 1'b0;
    //                jalr        = 1'b0;
    //                branch      = 1'b0;
    //                alu_src     = 1'b0;
    //                alu_control = {funct7[5], funct3};
    //                rfwd_src    = 3'b000;
    //                o_funct3    = 3'b000;
    //                dwe         = 1'b0;
    //            end
    //            `B_TYPE: begin
    //                rf_we       = 1'b0;
    //                jal         = 1'b0;
    //                jalr        = 1'b0;
    //                branch      = 1'b1;
    //                alu_src     = 1'b0;
    //                alu_control = {1'b0, funct3};
    //                rfwd_src    = 3'b000;
    //                o_funct3    = 3'b000;
    //                dwe         = 1'b0;
    //            end
    //            `S_TYPE: begin
    //                rf_we       = 1'b0;
    //                jal         = 1'b0;
    //                jalr        = 1'b0;
    //                branch      = 1'b0;
    //                alu_src     = 1'b1;
    //                alu_control = 4'b0000;
    //                rfwd_src    = 3'b000;
    //                o_funct3    = funct3;
    //                dwe         = 1'b1;
    //            end
    //            `IL_TYPE: begin
    //                rf_we       = 1'b1;
    //                jal         = 1'b0;
    //                jalr        = 1'b0;
    //                branch      = 1'b0;
    //                alu_src     = 1'b1;
    //                alu_control = 4'b0000;
    //                rfwd_src    = 3'b001;
    //                o_funct3    = funct3;
    //                dwe         = 1'b0;
    //            end
    //            `I_TYPE: begin
    //                rf_we = 1'b1;
    //                jal = 1'b0;
    //                jalr = 1'b0;
    //                branch = 1'b0;
    //                alu_src = 1'b1;
    //                if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
    //                else alu_control = {1'b0, funct3};
    //                rfwd_src = 3'b000;
    //                o_funct3 = funct3;
    //                dwe      = 1'b0;
    //            end
    //            `LUI_TYPE: begin
    //                rf_we       = 1'b1;
    //                jal         = 1'b0;
    //                jalr        = 1'b0;
    //                branch      = 1'b0;
    //                alu_src     = 1'b0;
    //                alu_control = 4'b0000;
    //                rfwd_src    = 3'b010;
    //                o_funct3    = funct3;
    //                dwe         = 1'b0;
    //            end
    //            `AUIPC_TYPE: begin
    //                rf_we       = 1'b1;
    //                jal         = 1'b0;
    //                jalr        = 1'b0;
    //                branch      = 1'b0;
    //                alu_src     = 1'b0;
    //                alu_control = 4'b0000;
    //                rfwd_src    = 3'b011;
    //                o_funct3    = funct3;
    //                dwe         = 1'b0;
    //            end
    //            `J_TYPE, `JL_TYPE: begin
    //                rf_we = 1'b1;
    //                jal   = 1'b1;
    //                if (opcode == `JL_TYPE) jalr = 1'b1;  // JALR
    //                else jalr = 1'b0;  // JAL
    //                branch      = 1'b0;
    //                alu_src     = 1'b0;
    //                alu_control = 4'b0000;
    //                rfwd_src    = 3'b100;
    //                o_funct3    = funct3;
    //                dwe         = 1'b0;
    //            end
    //        endcase
    //    end

endmodule

