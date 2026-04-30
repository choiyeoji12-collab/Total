`timescale 1ns / 1ps

// 주소 판독기
module Address_Decoder (
    input               en,     // 디코더 동작 활성화 신호 (마스터의 지시에만)
    input        [31:0] addr,   
    
    output logic        psel0,  // RAM
    output logic        psel1,  // GPO
    output logic        psel2,  // GPI
    output logic        psel3,  // GPIO
    output logic        psel4,  // FND
    output logic        psel5   // UART
);

    always_comb begin
        psel0 = 1'b0;  // idle : 0
        psel1 = 1'b0;  // idle : 0
        psel2 = 1'b0;  // idle : 0
        psel3 = 1'b0;  // idle : 0
        psel4 = 1'b0;  // idle : 0
        psel5 = 1'b0;  // idle : 0

        // 디코더가 활성화(en=1)일 때만 주소 해독
        if (en) begin
            // 주소의 최상위 4자리 확인
            case (addr[31:28])  // instead of casex
                // 앞자리가 1 -> 메모리(RAM) 
                4'h1: psel0 = 1'b1;
                // 앞자리가 2 -> 주변장치(I/O)
                4'h2: begin
                    case (addr[15:12])
                    // I/O 영역 안에서 세부 주소 (15~12번 비트) 확인
                        4'h0: psel1 = 1'b1;     // 0x2000_0000 -> GPO
                        4'h1: psel2 = 1'b1;     // 0x2000_1000 -> GPI
                        4'h2: psel3 = 1'b1;     // 0x2000_2000 -> GPIO
                        4'h3: psel4 = 1'b1;     // 0x2000_3000 -> FND
                        4'h4: psel5 = 1'b1;     // 0x2000_4000 -> UART
                    endcase
                end
            endcase
        end
    end

endmodule


//
//    logic [3:0] addr_top;
//    logic [3:0] addr_io;
//    logic [5:0] decoded_psel;
//
//    assign addr_top = addr[31:28];
//    assign addr_io  = addr[15:12];
//
//    always_comb begin
//        decoded_psel = 6'b0;
//        case (addr_top)
//            4'h1: begin
//                decoded_psel[0] = 1'b1;  // RAM
//            end
//            4'h2: begin
//                case (addr_io)
//                    4'h0: decoded_psel[1] = 1'b1;  // GPO
//                    4'h1: decoded_psel[2] = 1'b1;  // GPI
//                    4'h2: decoded_psel[3] = 1'b1;  // GPIO
//                    4'h3: decoded_psel[4] = 1'b1;  // FND
//                    4'h4: decoded_psel[5] = 1'b1;  // UART
//                endcase
//            end
//        endcase
//    end
//
//   always_comb begin
//       n_state = c_state;
//       Psel    = 6'b0;
//       Penable = 1'b0;
//       ready   = 1'b0;
//       case (c_state)
//           IDLE: begin
//               if (Rreq | Wreq) begin
//                   n_state = SETUP;
//               end
//           end
//           SETUP: begin
//               Psel    = decoded_psel;
//               Penable = 1'b0;
//               n_state = ACCESS;
//           end
//           ACCESS: begin
//               Psel    = decoded_psel;
//               Penable = 1'b1;
//               if (Pready) begin
//                   ready = 1'b1;
//                   if (Rreq | Wreq) begin
//                       n_state = SETUP;
//                   end else begin
//                       n_state = IDLE;
//                   end
//               end else begin
//                   n_state = ACCESS;
//               end
//           end
//       endcase
//   end
//
//endmodule
