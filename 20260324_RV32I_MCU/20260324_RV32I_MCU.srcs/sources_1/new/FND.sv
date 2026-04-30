`timescale 1ns / 1ps

module FND (
    input               PCLK,
    input               PRESET,
    // APB Interface
    input        [31:0] PADDR,
    input        [31:1] PWDATA,
    input               PWRITE,
    input               PENABLE,
    input               PSEL,
    output logic [31:0] PRDATA,
    output logic [31:0] PREADY,

    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);

    localparam [11:0] FND_CTL_ADDR  = 12'h000;  // 제어 레지스터 주소 (sel_display 제어용)
    localparam [11:0] FND_DATA_ADDR = 12'h004;  // 데이터 레지스터 주소 (출력할 24비트 값)

    logic [31:0] FND_CTL_REG;
    logic [31:0] FND_DATA_REG;

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    // Read 동작: CPU가 FND 레지스터 값을 읽어갈 때
    assign PRDATA = (PADDR[11:0] == FND_CTL_ADDR)  ? FND_CTL_REG : 
                    (PADDR[11:0] == FND_DATA_ADDR) ? FND_DATA_REG : 32'hxxxx_xxxx;

    // Write 동작: CPU가 FND에 값을 쓸 때
    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            FND_CTL_REG  <= 32'd0;
            FND_DATA_REG <= 32'd0;
        end else begin
            if (PREADY & PWRITE) begin
                case (PADDR[11:0])
                    FND_CTL_ADDR:  FND_CTL_REG <= PWDATA;
                    FND_DATA_ADDR: FND_DATA_REG <= PWDATA;
                endcase
            end
        end
    end

    fnd_controller U_FND_CTRL (
        .clk(PCLK),
        .reset(PRESET),
        .sel_display(FND_CTL_REG[0]),     // 제어 레지스터의 0번 비트를 연결
        .fnd_in_data(FND_DATA_REG[23:0]), // 데이터 레지스터의 하위 24비트 연결
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );
endmodule
