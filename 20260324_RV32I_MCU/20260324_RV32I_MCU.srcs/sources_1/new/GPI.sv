`timescale 1ns / 1ps

// 외부 핀에서 들어오는 신호를 CPU가 읽어올 때 사용하는 모듈
module GPI (
    input               PCLK,
    input               PRESET,
    input        [31:0] PADDR,
    input        [31:0] PWDATA,
    input               PENABLE,
    input               PWRITE,
    input               PSEL,

    // 외부에서 들어오는 16비트 입력 핀
    input        [15:0] GPI,

    output logic [31:0] PRDATA,
    output logic        PREADY
);

    localparam [11:0] GPI_CTL_ADDR = 12'h000;   // 제어 레지스터 주소
    localparam [11:0] GPI_IDATA_ADDR = 12'h004; // 입력 데이터 레지스터 주소 (외부에서 읽어온 값)

    logic [15:0] GPI_IDATA_REG, GPI_CTL_REG;

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    // Read 동작: CPU가 주소를 주면 register 값을 변환
    assign PRDATA = (PADDR[11:0] == GPI_CTL_ADDR) ? {16'h0000, GPI_CTL_REG} : 
                    (PADDR[11:0] == GPI_IDATA_ADDR) ? {16'h0000, GPI_IDATA_REG} : 32'hxxxx_xxxx;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            GPI_CTL_REG   <= 16'h0000;
           // GPI_IDATA_REG <= 16'h0000;
        end else begin
            // Write 동작: 입력 모듈이므로 제어 레지스터(CTL)에만 값을 씀
            // (데이터는 외부에서 들어오므로 쓰지 않음)
            if (PREADY & PWRITE) begin
                case (PADDR[11:0])
                    GPI_CTL_ADDR: GPI_CTL_REG <= PWDATA[15:0];
                endcase
            end
        end
    end

    // 외부 핀(GPI)에서 레지스터(GPI_IDATA_REG)로 데이터를 가져오는 로직
    //assign GPO_OUT = (GPO_CTL_REG) ? GPO_ODATA_REG : 16'hzzzz;
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            // 제어 레지스터(CTL)가 1로 활성화되어 있을 때만 외부 입력 핀(GPI)의 상태를 읽어옴
            assign GPI_IDATA_REG[i] = (GPI_CTL_REG[i]) ? GPI[i] : 1'bz;
        end
    endgenerate
endmodule
