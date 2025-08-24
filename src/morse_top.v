/*
 * Copyright (c) 2024 Angelo Nujic
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_anujic (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Morse timing parameters (for 100Hz clock)
  localparam DOT_TIME     = 6'd20;  // ~200ms for dot
  localparam DASH_TIME    = 6'd60;  // ~600ms for dash  
  //localparam GAP_TIME     = 6'd10;  // ~100ms gap between dots/dashes
  localparam CHAR_TIME    = 6'd40;  // ~400ms to complete character input

  // FSM States
  localparam IDLE         = 2'b00;
  //localparam DISP         = 2'b01;
  localparam PROC_INPUT   = 2'b10;
  localparam RES          = 2'b11;

  wire start;
  wire morse;
  //wire next;
  reg correct_res;
  reg [3:0] input_morse_q, input_morse_d;
  reg [6:0] correct_morse;
  //reg [3:0] code;
  //reg [2:0] len;  // Changed from [1:0] to [2:0] to match usage
  reg [4:0] letter;
  reg display_ready;
  //reg [1:0] count_len_q, count_len_d;
  //reg [5:0] count_time_q, count_time_d;
  reg [1:0] state_q, state_d;
  // Additional signals for Morse input detection
  reg [5:0] timer_q, timer_d;          // Timer for measuring durations
  reg prev_morse_q, prev_morse_d;      // Previous morse input state
  reg [2:0] bit_count_q, bit_count_d;  // Track how many dots/dashes received
  reg input_valid;                     // Signal when input is complete

  assign start = ui_in[0];
  assign morse = ui_in[1];
  assign uo_out[7] = correct_res;
  assign uio_out = 8'b0;  // Added missing assignment
  assign uio_oe = 8'b0;   // Added missing assignment

  // 7 segment display with randomly selected letter
  morse_seven_seg seven_seg_i (
    .clk    (clk),
    .rst_n   (rst_n),
    .start_i  (start),
    .seg_o    (uo_out[6:0]),
    .letter_o (letter),
    .ready_o  (display_ready)
  );

  always @(*) begin
    correct_morse = 7'h7F;
    if(start && display_ready) begin
      case (letter)
        6'd0: correct_morse = {3'd2, 4'b10}; // A: .-
        6'd1: correct_morse = {3'd4, 4'b1000}; // B: -...
        6'd2: correct_morse = {3'd4, 4'b1010}; // C: -.-.
        6'd3: correct_morse = {3'd3, 4'b100}; // D: -..
        6'd4: correct_morse = {3'd1, 4'b0}; // E: .
        6'd5: correct_morse = {3'd4, 4'b0010}; // F: ..-.
        6'd6: correct_morse = {3'd3, 4'b110}; // G: --.
        6'd7: correct_morse = {3'd4, 4'b0000}; // H: ....
        6'd8: correct_morse = {3'd2, 4'b00}; // I: ..
        6'd9: correct_morse = {3'd4, 4'b0111}; // J: .---
        6'd10: correct_morse = {3'd3, 4'b101}; // K: -.-
        6'd11: correct_morse = {3'd4, 4'b0100}; // L: .-..
        6'd12: correct_morse = {3'd2, 4'b11}; // M: --
        6'd13: correct_morse = {3'd2, 4'b10}; // N: -.
        6'd14: correct_morse = {3'd3, 4'b111}; // O: ---
        6'd15: correct_morse = {3'd4, 4'b0110}; // P: .--.
        6'd16: correct_morse = {3'd4, 4'b1101}; // Q: --.-
        6'd17: correct_morse = {3'd3, 4'b010}; // R: .-.
        6'd18: correct_morse = {3'd3, 4'b000}; // S: ...
        6'd19: correct_morse = {3'd1, 4'b1}; // T: -
        6'd20: correct_morse = {3'd3, 4'b001}; // U: ..-
        6'd21: correct_morse = {3'd4, 4'b0001}; // V: ...-
        6'd22: correct_morse = {3'd3, 4'b011}; // W: .--
        6'd23: correct_morse = {3'd4, 4'b1001}; // X: -..-
        6'd24: correct_morse = {3'd4, 4'b1011}; // Y: -.--
        6'd25: correct_morse = {3'd4, 4'b1100}; // Z: --..
        default: correct_morse = 7'h7F; // Default to avoid latches
      endcase
    end
  end

// Combinational logic
always @(*) begin
  // Default values to prevent latches
  input_morse_d = input_morse_q;
  timer_d = timer_q;
  prev_morse_d = morse;
  bit_count_d = bit_count_q;
  input_valid = 1'b0;
  correct_res = 1'b0;
  state_d = state_q;  // Added missing default assignment
  
  case (state_q)
    2'b01, IDLE: begin
      // Reset input related signals when going to IDLE
      input_morse_d = 4'b0;
      timer_d = 6'b0;
      bit_count_d = 3'b0;
      if(start && display_ready) begin
        state_d = PROC_INPUT;
      end
    end
    
    PROC_INPUT: begin
      if (!start) begin
        state_d = IDLE;
        input_morse_d = 4'b0;
        bit_count_d = 3'b0;
      end else begin
        // Rising edge of morse signal - start timing
        if (morse && !prev_morse_q) begin
          timer_d = 6'b0;
        end
        // Falling edge - interpret the signal
        if (!morse && prev_morse_q) begin
          // Check if it's a dot or dash based on duration
          if (timer_q >= DASH_TIME) begin
            // It's a dash (1)
            input_morse_d = (input_morse_q << 1) | 4'b0001;
            bit_count_d = bit_count_q + 1'b1;
          end else if (timer_q >= DOT_TIME) begin
            // It's a dot (0)
            input_morse_d = (input_morse_q << 1);  // Fixed: don't OR with 1 for dot
            bit_count_d = bit_count_q + 1'b1;
          end
          timer_d = 6'b0;
        end
        // If morse is high, increment timer to measure duration
        if (morse) begin
          if (timer_q < 6'b111111) begin
            timer_d = timer_q + 1'b1;
          end else begin // timeout
            state_d = IDLE;
          end
        end
        // If morse is low (gap), increment timer to detect character completion
        else begin
          if (timer_q < 6'b111111) timer_d = timer_q + 1'b1;
          // Character complete if gap is long enough
          if (timer_q >= CHAR_TIME) begin
            input_valid = 1'b1;
            state_d = RES;  // Move to result state when input is complete
          end
        end
        
        // Safety check - if we get too many bits, consider input complete
        if (bit_count_q >= 4) begin
          input_valid = 1'b0;
          state_d = RES;
        end
      end
    end
    
    RES: begin
      // In RES state, prepare for next input or return to IDLE
      if (!start) begin
        state_d = IDLE;
        input_morse_d = 4'b0;
        bit_count_d = 3'b0;
      end 
      if (({bit_count_q, input_morse_q} == correct_morse) && input_valid) begin // correct result
        correct_res = 1'b1;
      end
    end
  endcase
end

// Sequential logic update
always @(posedge clk) begin
  if (!rst_n) begin
    input_morse_q <= '0;
    timer_q <= '0;
    prev_morse_q <= 1'b0;
    bit_count_q <= 3'b0;
    state_q <= IDLE;
  end else begin
    input_morse_q <= input_morse_d;
    timer_q <= timer_d;
    prev_morse_q <= prev_morse_d;
    bit_count_q <= bit_count_d;
    state_q <= state_d;
  end
end

// List all unused inputs to prevent warnings
wire _unused = &{ena, uio_in, ui_in[7:2], 1'b0};

endmodule