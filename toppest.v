`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/15/2019 01:23:28 PM
// Design Name: 
// Module Name: toppest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module toppest(
    input wire CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire RST_BTN,         // reset button
    input wire [3:0] sw,        // four switches, [0] right [1] left [2] down [3] up
    output wire VGA_HS_O,       // horizontal sync output
    output wire VGA_VS_O,       // vertical sync output
    output wire [3:0] VGA_R,     // 4-bit VGA red output
    output wire [3:0] VGA_G,     // 4-bit VGA green output
    output wire [3:0] VGA_B,     // 4-bit VGA blue output
    output wire [15:0] LED       // 16 led for debug
    );
    
    reg LEDs [15:0];
    
//    localparam one_second = 25'b101111010111100001000000;
    localparam one_second = 25'b10111101011110000100000;
    // generate a 25 MHz pixel strobe and an 1Hz impulse
    reg [15:0] cnt;
    reg [24:0] count;
    reg G_move_clk;
    reg pix_stb;
    always @(posedge CLK)
    begin
        {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000
        count <= count + 1;
        if (count == one_second)
        begin
            G_move_clk <= 1;
        end
        else 
        begin
            G_move_clk <= 0;
        end
        if (G_move_clk)
        LEDs [0] <= ~LEDs [0];
    end

        
    wire [3:0] head_pos_x;
    wire [3:0] head_pos_y;
    wire [3:0] tail_pos_x;
    wire [3:0] tail_pos_y;
    wire [3:0] apple_pos_x;
    wire [3:0] apple_pos_y;
    wire [1:0] state;    
    
    // map memory
    localparam G_MAP_WIDTH = 14;
    localparam G_MAP_HEIGHT = 14;
    localparam G_MAP_DEPTH = G_MAP_WIDTH * G_MAP_HEIGHT;
    localparam G_MAP_A_WIDTH = 8; // 2 ^ 5 > 5 x 5
    localparam G_MAP_D_WIDTH = 2;
    // 00 lime green 01 glass green 10 white 11 black
    
    // game module
    Game game(
        .clk            (CLK),
        .move_clk       (G_move_clk),
        .rst            (RST_BTN),
        .sw             (sw),
        .o_head_pos_x   (head_pos_x),
        .o_head_pos_y   (head_pos_y),
        .o_tail_pos_x   (tail_pos_x),
        .o_tail_pos_y   (tail_pos_y),
        .o_apple_pos_x  (apple_pos_x),
        .o_apple_pos_y  (apple_pos_y),
        .game_state     (state),
        .o_LED          (LED)
    );
    
    // graphic module
    top #(
        .MAP_WIDTH      (G_MAP_WIDTH),
        .MAP_HEIGHT     (G_MAP_HEIGHT),
        .MAP_DEPTH      (G_MAP_DEPTH),
        .MAP_A_WIDTH    (G_MAP_A_WIDTH),
        .MAP_D_WIDTH    (G_MAP_D_WIDTH)
        )
        graphics(
        .M_CLK          (CLK),
        .M_pix_stb      (pix_stb),
        .M_RST_BTN      (RST_BTN),
        // .M_move_clk     (G_move_clk),
        .i_head_pos_x   (head_pos_x),
        .i_head_pos_y   (head_pos_y),
        .i_tail_pos_x   (tail_pos_x),
        .i_tail_pos_y   (tail_pos_y),
        .i_apple_pos_x  (apple_pos_x),
        .i_apple_pos_y  (apple_pos_y),
        .i_game_state   (state),
        .M_VGA_HS_O     (VGA_HS_O),
        .M_VGA_VS_O     (VGA_VS_O),
        .M_VGA_R        (VGA_R),
        .M_VGA_G        (VGA_G),
        .M_VGA_B        (VGA_B),
        .LED            (LED)
    );
    
    /*
    always @ (posedge CLK)
    begin
        assign LED [0] = move_clk;
    end
    */
    
    assign LED [0] = LEDs [0];
    
endmodule
