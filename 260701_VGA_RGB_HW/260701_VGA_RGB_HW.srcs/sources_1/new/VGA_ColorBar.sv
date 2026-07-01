`timescale 1ns / 1ps

module VGA_ColorBar (
    input  logic       de,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

    always_comb begin
        // 기본 black
        port_red   = 4'h0;
        port_green = 4'h0;
        port_blue  = 4'h0;

        if (de) begin
            if (y_pixel < 320) begin
                // 위
                if (x_pixel < 91) begin
                    // 흰색
                    port_red   = 4'hF;
                    port_green = 4'hF;
                    port_blue  = 4'hF;
                end else if (x_pixel < 182) begin
                    // 노란색
                    port_red   = 4'hF;
                    port_green = 4'hF;
                    port_blue  = 4'h0;
                end else if (x_pixel < 273) begin
                    // 하늘색
                    port_red   = 4'h5;
                    port_green = 4'hC;
                    port_blue  = 4'hF;
                end else if (x_pixel < 364) begin
                    // 연두색
                    port_red   = 4'h8;
                    port_green = 4'hF;
                    port_blue  = 4'h0;
                end else if (x_pixel < 455) begin
                    // 핑크색
                    port_red   = 4'hF;
                    port_green = 4'h0;
                    port_blue  = 4'hF;
                end else if (x_pixel < 546) begin
                    // 빨간색
                    port_red   = 4'hF;
                    port_green = 4'h0;
                    port_blue  = 4'h0;
                end else  begin
                    // 파란색
                    port_red   = 4'h0;
                    port_green = 4'h0;
                    port_blue  = 4'hF;
                end
            end else if (y_pixel < 360) begin
                // 중간
                if (x_pixel < 91) begin
                    // 파란색
                    port_red   = 4'h0;
                    port_green = 4'h0;
                    port_blue  = 4'hF;
                end else if (x_pixel < 182) begin
                    // 검정색
                    port_red   = 4'h0;
                    port_green = 4'h0;
                    port_blue  = 4'h0;
                end else if (x_pixel < 273) begin
                    // 핑크색
                    port_red   = 4'hF;
                    port_green = 4'h0;
                    port_blue  = 4'hF;
                end else if (x_pixel < 364) begin
                    // 검정색
                    port_red   = 4'h0;
                    port_green = 4'h0;
                    port_blue  = 4'h0;
                end else if (x_pixel < 455) begin
                    // 하늘색
                    port_red   = 4'h5;
                    port_green = 4'hC;
                    port_blue  = 4'hF;
                end else if (x_pixel < 546) begin
                    // 검정색
                    port_red   = 4'h0;
                    port_green = 4'h0;
                    port_blue  = 4'h0;
                end else  begin
                    // 흰색
                    port_red   = 4'hF;
                    port_green = 4'hF;
                    port_blue  = 4'hF;
                end
            end else begin
                // 아래
                if (x_pixel < 107) begin
                    // 남색
                    port_red   = 4'h0;
                    port_green = 4'h0;
                    port_blue  = 4'h4;
                end else if (x_pixel < 214) begin
                    // 흰색
                    port_red   = 4'hF;
                    port_green = 4'hF;
                    port_blue  = 4'hF;
                end else if (x_pixel < 321) begin
                    // 보라색
                    port_red   = 4'h4;
                    port_green = 4'h0;
                    port_blue  = 4'h8;
                end else if (x_pixel < 428) begin
                    // 연한 검정
                    port_red   = 4'h1;
                    port_green = 4'h1;
                    port_blue  = 4'h1;
                end else if (x_pixel < 463) begin
                    // 검정색
                    port_red   = 4'h0;
                    port_green = 4'h0;
                    port_blue  = 4'h0;
                end else if (x_pixel < 498) begin
                    // 검정색
                    port_red   = 4'h2;
                    port_green = 4'h2;
                    port_blue  = 4'h2;
                end else if (x_pixel < 534) begin
                    // 검정색
                    port_red   = 4'h3;
                    port_green = 4'h3;
                    port_blue  = 4'h3;
                end else  begin
                    // 검정색
                    port_red   = 4'h0;
                    port_green = 4'h0;
                    port_blue  = 4'h0;
                end
            end
        end
    end

endmodule
