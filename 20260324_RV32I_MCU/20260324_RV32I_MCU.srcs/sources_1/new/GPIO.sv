`timescale 1ns / 1ps

// 하나의 핀을 방향에 따라 입력으로도, 출력으로도 사용할 수 있는 복합 모듈
module GPIO (
    input               PCLK,
    input               PRESET,
    input        [31:0] PADDR,
    input        [31:0] PWDATA,
    input               PENABLE,
    input               PWRITE,
    input               PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // 외부 입출력 핀 
    //external ports
    inout  logic [15:0] GPIO
);

    localparam [11:0] GPIO_CTL_ADDR = 12'h000;  // 제어(방향) 레지스터 주소 (1:출력/0:입력)
    localparam [11:0] GPIO_ODATA_ADDR = 12'h004;    // 출력 데이터 레지스터 주소
    localparam [11:0] GPIO_IDATA_ADDR = 12'h008;    // 입력 데이터 레지스터 주소

    logic [15:0] GPIO_ODATA_REG, GPIO_CTL_REG,GPIO_IDATA_REG;

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    // Read 동작 
    assign PRDATA = (PADDR[11:0] == GPIO_CTL_ADDR) ? {16'h0000, GPIO_CTL_REG} : 
                    (PADDR[11:0] == GPIO_ODATA_ADDR) ? {16'h0000, GPIO_ODATA_REG} : 
                    (PADDR[11:0] == GPIO_IDATA_ADDR) ? {16'h0000, GPIO_IDATA_REG} : 32'hxxxx_xxxx;
    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            GPIO_CTL_REG   <= 16'h0000;
            GPIO_ODATA_REG <= 16'h0000;
           // GPIO_IDATA_REG <= 16'h0000;
        end else begin
            if (PREADY) begin
                if (PWRITE) begin
                    // Write 동작: 제어 레지스터와 출력 레지스터에 값을 쓸 수 있음
                    case (PADDR[11:0])
                        GPIO_CTL_ADDR:
                        GPIO_CTL_REG <= PWDATA[15:0];  //GPIO CTL REG
                        GPIO_ODATA_ADDR: GPIO_ODATA_REG <= PWDATA[15:0];
                    endcase
                end 
            end
        end
    end

    // APB 로직과 실제 물리적인 핀 제어 로직을 분리함
    gpio U_GPIO (
        .ctl   (GPIO_CTL_REG),
        .o_data(GPIO_ODATA_REG),
        .i_data(GPIO_IDATA_REG),
        .gpio  (GPIO)
    );


endmodule

// 실제 양방향 핀 제어를 수행하는 모듈
module gpio (
    input        [15:0] ctl,
    input        [15:0] o_data,
    output logic [15:0] i_data,
    inout  logic [15:0] gpio
);

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            // <방향 설정 핵심 로직>
            // 제어(ctl) 비트가 1이면 출력 모드
            // 내부 출력 데이터(o_data)를 외부 핀(gpio)으로 내보냄
            assign gpio[i] = ctl[i] ? o_data[i] : 1'bz;

            // 제어(ctl) 비트가 0이면 입력 모드
            // 외부 핀(gpio)의 상태를 내부 입력 데이터(i_data)로 읽어옴
            assign i_data  = ~ctl[i] ? gpio[i] : 1'bz;
        end
    endgenerate

endmodule
