/*
 * Copyright (c) 2024 Angelo Nujic
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module morse_seven_seg(
  input wire clk,
  input wire rst_n,
  input wire start_i,
  output reg [6:0] seg_o,
  output reg [4:0] letter_o,
  output reg ready_o
);
reg [4:0] counter_q, counter_d;
reg ready_q, ready_d;
reg [6:0] seg_d, seg_q;
assign counter_d = ~ready_q ? counter_q + 1 : counter_q;
assign ready_d = start_i;
assign letter_o = ready_q ? counter_q : 'b1;
assign seg_o = seg_q;
assign ready_o = ready_q;

always @(*) begin
  seg_d = 'b0; // All segments off by default
  if (ready_q) begin
    case (counter_q)
      0: seg_d = 7'b1011111; // A
      1: seg_d = 7'b1111100; // B
      2: seg_d = 7'b1011000; // C
      3: seg_d = 7'b1011110; // D
      4: seg_d = 7'b1111001; // E
      5: seg_d = 7'b1110001; // F
      6: seg_d = 7'b0111101; // G
      7: seg_d = 7'b1110110; // H
      8: seg_d = 7'b0010001; // I
      9: seg_d = 7'b0001101; // J
      10: seg_d = 7'b1110101; // K
      11: seg_d = 7'b0111000; // L
      12: seg_d = 7'b1010101; // M
      13: seg_d = 7'b1010100; // N
      14: seg_d = 7'b1011100; // O
      15: seg_d = 7'b1110011; // P
      16: seg_d = 7'b1100111; // Q
      17: seg_d = 7'b1010000; // R
      18: seg_d = 7'b1101101; // S
      19: seg_d = 7'b1111000; // T
      20: seg_d = 7'b0011100; // U
      21: seg_d = 7'b0101010; // V
      22: seg_d = 7'b1101010; // W
      23: seg_d = 7'b0110110; // X
      24: seg_d = 7'b1101110; // Y
      25: seg_d = 7'b1011011; // Z
      default: seg_d = 'b0; // All segments off for undefined letters
    endcase
  end
  
end

always @(posedge clk) begin
  if (!rst_n) begin
    counter_q <= 5'b00000;
    ready_q <= 1'b0;
    seg_q     <= 'b0;
  end else begin
    counter_q <= counter_d;
    ready_q <= ready_d;
    seg_q     <=     seg_d;
  end
end
  
endmodule