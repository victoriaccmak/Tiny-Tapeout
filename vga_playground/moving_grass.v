/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

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

// Define grass properties
localparam GRASS_REC_HEIGHT_1 = 80;
localparam GRASS_REC_HEIGHT_2 = 60;
localparam GRASS_REC_HEIGHT_3 = 65;
localparam GRASS_REC_HEIGHT_4 = 30;
localparam GRASS_REC_HEIGHT_5 = 50;
localparam GRASS_REC_WIDTH_1 = 50;
localparam GRASS_REC_WIDTH_2 = 40;
localparam GRASS_REC_WIDTH_3 = 45;
localparam GRASS_REC_WIDTH_4 = 20;
localparam GRASS_REC_WIDTH_5 = 1;
localparam GRASS_BASE_THICKNESS_1 = 10;
localparam GRASS_BASE_THICKNESS_2 = 7;
localparam GRASS_BASE_THICKNESS_3 = 8;
localparam GRASS_BASE_THICKNESS_4 = 4;
localparam GRASS_SPACING_5 = 15;

// Motion control
reg grass_dir = 1;
reg [5:0] grass_mvmt;

// Local coordinates for each "grass cell"
wire [9:0] local_x_1 = pix_x % GRASS_REC_WIDTH_1 - grass_mvmt;
wire [9:0] local_x_2 = (pix_x + 30) % GRASS_REC_WIDTH_2;
wire [9:0] local_x_3 = (pix_x + 15) % GRASS_REC_WIDTH_3 - grass_mvmt;
wire [9:0] local_x_4 = (pix_x) % GRASS_REC_WIDTH_4;
wire [9:0] local_x_5 = (pix_x) % GRASS_SPACING_5;
wire [9:0] local_y_1 = pix_y - (V_VISIBLE / 2 - GRASS_REC_HEIGHT_1);
wire [9:0] local_y_2 = pix_y - (V_VISIBLE / 2 - GRASS_REC_HEIGHT_2);
wire [9:0] local_y_3 = pix_y - (V_VISIBLE / 2 - GRASS_REC_HEIGHT_3);
wire [9:0] local_y_4 = pix_y - (V_VISIBLE / 2 - GRASS_REC_HEIGHT_4);
wire [9:0] local_y_5 = pix_y - (V_VISIBLE / 2 - GRASS_REC_HEIGHT_5);

wire [5:0] blade_mvmt_1 = (grass_mvmt) % GRASS_REC_WIDTH_1;
wire [5:0] blade_mvmt_2 = (grass_mvmt) % GRASS_REC_WIDTH_2;
wire [5:0] blade_mvmt_3 = (grass_mvmt) % GRASS_REC_WIDTH_3;

// Define curved grass shape (using quadratic approximation)
wire inside_grass_shape_1 = (local_y_1) >= 
                            (GRASS_REC_HEIGHT_1 * local_x_1 * local_x_1 / (GRASS_REC_WIDTH_1 - blade_mvmt_1) / (GRASS_REC_WIDTH_1 - blade_mvmt_1)) &&
                            (local_y_1) <= 
                            (GRASS_REC_HEIGHT_1 * local_x_1 * local_x_1 / (GRASS_REC_WIDTH_1 - GRASS_BASE_THICKNESS_1 - blade_mvmt_1) / (GRASS_REC_WIDTH_1 - GRASS_BASE_THICKNESS_1 - blade_mvmt_1)) &&
                            (pix_y >= V_VISIBLE / 2 - GRASS_REC_HEIGHT_1);
