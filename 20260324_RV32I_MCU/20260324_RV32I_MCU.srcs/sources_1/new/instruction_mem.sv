`timescale 1ns / 1ps

module instruction_mem (  // mem : memory
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    logic [31:0] rom[0:2555];

    initial begin
        //$readmemh("riscv_rv32i_rom_data.mem", rom);
        //$readmemh("U_APB_BRAM.mem", rom);
        //$readmemh("APB_GPO.mem", rom);
        $readmemh("APB_BRAM_GPO_GPI.mem", rom);

        // R-Type Simulation
        //rom[0] = 32'h004182B3; // ADD x5, x3, x4
        //rom[1] = 32'h40408333; // SUB x6, x1, x4
        //rom[2] = 32'h002313B3; // SLL x7, x6, x2
        //rom[3] = 32'h00232433; // SLT x8, x6, x2
        //rom[4] = 32'h002334B3; // SLTU x9, x6, x2
        //rom[5] = 32'h00234533; // XOR x10, x6, x2
        //rom[6] = 32'h002355B3; // SRL x11, x6, x2
        //rom[7] = 32'h40235633; // SRA x12, x6, x2
        //rom[8] = 32'h002366B3; // OR x13, x6, x2
        //rom[9] = 32'h00237733; // AND x14, x6, x2

        // I-Type Simulation
        // 비교 연산(SLTI)을 테스트하기 위해 음수(-3) 생성
        //rom[0] = 32'h40408333; // SUB x6, x1, x4 
//
        //rom[1] = 32'h00A08513; // ADDI x10, x1, 10
        //rom[2] = 32'h00A32593; // SLTI x11, x6, 10
        //rom[3] = 32'h00A33613; // SLTIU x12, x6, 10
        //rom[4] = 32'h00A1C693; // XORI x13, x3, 10
        //rom[5] = 32'h00A26713; // ORI x14, x4, 10
        //rom[6] = 32'h00A0F793; // ANDI x15, x1, 10
        //rom[7] = 32'h00211813; // SLLI x16, x2, 2
        //rom[8] = 32'h00125893; // SRLI x17, x4, 1
        //rom[9] = 32'h40235913; // SRAI x18, x6, 2

        // IL-Type Simulation
        // Load로 읽어올 x10 레지스터에 음수(-17) 생성 (I-Type)
        //rom[0] = 32'hFEF00513; // ADDI x10, x0, -17

        // 2단계: Data RAM의 4번지에 음수(-17) 저장해두기 (S-Type)
        //rom[1] = 32'h00A02223; // SW x10, 4(x0)

        //rom[2] = 32'h00400283; // LB x5, 4(x0)
        //rom[3] = 32'h00801303; // LH x6, 8(x0)
        //rom[4] = 32'h00C02383; // LW x7, 12(x0)
        //rom[5] = 32'h01004403; // LBU x8, 16(x0)
        //rom[6] = 32'h01405483; // LHU x9, 20(x0)

        // S-Type Simulation
        // [SW 경우의 수 1개]
        //rom[0] = 32'h00222023; // SW x2, 0(x4)

        // [SH 경우의 수 2개]
        //rom[1] = 32'h00321223; // SH x3, 4(x4)
        //rom[2] = 32'h00321523; // SH x3, 10(x4)

        // [SB 경우의 수 4개]
        //rom[3] = 32'h00520623; // SB x5, 12(x4)
        //rom[4] = 32'h005208A3; // SB x5, 17(x4)
        //rom[5] = 32'h00520B23; // SB x5, 22(x4)
        //rom[6] = 32'h00520DA3; // SB x5, 27(x4)

        // B-Type Simulation
        // 조건 분기를 테스트하기 위해 음수(-3) 생성
        //rom[0] = 32'h40408333; // SUB x6, x1, x4
//
        //rom[1] = 32'h00230263; // BEQ x6, x2, 4
        //rom[2] = 32'h00231263; // BNE x6, x2, 4
        //rom[3] = 32'h00234263; // BLT x6, x2, 4
        //rom[4] = 32'h00235263; // BGE x6, x2, 4
        //rom[5] = 32'h00236263; // BLTU x6, x2, 4
        //rom[6] = 32'h00237263; // BGEU x6, x2, 4

        // U-Type
        //rom[0] = 32'h123452b7;  // LUI x5, 0x12345
        //rom[1] = 32'h00001317;  // AUIPC x6, 0x1

        // J-Type & JL-Type Simulation
        //rom[2] = 32'h008003EF; // JAL x7, 8   // PC=16으로 점프
        //rom[3] = 32'h3E700413; // ADDI x8, x0, 999 // 건너뛰어져야 코드
        //rom[4] = 32'h004004E7; // JALR x9, x0, 4     // PC=4로 백점프

        //rom[0] = 32'h004182b3;  // R : ADD X5, X3, X4    
        //rom[1] = 32'h00812123;  // S : SW X2, 2(X8), SW X2, X8, 2
        //rom[2] = 32'h00212383;  // I : LW X7, X2, 2
        //rom[3] = 32'h00438413;  // I : ADDi X8, X7, 4
        //rom[4] = 32'h00840463;  // B : BEQ X8, X8, 8
        //rom[5] = 32'h004182b3;  // R : ADD X5, X3, X4
        //rom[6] = 32'h00812123;  // S : SW X2, 2(X8), SW X2, X8, 2
        //rom[7] = 32'h123452b7;  // U : LUI X5, 0X12345
        //rom[8] = 32'h00001337;  // U : AUIPC X6, 0X1

    end

    assign instr_data = rom[instr_addr[31:2]];

endmodule
