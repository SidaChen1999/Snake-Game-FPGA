`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/16 21:10:59
// Design Name: 
// Module Name: CBuffer
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


module CBuffer
(
    input wire i_write,
    input wire i_read, // 10,11 read, 01 write , 00 keep 
    input wire [1:0] i_data,
    output wire [1:0] o_data,
    output wire [2:0] o_size
);

integer i;

reg [2:0] size;
reg [1:0] buff[7:0];
reg [2:0] head,tail;
reg [1:0] data;
assign o_size = size;
assign o_data = data;

initial 
begin
    size = 0;
    data = 0;
    head = 0;
    tail = 0;
    for(i = 0; i < 8; i = i + 1)
    begin
        buff[i] = 0;
    end
end

always @(i_write or i_read)
begin
    if (i_read)
    begin
            if (size != 0)
            begin
                data = buff[tail];
                size = size - 1;
                tail = tail + 1;
                if (tail == 7)
                    tail = 0;
            end
    end
    else if (i_write)
    begin
        if (size <= 8)
        begin
            size = size + 1;
            buff[head] = i_data;
            head = head + 1;
            if (head == 7)
                head = 0;
            data = buff[tail];
        end
    end
    else
    begin
          data = data;
          size = size;
    end
end

endmodule