wire inside_grass_shape_2 = (local_y_2) >= 
                            (GRASS_REC_HEIGHT_2 * (local_x_2 - (GRASS_REC_WIDTH_2 - blade_mvmt_2)) * (local_x_2 - (GRASS_REC_WIDTH_2 - blade_mvmt_2)) / (GRASS_REC_WIDTH_2 - blade_mvmt_2) / (GRASS_REC_WIDTH_2 - blade_mvmt_2)) &&
                            (local_y_2) <= 
                            (GRASS_REC_HEIGHT_2 * (local_x_2 - (GRASS_REC_WIDTH_2 - blade_mvmt_2)) * (local_x_2 - (GRASS_REC_WIDTH_2 - blade_mvmt_2)) / (GRASS_REC_WIDTH_2 - GRASS_BASE_THICKNESS_2 - blade_mvmt_2) / (GRASS_REC_WIDTH_2 - GRASS_BASE_THICKNESS_2 - blade_mvmt_2)) &&
                            (local_x_2) <=
                            GRASS_REC_WIDTH_2 - blade_mvmt_2 &&
                            (pix_y >= V_VISIBLE / 2 - GRASS_REC_HEIGHT_2);
wire inside_grass_shape_3 = (local_y_3) >= 
                            (GRASS_REC_HEIGHT_3 * local_x_3 * local_x_3 / (GRASS_REC_WIDTH_3 - blade_mvmt_3) / (GRASS_REC_WIDTH_3 - blade_mvmt_3)) &&
                            (local_y_3) <= 
                            (GRASS_REC_HEIGHT_3 * local_x_3 * local_x_3 / (GRASS_REC_WIDTH_3 - GRASS_BASE_THICKNESS_3 - blade_mvmt_3) / (GRASS_REC_WIDTH_3 - GRASS_BASE_THICKNESS_3 - blade_mvmt_3)) &&
                            (pix_y >= V_VISIBLE / 2 - GRASS_REC_HEIGHT_3);
wire inside_grass_shape_4 = (local_y_4) >= 
                            (GRASS_REC_HEIGHT_4 * (local_x_4 - GRASS_REC_WIDTH_4) * (local_x_4 - GRASS_REC_WIDTH_4) / GRASS_REC_WIDTH_4 / GRASS_REC_WIDTH_4) &&
                            (local_y_4) <= 
                            (GRASS_REC_HEIGHT_4 * (local_x_4 - GRASS_REC_WIDTH_4) * (local_x_4 - GRASS_REC_WIDTH_4) / (GRASS_REC_WIDTH_4 - GRASS_BASE_THICKNESS_4) / (GRASS_REC_WIDTH_4 - GRASS_BASE_THICKNESS_4)) &&
                            (local_x_4) <=
                            GRASS_REC_WIDTH_4 &&
                            (pix_y >= V_VISIBLE / 2 - GRASS_REC_HEIGHT_4);
wire inside_grass_shape_5 = (local_y_5) >= 0 && (local_y_5) <= GRASS_REC_HEIGHT_5 &&
                            (local_x_5) <=
                            GRASS_REC_WIDTH_5;

// Draw the base layer of grass (flat bottom)
wire in_grass_base = (pix_y >= V_VISIBLE / 2);

// Combine all grass regions
// wire in_all_grass = (inside_grass_shape_5) || in_grass_base;
wire in_all_grass = (inside_grass_shape_1 || inside_grass_shape_2 || inside_grass_shape_3 || inside_grass_shape_4 || inside_grass_shape_5) || in_grass_base;

// Output colors
assign R = video_active ? (in_all_grass ? 2'b00 : 2'b00) : 2'b00;
assign G = video_active ? (in_all_grass ? 2'b11 : 2'b10) : 2'b00;
assign B = video_active ? (in_all_grass ? 2'b00 : 2'b11) : 2'b00;

  
// Animate movement (back and forth)
always @(posedge vsync or negedge rst_n) begin
  if (~rst_n) begin
    counter <= 0;
    grass_mvmt <= 1;
    grass_dir <= 1;
  end else begin
    counter <= counter + 1;

    if (grass_mvmt > GRASS_REC_WIDTH_1 - GRASS_BASE_THICKNESS_1 - 9) begin
      grass_dir <= 0;
    end else if (grass_mvmt < 2) begin
      grass_dir <= 1;
    end

    if (grass_dir) begin
      grass_mvmt <= grass_mvmt + 1;
    end else begin
      grass_mvmt <= grass_mvmt - 1;
    end
  end
end      
  
endmodule
