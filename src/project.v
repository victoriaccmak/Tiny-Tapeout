/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_oiia_goose (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  wire sound;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [9:0] counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  wire [9:0] moving_x = pix_x + counter;

  localparam H_VISIBLE = 640;
  localparam V_VISIBLE = 480;

  // Define square position and size
  localparam UW_REC_HEIGHT = 50;
  localparam U_LEN = 35;
  localparam W_LEN = 50;
  localparam FONT_THICKNESS = 8;
  localparam SCREEN_PADDING = 50;
  
  reg uw_x_dir_right = 1;
  reg uw_y_dir_down = 1;

  reg [5:0] uw_x_pos;
  reg [5:0] uw_y_pos;
  
  wire [9:0] uw_right_edge;
  wire [9:0] uw_bot_edge;
  assign uw_right_edge = u_rec_x + (U_LEN + W_LEN);
  assign uw_bot_edge = uw_rec_y + UW_REC_HEIGHT;
  
  wire [10:0] u_rec_x;
  wire [10:0] w_rec_x;
  wire [10:0] uw_rec_y;

  assign u_rec_x = uw_x_pos * (H_VISIBLE / 64);
  assign w_rec_x = u_rec_x + U_LEN + FONT_THICKNESS;
  assign uw_rec_y = uw_y_pos * (V_VISIBLE / 64);

  reg bg_colx = 0;
  reg bg_coly = 1;

  wire in_u_rec;
  assign in_u_rec = (pix_x >= u_rec_x) && (pix_x < u_rec_x + U_LEN) && 
    (pix_y >= uw_rec_y) && (pix_y < uw_rec_y + UW_REC_HEIGHT);
  
  wire in_w_rec;
  assign in_w_rec = (pix_x >= w_rec_x) && (pix_x < w_rec_x + W_LEN) && 
    (pix_y >= uw_rec_y) && (pix_y < uw_rec_y + UW_REC_HEIGHT);

  wire [9:0] u_x = pix_x - u_rec_x;
  wire [9:0] w_x = pix_x - w_rec_x;
  wire [8:0] uw_y = pix_y - uw_rec_y;

  wire inside_U_left_bar   = (u_x < FONT_THICKNESS);
  wire inside_U_right_bar  = (u_x >= U_LEN - FONT_THICKNESS);
  wire inside_U_bottom_bar = (uw_y >= UW_REC_HEIGHT - FONT_THICKNESS) && (u_x <= U_LEN);
  
  wire inside_W_left_bar   = (w_x < FONT_THICKNESS);
  wire inside_W_mid_bar  = (w_x >= (W_LEN - FONT_THICKNESS) / 2) && (w_x <= (W_LEN + FONT_THICKNESS) / 2) && (uw_y >= UW_REC_HEIGHT / 2);
  wire inside_W_right_bar  = (w_x >= W_LEN - FONT_THICKNESS);
  wire inside_W_bottom_bar = (uw_y >= UW_REC_HEIGHT - FONT_THICKNESS) && (w_x <= W_LEN);

  wire inside_U = (inside_U_left_bar || inside_U_right_bar || inside_U_bottom_bar);
  wire inside_W = (inside_W_left_bar || inside_W_mid_bar || inside_W_right_bar || inside_W_bottom_bar);
    
  assign R = video_active ? ((in_u_rec && inside_U) || (in_w_rec && inside_W) ? 2'b11 : {bg_colx, bg_coly}) : 2'b00;
  assign G = video_active ? ((in_u_rec && inside_U) || (in_w_rec && inside_W) ? 2'b10 : {bg_colx, bg_coly}) : 2'b00;
  assign B = video_active ? ((in_u_rec && inside_U) || (in_w_rec && inside_W) ? 2'b11 : {bg_colx, bg_coly}) : 2'b00;

always @(posedge vsync or negedge rst_n) begin
  if (~rst_n) begin
    counter <= 0;
    uw_x_pos <= SCREEN_PADDING;
    uw_y_pos <= SCREEN_PADDING;
    uw_x_dir_right <= 1'b1;
    uw_y_dir_down  <= 1'b1;
  end else begin
    counter <= counter + 1;

    if (counter & 1 == 1) begin
      // Move horizontally
      if (uw_x_dir_right) begin
        uw_x_pos <= uw_x_pos + 1;
      end else begin
        uw_x_pos <= uw_x_pos - 1;
      end

      // Move vertically
      if (uw_y_dir_down) begin
        uw_y_pos <= uw_y_pos + 1;
      end else begin
        uw_y_pos <= uw_y_pos - 1;
      end

      // Bounce off edges
      if (uw_right_edge >= H_VISIBLE - SCREEN_PADDING) begin
        bg_colx <= 1;
        uw_x_dir_right <= 1'b0; // move left
      end else if (u_rec_x <= SCREEN_PADDING) begin
        bg_colx <= 1;
        uw_x_dir_right <= 1'b1; // move right
      end else begin
        bg_colx <= 0;
      end

      if (uw_bot_edge >= V_VISIBLE - SCREEN_PADDING) begin
        uw_y_dir_down <= 1'b0;  // move up
      end else if (uw_rec_y <= SCREEN_PADDING) begin
        uw_y_dir_down <= 1'b1;  // move down
      end
    end
  end
end
  
endmodule
