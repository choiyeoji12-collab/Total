`timescale 1ns / 1ps

// CPU가 데이터를 외부 핀으로 출력할 때 사용하는 모듈
module GPO (
    input               PCLK,
    input               PRESET,
    // CPU -> BUS -> 주변 장치로 전달
    input        [31:0] PADDR,
    input        [31:0] PWDATA,
    input               PWRITE,
    input               PENABLE,
    input               PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // 실제 외부로 나가는 16비트 출력 핀
    output logic [15:0] GPO_OUT
);

    localparam [11:0] GPO_CTL_ADDR = 12'h000;   // 제어 레지스터 주소 (핀 활성화 여부)
    localparam [11:0] GPO_ODATA_ADDR = 12'h004; // 출력 데이터 레지스터 주소 (실제 내보낼 값)

    logic [15:0] GPO_ODATA_REG, GPO_CTL_REG;
    // GPO_ODATA_REG (Output Data-내용물) : 실제로 밖으로 내보내고 싶은 값(Data)
    // GPO_CTL_REG (Control-전원 스위치) : ODATA의 값을 밖으로 내보내고 싶은지 결정하는 스위치 역할

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    // Read 동작: CPU가 주소를 주면 해당 레지스터의 값을 읽어서 PRDATA로 보냄
    assign PRDATA = (PADDR[11:0] == GPO_CTL_ADDR)   ? {16'h0000,GPO_CTL_REG}  : 
                    (PADDR[11:0] == GPO_ODATA_ADDR) ? {16'h0000,GPO_ODATA_REG}: 32'hxxxx_xxxx;

    // Write 동작: 클럭에 맞춰 데이터를 레지스터에 저장
    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            // 리셋 시 register 초기화
            GPO_CTL_REG   <= 16'h0000;
            GPO_ODATA_REG <= 16'h0000;
        end else begin
            if (PREADY & PWRITE) begin
                case (PADDR[11:0])
                    GPO_CTL_ADDR:   GPO_CTL_REG <= PWDATA[15:0];  // GPO CTL REG
                    GPO_ODATA_ADDR: GPO_ODATA_REG <= PWDATA[15:0];
                endcase
            end
        end
    end

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            // 제어 레지스터(CTL)의 비트가 1일 때만 데이터(ODATA)를 출력함
            // 0일 때는 High-Impedance(연결 끊김 상태)로 설정
            assign GPO_OUT[i] = (GPO_CTL_REG[i]) ? GPO_ODATA_REG[i] : 1'bz;
        end
    endgenerate

endmodule




/*
    logic we;

    assign we = PENABLE & PSEL & PWRITE;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            PREADY <= 1'b0;
        end else begin
            PREADY <= 1'b1;
        end
    end

    oreg U_OREG (
        .clk  (PCLK),
        .rst  (PRESET),
        .wdata(PWDATA[7:0]),
        .we   (we),
        .GPO0 (GPO0),
        .GPO1 (GPO1),
        .GPO2 (GPO2),
        .GPO3 (GPO3),
        .GPO4 (GPO4),
        .GPO5 (GPO5),
        .GPO6 (GPO6),
        .GPO7 (GPO7)
    );

endmodule

module oreg (
    input              clk,
    input              rst,
    input        [7:0] wdata,
    input              we,
    output logic       GPO0,
    output logic       GPO1,
    output logic       GPO2,
    output logic       GPO3,
    output logic       GPO4,
    output logic       GPO5,
    output logic       GPO6,
    output logic       GPO7
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            GPO0 <= 1'b0;
            GPO1 <= 1'b0;
            GPO2 <= 1'b0;
            GPO3 <= 1'b0;
            GPO4 <= 1'b0;
            GPO5 <= 1'b0;
            GPO6 <= 1'b0;
            GPO7 <= 1'b0;
        end else begin
            if (we) begin
                GPO0 <= wdata[0];
                GPO1 <= wdata[1];
                GPO2 <= wdata[2];
                GPO3 <= wdata[3];
                GPO4 <= wdata[4];
                GPO5 <= wdata[5];
                GPO6 <= wdata[6];
                GPO7 <= wdata[7];
            end
        end
    end

endmodule
*/
