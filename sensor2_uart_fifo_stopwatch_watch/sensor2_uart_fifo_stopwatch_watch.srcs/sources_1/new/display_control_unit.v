`timescale 1ns / 1ps
module display_control_unit (
    input        clk,
    input        rst,
    input  [3:0] sw,
    input        btn_u,
    input        btn_d,
    output reg   show_sensor,
    output reg [1:0] sensor_page
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            show_sensor <= 1'b0;
            sensor_page <= 2'd0;   // 0=dist
        end else begin
            show_sensor <= sw[3];

            if (sw[3]) begin
                if (btn_u) begin
                    if (sensor_page == 2'd2) sensor_page <= 2'd0;
                    else sensor_page <= sensor_page + 1;
                end else if (btn_d) begin
                    if (sensor_page == 2'd0) sensor_page <= 2'd2;
                    else sensor_page <= sensor_page - 1;
                end
            end else begin
                sensor_page <= 2'd0;
            end
        end
    end
endmodule