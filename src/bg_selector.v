
// Note: This module is not in use


// `default_nettype none

// module bg_selector(
//     // inputs
//     input  wire [1:0] bg_num,
//     input  wire       clk,      // clock
//     input  wire       rst_n,    // active-low reset

//     // outputs
//     output reg bg1_en,
//     output reg bg2_en,
//     output reg bg3_en,
//     output reg bg4_en
// );

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             // reset: all outputs off
//             bg1_en <= 1'b0;
//             bg2_en <= 1'b0;
//             bg3_en <= 1'b0;
//             bg4_en <= 1'b0;
//         end else begin
//             // default: all off
//             bg1_en <= 1'b0;
//             bg2_en <= 1'b0;
//             bg3_en <= 1'b0;
//             bg4_en <= 1'b0;

//             // enable selected background
//             case (bg_num)
//                 2'b00: bg1_en <= 1'b1;
//                 2'b01: bg2_en <= 1'b1;
//                 2'b10: bg3_en <= 1'b1;
//                 2'b11: bg4_en <= 1'b1;
//             endcase
//         end
//     end

// endmodule
