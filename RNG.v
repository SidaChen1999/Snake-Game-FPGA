`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/16 16:40:58
// Design Name: 
// Module Name: RNG
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


module RNG // Random Number Generator
(
    input clk,
    output  reg[3:0] rnd 
);

reg [8:0] rand_num;

initial 
begin
    rand_num <= 9'd132;
end

always@(posedge clk)
        begin
            rand_num[0] <= rand_num[8];
            rand_num[1] <= rand_num[0];
            rand_num[2] <= rand_num[1];
            rand_num[3] <= rand_num[2];
            rand_num[4] <= rand_num[3]^rand_num[8];
            rand_num[5] <= rand_num[4]^rand_num[8];
            rand_num[6] <= rand_num[5]^rand_num[8];
            rand_num[7] <= rand_num[6];
            rand_num[8] <= rand_num[7];
            rnd = (rand_num % 14) + 1;
        end
endmodule
