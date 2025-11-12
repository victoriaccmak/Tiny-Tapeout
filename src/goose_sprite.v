`default_nettype none

module goose_sprite (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    output wire [1:0]  R,
    output wire [1:0]  G,
    output wire [1:0]  B,
    output wire        in_goose
);
    // --- PARAMETERS ---
    localparam GOOSE_WIDTH  = 32;   // Adjust based on your image
    localparam GOOSE_HEIGHT = 32;

    // --- MEMORY ARRAYS ---
    reg [7:0] goose_mem [0:GOOSE_WIDTH*GOOSE_HEIGHT-1];
    reg [1:0] palette_r [0:255];
    reg [1:0] palette_g [0:255];
    reg [1:0] palette_b [0:255];

    // --- LOAD HEX FILES ---
    initial begin
        $readmemh("../data_hex/goose.hex", goose_mem);
        $readmemh("../data_hex/palette_r.hex", palette_r);
        $readmemh("../data_hex/palette_g.hex", palette_g);
        $readmemh("../data_hex/palette_b.hex", palette_b);
    end

    // --- POSITION OFFSET (so the goose isn't at top-left corner) ---
    localparam GOOSE_X = 100;
    localparam GOOSE_Y = 80;

    wire [9:0] rel_x = pix_x - GOOSE_X;
    wire [9:0] rel_y = pix_y - GOOSE_Y;
    wire in_bounds = (rel_x < GOOSE_WIDTH) && (rel_y < GOOSE_HEIGHT);

    // --- OUTPUT COLOR ---
    reg [7:0] goose_idx;
    always @(posedge clk) begin
        if (!rst_n)
            goose_idx <= 0;
        else if (in_bounds)
            goose_idx <= goose_mem[rel_y * GOOSE_WIDTH + rel_x];
        else
            goose_idx <= 0;
    end

    assign R = in_bounds ? palette_r[goose_idx] : 2'b00;
    assign G = in_bounds ? palette_g[goose_idx] : 2'b00;
    assign B = in_bounds ? palette_b[goose_idx] : 2'b00;
    assign in_goose = in_bounds;

endmodule
