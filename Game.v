`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/19 09:48:47
// Design Name: 
// Module Name: Game
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


module Game
(
    input wire clk,
    input wire move_clk,
    input wire rst,
    input wire [3:0] sw,
    output wire [3:0] o_head_pos_x,
    output wire [3:0] o_head_pos_y,
    output wire [3:0] o_tail_pos_x,
    output wire [3:0] o_tail_pos_y,
    output wire [3:0] o_apple_pos_x,
    output wire [3:0] o_apple_pos_y,
    output wire [1:0] game_state,    // 00normal, 01 eat apple, 10 dead.
    output reg [15:0] o_LED
);

//module control(
//    input wire [3:0] sw,  // four switches, [0] right [1] left [2] down [3] up
//    output wire start_signal,
//    output wire o_write_en,
//    output wire [1:0]out    // 00 right     01 left         10 down         11 up
//);
wire [15:0] LEDs;

wire start;
wire buffer_write;
wire [1:0] sw_signal;
control crt(.sw(sw),
            .clk(clk),
            .move_clk(move_clk),
            .rst(rst),
            .start_signal(start),
           //  .o_write_en(buffer_write),
            .out(sw_signal));




//module CBuffer
//(
//    input wire i_write,
//    input wire i_read, // 10,11 read, 01 write , 00 keep 
//    input wire [1:0] i_data,
//    output wire [1:0] o_data,
//    output wire [2:0] o_size
//);

/*
wire[1:0] buffer_read;
wire[2:0] buffer_size;
wire[1:0] buffer_data;
CBuffer buff(.i_write(buffer_write),
             .i_read(buffer_read),
             .i_data(sw_signal),
             .o_data(buffer_data),
             .o_size(buffer_size));
*/

//module Game_Body
//(
//    input wire clk,
//    input wire move_clk
//    input wire rst,,
//    input wire start,
//    input wire [1:0] sw,
//    output wire buffer_get,
//    output wire [2:0] o_head_pos_x,
//    output wire [2:0] o_head_pos_y,
//    output wire [2:0] o_tail_pos_x,
//    output wire [2:0] o_tail_pos_y,
//    output wire [2:0] o_apple_pos_x,
//    output wire [2:0] o_apple_pos_y,
//    output wire [1:0] game_state    //00normal, 01 eat apple, 10 dead.
//);

Game_Body GB(.clk(clk),
             .move_clk(move_clk),
             .rst(rst),
             .start(start),
             .sw(sw_signal),
             // .buffer_get(buffer_read),
             .o_head_pos_x(o_head_pos_x),
             .o_head_pos_y(o_head_pos_y),
             .o_tail_pos_x(o_tail_pos_x),
             .o_tail_pos_y(o_tail_pos_y),
             .o_apple_pos_x(o_apple_pos_x),
             .o_apple_pos_y(o_apple_pos_y),
             .game_state(game_state));

always @(*)
begin          
    // o_LED <= LEDs;
    o_LED [1] <= start;
    o_LED [2] <= game_state [0];
    o_LED [3] <= game_state [1];
    o_LED [4] <= sw_signal [0];
    o_LED [5] <= sw_signal [1];
end
endmodule
