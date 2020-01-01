`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/18 22:01:04
// Design Name: 
// Module Name: Game_Body
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


module Game_Body
(
    input wire clk,
    input wire move_clk,
    input wire rst,
    input wire start,
    input wire [1:0] sw,
 //   output wire buffer_get,
    output wire [3:0] o_head_pos_x,
    output wire [3:0] o_head_pos_y,
    output wire [3:0] o_tail_pos_x,
    output wire [3:0] o_tail_pos_y,
    output wire [3:0] o_apple_pos_x,
    output wire [3:0] o_apple_pos_y,
    output wire [1:0] game_state    //00 normal, 01 eat apple, 10 dead.
);
// 1 2 3 4 5
// 2
// 3
// 4
// 5
reg[4:0] head_x,head_y,tail_x,tail_y,apple_x,apple_y,new_apple_x,new_apple_y;
reg[2:0] state;
reg[4:0] snake_x[31:0],snake_y[31:0];
reg[4:0] length;
reg[1:0] buffer;
reg move;
reg[1:0] game;
assign game_state = game;
// reg buffer_clear;
// assign buffer_get = buffer_clear;

assign o_head_pos_x = head_x - 1;
assign o_head_pos_y = head_y - 1;
assign o_tail_pos_x = tail_x - 1;
assign o_tail_pos_y = tail_y - 1;
assign o_apple_pos_x = apple_x - 1;
assign o_apple_pos_y = apple_y - 1;

integer i;
wire[3:0] coor;
RNG rng(.clk(clk),.rnd(coor));

initial 
begin
    move <= 0;
//    buffer_clear = 0;
    length <= 2;
    head_x <= 4'b0101;
    head_y <= 4'b1000;
    tail_x <= 4'b0011;
    tail_y <= 4'b1000;
    apple_x <= 4'b1100;
    apple_y <= 4'b1000;
    game <= 2'b00;
    state <= 3'b000;
end

/*
always @(negedge move_clk)
begin
    move <= 1;
end
*/
always @(posedge clk)
begin

    if (rst)
    begin
        move <= 0;
        length <= 3;
        game <= 2'b00;
        state <= 3'b000;
        snake_x[0] <= 4'b0101;
        snake_y[0] <= 4'b1000;
        snake_x[1] <= 4'b0100;
        snake_y[1] <= 4'b1000;
        snake_x[2] <= 4'b0011;
        snake_y[2] <= 4'b1000;
        head_x <= 4'b0101;
        head_y <= 4'b1000;
        tail_x <= 4'b0011;
        tail_y <= 4'b1000;
        apple_x <= 4'b1100;
        apple_y <= 4'b1000;
    end
    else
    begin
        if (move_clk)
            move <= 1;

    if (start)
    begin
        case (state)
            3'b000:
            begin
                game <= 2'b00;
                if (move)
                begin
                    buffer <= sw;
 //                   buffer_clear = 1;
                    state <= 3'b001;
                end
            end
            3'b001:
            begin
 //               buffer_clear = 0;
                case (buffer)   // 00 right     01 left         10 down         11 up
                    2'b00: begin head_x = head_x + 1; head_y = head_y;  end
                    2'b01: begin head_x = head_x - 1; head_y = head_y;  end
                    2'b10: begin head_x = head_x; head_y = head_y + 1;  end
                    2'b11: begin head_x = head_x; head_y = head_y - 1;  end
                endcase
//                if ((head_x < 1)||(head_x > 14)||(head_y < 1)||(head_y > 14)) //hit wall
//                    state <= 3'b010;
                if (head_x < 1)
                begin
                    head_x <= 1;
                    state <= 3'b010;
                end
                else if (head_x > 14)
                begin
                    head_x <= 14;
                    state <= 3'b010;
                end
                else if (head_y < 1)
                begin
                    head_y <= 1;
                    state <= 3'b010;
                end
                else if (head_y > 14)
                begin
                    head_y <= 14;
                    state <= 3'b010;
                end
                else if ((head_x == apple_x) && (head_y == apple_y))    //eat apple
                    state <= 3'b011;
                else
                begin
                    for (i = 1; i < length; i = i+1)
                        if ((snake_x[i] == head_x) && (snake_y[i] == head_y))   //hit itself
                            state = 3'b010;
                    if (state != 3'b010)    // normal move
                        state = 3'b111;
                end
            end
            3'b010:
            begin
                game <= 2'b10;
            end
            3'b011: // 
            begin
                if (length == 31)
                    state <= 3'b100;
                else
                begin
                    length <= length + 1;
                    state <= 3'b100;
                end
            end
            3'b100: // random apple_x
            begin
                new_apple_x <= coor;
                state <= 3'b101;
            end
            3'b101: // random apple_y
            begin
                new_apple_y <= coor;
                state <= 3'b110;
            end
            3'b110:
            begin
                for (i = 0; i < length; i = i + 1)
                    if (((new_apple_x == snake_x[i]) && (new_apple_y == snake_y[i])) || ((new_apple_x == head_x) && (new_apple_y == head_y)))
                        state = 3'b100;
                if (state != 3'b100)
                begin
                    apple_x <= new_apple_x;
                    apple_y <= new_apple_y;
                    state <= 3'b111;
                    game <= 2'b01;
                end
            end
            3'b111:
            begin
                snake_x[31] <= snake_x[30];
                snake_x[30] <= snake_x[29];
                snake_x[29] <= snake_x[28];
                snake_x[28] <= snake_x[27];
                snake_x[27] <= snake_x[26];
                snake_x[26] <= snake_x[25];
                snake_x[25] <= snake_x[24];
                snake_x[24] <= snake_x[23];
                snake_x[23] <= snake_x[22];
                snake_x[22] <= snake_x[21];
                snake_x[21] <= snake_x[20];
                snake_x[20] <= snake_x[19];
                snake_x[19] <= snake_x[18];
                snake_x[18] <= snake_x[17];
                snake_x[17] <= snake_x[16];
                snake_x[16] <= snake_x[15];
                snake_x[15] <= snake_x[14];
                snake_x[14] <= snake_x[13];
                snake_x[13] <= snake_x[12];
                snake_x[12] <= snake_x[11];
                snake_x[11] <= snake_x[10];
                snake_x[10] <= snake_x[9];
                snake_x[9] <= snake_x[8];
                snake_x[8] <= snake_x[7];
                snake_x[7] <= snake_x[6];
                snake_x[6] <= snake_x[5];
                snake_x[5] <= snake_x[4];
                snake_x[4] <= snake_x[3];
                snake_x[3] <= snake_x[2];
                snake_x[2] <= snake_x[1];
                snake_x[1] <= snake_x[0];
                snake_x[0] <= head_x;
                
                snake_y[31] <= snake_y[30];
                snake_y[30] <= snake_y[29];
                snake_y[29] <= snake_y[28];
                snake_y[28] <= snake_y[27];
                snake_y[27] <= snake_y[26];
                snake_y[26] <= snake_y[25];
                snake_y[25] <= snake_y[24];
                snake_y[24] <= snake_y[23];
                snake_y[23] <= snake_y[22];
                snake_y[22] <= snake_y[21];
                snake_y[21] <= snake_y[20];
                snake_y[20] <= snake_y[19];
                snake_y[19] <= snake_y[18];
                snake_y[18] <= snake_y[17];
                snake_y[17] <= snake_y[16];
                snake_y[16] <= snake_y[15];
                snake_y[15] <= snake_y[14];
                snake_y[14] <= snake_y[13];
                snake_y[13] <= snake_y[12];
                snake_y[12] <= snake_y[11];
                snake_y[11] <= snake_y[10];
                snake_y[10] <= snake_y[9];
                snake_y[9] <= snake_y[8];
                snake_y[8] <= snake_y[7];
                snake_y[7] <= snake_y[6];
                snake_y[6] <= snake_y[5];
                snake_y[5] <= snake_y[4];
                snake_y[4] <= snake_y[3];
                snake_y[3] <= snake_y[2];
                snake_y[2] <= snake_y[1];
                snake_y[1] <= snake_y[0];
                snake_y[0] <= head_y;

//                for (i = 1; i < length - 1; i = i + 1)
//                begin
//                    snake_x[i] <= snake_x[i-1];
//                    snake_y[i] <= snake_y[i-1]; 
//                end                 
//                snake_x[0] <= head_x;
//                snake_y[0] <= head_y;
                tail_x <= snake_x[length - 1];
                tail_y <= snake_y[length - 1];
                move <= 0;
                state <= 3'b000;
                
            end
        endcase
    end
    end
end

endmodule
