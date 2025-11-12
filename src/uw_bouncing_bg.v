/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module uw_bouncing_bg(
    // inputs    
    input  wire       clk,      // clock
    input  wire       rst_n,    // reset_n - low to reset
    input reg[9:0] counter,
    input wire video_active,
    input wire [9:0] pix_x,
    input wire [9:0] pix_y,

    // outputs
    output wire [1:0] R,
    output wire [1:0] G,
    output wire [1:0] B
);

    localparam H_VISIBLE = 640;
    localparam V_VISIBLE = 480;

    // Define square position and size
    localparam UW_REC_HEIGHT = 50;
    localparam U_REC_WIDTH = 35;
    localparam W_REC_WIDTH = 50;
    localparam FONT_THICKNESS = 8;
    localparam SCREEN_PADDING = 50;
    
    reg uw_x_dir_right = 1;
    reg uw_y_dir_down = 1;

    reg [5:0] uw_x_pos_reduced;
    reg [5:0] uw_y_pos_reduced;
    
    wire [9:0] uw_right_edge;
    wire [9:0] uw_bot_edge;
    assign uw_right_edge = u_x_pos_actual + (U_REC_WIDTH + W_REC_WIDTH);
    assign uw_bot_edge = uw_y_pos_actual + UW_REC_HEIGHT;
    
    wire [9:0] u_x_pos_actual;
    wire [9:0] w_x_pos_actual;
    wire [9:0] uw_y_pos_actual;

    assign u_x_pos_actual = uw_x_pos_reduced * (H_VISIBLE / 64); // 64 because uw_x_pos_reduced can have values from 0 to 63.
    assign w_x_pos_actual = u_x_pos_actual + U_REC_WIDTH + FONT_THICKNESS;
    assign uw_y_pos_actual = uw_y_pos_reduced * (V_VISIBLE / 64);

    reg bg_colx = 0;
    reg bg_coly = 1;

    wire in_u_rec;
    assign in_u_rec = (pix_x >= u_x_pos_actual) && (pix_x < u_x_pos_actual + U_REC_WIDTH) && 
        (pix_y >= uw_y_pos_actual) && (pix_y < uw_y_pos_actual + UW_REC_HEIGHT);
    
    wire in_w_rec;
    assign in_w_rec = (pix_x >= w_x_pos_actual) && (pix_x < w_x_pos_actual + W_REC_WIDTH) && 
        (pix_y >= uw_y_pos_actual) && (pix_y < uw_y_pos_actual + UW_REC_HEIGHT);

    wire [9:0] u_x = pix_x - u_x_pos_actual;
    wire [9:0] w_x = pix_x - w_x_pos_actual;
    wire [8:0] uw_y = pix_y - uw_y_pos_actual;

    wire inside_U_left_bar   = (u_x < FONT_THICKNESS);
    wire inside_U_right_bar  = (u_x >= U_REC_WIDTH - FONT_THICKNESS);
    wire inside_U_bottom_bar = (uw_y >= UW_REC_HEIGHT - FONT_THICKNESS) && (u_x <= U_REC_WIDTH);
    
    wire inside_W_left_bar   = (w_x < FONT_THICKNESS);
    wire inside_W_mid_bar  = (w_x >= (W_REC_WIDTH - FONT_THICKNESS) / 2) && (w_x <= (W_REC_WIDTH + FONT_THICKNESS) / 2) && (uw_y >= UW_REC_HEIGHT / 2);
    wire inside_W_right_bar  = (w_x >= W_REC_WIDTH - FONT_THICKNESS);
    wire inside_W_bottom_bar = (uw_y >= UW_REC_HEIGHT - FONT_THICKNESS) && (w_x <= W_REC_WIDTH);

    wire inside_U = (inside_U_left_bar || inside_U_right_bar || inside_U_bottom_bar);
    wire inside_W = (inside_W_left_bar || inside_W_mid_bar || inside_W_right_bar || inside_W_bottom_bar);
        
    assign R = video_active ? ((in_u_rec && inside_U) || (in_w_rec && inside_W) ? 2'b11 : {bg_colx, bg_coly}) : 2'b00;
    assign G = video_active ? ((in_u_rec && inside_U) || (in_w_rec && inside_W) ? 2'b10 : {bg_colx, bg_coly}) : 2'b00;
    assign B = video_active ? ((in_u_rec && inside_U) || (in_w_rec && inside_W) ? 2'b11 : {bg_colx, bg_coly}) : 2'b00;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            uw_x_pos_reduced <= SCREEN_PADDING;
            uw_y_pos_reduced <= SCREEN_PADDING;
            uw_x_dir_right <= 1'b1;
            uw_y_dir_down    <= 1'b1;
        end else begin

            if (counter & 1 == 1) begin
                // Move horizontally
                if (uw_x_dir_right) begin
                    uw_x_pos_reduced <= uw_x_pos_reduced + 1;
                end else begin
                    uw_x_pos_reduced <= uw_x_pos_reduced - 1;
                end

                // Move vertically
                if (uw_y_dir_down) begin
                    uw_y_pos_reduced <= uw_y_pos_reduced + 1;
                end else begin
                    uw_y_pos_reduced <= uw_y_pos_reduced - 1;
                end

                // Bounce off edges
                if (uw_right_edge >= H_VISIBLE - SCREEN_PADDING) begin
                    bg_colx <= 1;
                    uw_x_dir_right <= 1'b0; // move left
                end else if (u_x_pos_actual <= SCREEN_PADDING) begin
                    bg_colx <= 1;
                    uw_x_dir_right <= 1'b1; // move right
                end else begin
                    bg_colx <= 0;
                end

                if (uw_bot_edge >= V_VISIBLE - SCREEN_PADDING) begin
                    uw_y_dir_down <= 1'b0;    // move up
                end else if (uw_y_pos_actual <= SCREEN_PADDING) begin
                    uw_y_dir_down <= 1'b1;    // move down
                end
            end
        end
    end
  
endmodule