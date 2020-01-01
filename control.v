`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/16 17:58:16
// Design Name: 
// Module Name: control
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


module control(
    input wire [3:0] sw,  // four switches, [0] right [1] left [2] down [3] up
    input wire clk,
    input wire move_clk,
    input wire rst,
    output wire start_signal,
    // output wire o_write_en,
    output wire [1:0]out    // 00 right     01 left         10 down         11 up
);

reg[1:0] data;
// reg write_en;
reg[1:0] current;
reg start;
assign out = data;
// assign o_write_en = write_en;
assign start_signal = start;
initial
begin
    data <= 2'b00;
//    write_en = 0;
    current <= 2'b00;
    start <= 0;
end

reg sw_buff [7:0];

always @(posedge clk)
begin
    sw_buff [7] <= sw_buff [6];
    sw_buff [5] <= sw_buff [4];
    sw_buff [3] <= sw_buff [2];
    sw_buff [1] <= sw_buff [0];
    sw_buff [6] <= sw [3]; 
    sw_buff [4] <= sw [2];
    sw_buff [2] <= sw [1];
    sw_buff [0] <= sw [0];
    if (rst)
    begin
        data <= 2'b00;
        current <= 2'b00;
        start <= 0;
    end
    else  if (move_clk)
        current <= data;
    else
    begin
    case (current)
    2'b00:              // 00 right
    begin
        if (sw_buff [4] && ~sw_buff [5])
        begin
            start <= 1;
            data <= 2'b10;// 10 down
 //           write_en = 1;
        end
        else if(sw_buff [6] && ~sw_buff [7])
        begin
            start <= 1;
            data <= 2'b11;//11 up
        end
        else
        begin
            current <= current;
            data <= data;
 //           write_en = 0;
        end
    end
    2'b01:  // 01 left 
    begin
        if (sw_buff [4] && ~sw_buff [5])
        begin
            start <= 1;
            data <= 2'b10;// 10 down
 //           write_en = 1;
        end
        else if(sw_buff [6] && ~sw_buff [7])
        begin
            start <= 1;
            data <= 2'b11;//11 up
//            write_en = 1;
        end
        else
        begin
            current <= current;
            data <= data;
 //           write_en = 0;
        end
    end
    2'b10:// 10 down 
    begin
        if (sw_buff [0] && ~sw_buff [1])
        begin
            start <= 1;
            data <= 2'b00;// 00 right
//            write_en = 1;
        end
        else if(sw_buff [2] && ~sw_buff [3])
        begin
            start <= 1;
            data <= 2'b01;// 01 left
 //           write_en = 1;
        end
        else
        begin
            current <= current;
            data <= data;
 //           write_en = 0;
        end
    end
    2'b11://11 up
    begin
        if (sw_buff [0] && ~sw_buff [1])
        begin
            start <= 1;
            data <= 2'b00;// 00 right
 //           write_en = 1;
        end
        else if(sw_buff [2] && ~sw_buff [3])
        begin
            start <= 1;
            data <= 2'b01;// 01 left
 //           write_en = 1;
        end
        else
        begin
            current <= current;
            data <= data;
 //           write_en = 0;
        end
    end
    endcase
    end
end

endmodule
