
`define SIMULATION 1

// OP code
`define R_TYPE 7'b011_0011
`define B_TYPE 7'b110_0011
`define S_TYPE 7'b010_0011
`define I_TYPE 7'b001_0011
`define IL_TYPE 7'b000_0011
`define LUI_TYPE 7'b011_0111       // U-Type
`define AUIPC_TYPE 7'b001_0111     // U-Type
`define J_TYPE 7'b110_1111 
`define JL_TYPE 7'b110_0111 


// R-type instruction

`define ADD 4'b0_000
`define SUB 4'b1_000
`define SLL 4'b0_001
`define SLT 4'b0_010
`define SLTU 4'b0_011
`define XOR 4'b0_100
`define SRL 4'b0_101
`define SRA 4'b1_101
`define OR 4'b0_110
`define AND 4'b0_111

// B-type instruction

`define BEQ 4'b0_000
`define BNE 4'b0_001
`define BLT 4'b0_100
`define BGE 4'b0_101
`define BLTU 4'b0_110
`define BGEU 4'b0_111

// S-Type instruction
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010

// IL-Type instruction
`define LB 3'b000
`define LH 3'b001
`define LW 3'b010
`define LBU 3'b100
`define LHU 3'b101

// I-Type instruction
`define ADDI 3'b000
`define SLTI 3'b010
`define SLTIU 3'b011
`define XORI 3'b100
`define ORI 3'b110 
`define ANDI 3'b111 
`define SLLI 3'b001
`define SRLI 3'b101
`define SRAI 3'b101
