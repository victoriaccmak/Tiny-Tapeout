/*
 * Music from "Drop" demo.
 * Full version: https://github.com/rejunity/tt08-vga-drop
 *
 * Copyright (c) 2024 Renaldas Zioma, Erik Hemming
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`define MUSIC_SPEED   4'd1;  // for 60 FPS
// `define MUSIC_SPEED   2'd2;  // for 30 FPS

// `define C5  30; // 523.26 Hz 
`define Cs5 28; // 554.36 Hz 
// `define D5  27; // 587.32 Hz 
`define Ds5 25; // 622.26 Hz 
`define E5  24; // 659.26 Hz 
// `define F5  23; // 698.46 Hz 
// `define Fs5 21; // 739.98 Hz 
// `define G5  20; // 784.0 Hz 
// `define Gs5 19; // 830.6 Hz 
// `define A5  18; // 880.0 Hz 
// `define As5 17; // 932.32 Hz 
// `define B5  16; // 987.76 Hz 

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] x;
  wire [9:0] y;
  wire sound;

  // TinyVGA PMOD
  assign R = video_active ? (x == frame_counter) ? 2'b11 : 2'b00 : 2'b00;
  assign G = video_active ? (x == frame_counter) ? 2'b11 : 2'b00 : 2'b00;
  assign B = video_active ? (x == frame_counter) ? 2'b11 : 2'b00 : 2'b00;

  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = {sound, 7'b0};

  // Unused outputs assigned to 0.
  assign uio_oe  = 8'hff;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
  );

  wire [12:0] timer = frame_counter;
  reg part1;

  wire [4:0] envelopeB = 5'd31 - timer[1:0]*8;// exp(t*-20) decays to 0 approximately in 16 frames  [255 181 129  92  65  46  33  23  16  12   8   6   4   3]

  // lead wave counter
  reg [7:0] note_freq;
  reg [7:0] note_counter;
  reg       note;

  // lead notes
  wire [3:0] note_in = timer[5:2];           // 16 notes, 4 frames per note each. 64 frames total, ~2 seconds
  always @(note_in)
  case(note_in)
      4'd0 : note_freq = `Ds5
      4'd1 : note_freq = 1'b0;
      4'd2 : note_freq = `Ds5
      4'd3 : note_freq = `Ds5
      4'd4 : note_freq = `E5
      4'd5 : note_freq = 1'b0;
      4'd6 : note_freq = `Ds5
      4'd7 : note_freq = `Cs5
      4'd8 : note_freq = `Ds5
      4'd9 : note_freq = `Ds5
      4'd10 : note_freq = `Ds5
      4'd11 : note_freq = `Ds5
      4'd12: note_freq = `E5
      4'd13 : note_freq = 1'b0;
      4'd14: note_freq = `Ds5
      4'd15: note_freq = `Cs5
  endcase

  wire lead   = note       & (x >= 256 && x < 256+envelopeB*8);   // ROM square wave with quarter second envelope

  assign sound = { lead && part1 };

  reg [11:0] frame_counter;

  always @(posedge clk) begin
    if (~rst_n) begin
      frame_counter <= 0;
      note_counter <= 0;
      note <= 0;
      part1 <= 1;

    end else begin

      part1 <= timer[6];

      if (x == 0 && y == 0) begin
        frame_counter <= frame_counter + `MUSIC_SPEED;
      end

      // square wave
      if (x == 0) begin
        if (note_counter > note_freq && note_freq != 0) begin
          note_counter <= 0;
          note <= ~note;
        end else begin
          note_counter <= note_counter + 1'b1;
        end
      end
    end
  end

endmodule
