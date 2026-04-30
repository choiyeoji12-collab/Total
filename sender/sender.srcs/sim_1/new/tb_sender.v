`timescale 1ns / 1ps

module tb_sender;

    reg clk, rst;
    reg ascii_s;
    reg mode_sel;
    reg [23:0] pc_uart;

    reg  tx_busy;
    reg  tx_done;
    wire tx_start;
    wire [7:0] tx_data;

    // DUT
    ascii_sender dut (
        .clk     (clk),
        .rst     (rst),
        .ascii_s (ascii_s),
        .mode_sel(mode_sel),
        .pc_uart (pc_uart),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        .tx_start(tx_start),
        .tx_data (tx_data)
    );

    // 100MHz clock
    always #5 clk = ~clk;

    // --------------------------
    // Fake UART model:
    //  - tx_start가 오면 busy=1로 만들고
    //  - 일정 클럭 후 done 펄스 1번 발생
    // --------------------------
    integer busy_cnt;
    localparam integer BUSY_CYCLES = 80; // 글자 1개당 바쁜 시간(발표용으로 적당히)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_busy  <= 1'b0;
            tx_done  <= 1'b0;
            busy_cnt <= 0;
        end else begin
            tx_done <= 1'b0; // 기본값

            // tx_start가 뜨면 "전송 시작"으로 보고 busy 걸기
            if (tx_start && !tx_busy) begin
                tx_busy  <= 1'b1;
                busy_cnt <= BUSY_CYCLES;
            end

            // busy 유지 후 done 발생
            if (tx_busy) begin
                if (busy_cnt == 0) begin
                    tx_busy <= 1'b0;
                    tx_done <= 1'b1; // 1클럭 펄스
                end else begin
                    busy_cnt <= busy_cnt - 1;
                end
            end
        end
    end

    // 콘솔에 보낸 문자 출력(발표용 증거)
    always @(posedge clk) begin
        if (tx_start && !tx_busy) begin
            $write("%c", tx_data);
        end
    end

    task pulse_ascii_s;
        begin
            ascii_s = 1'b1;
            @(posedge clk);
            ascii_s = 1'b0;
        end
    endtask

    initial begin
        clk      = 1'b0;
        rst      = 1'b1;
        ascii_s  = 1'b0;
        mode_sel = 1'b0;
        pc_uart  = 24'd0;

        repeat(5) @(posedge clk);
        rst = 1'b0;

        // 1) Stopwatch 예시: S 01:23:45.67
        mode_sel = 1'b0;
        pc_uart  = {5'd1, 6'd23, 6'd45, 7'd67};
        pulse_ascii_s();

        // sender가 IDLE로 돌아올 시간 확보
        #200_000;

        // 2) Watch 예시: W 12:34:56.78
        mode_sel = 1'b1;
        pc_uart  = {5'd12, 6'd34, 6'd56, 7'd78};
        pulse_ascii_s();

        #300_000;
        $stop;
    end

endmodule