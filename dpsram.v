`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/22/2019 07:00:32 PM
// Design Name: 
// Module Name: dpsram
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


module dpsram #(parameter DATA_WIDTH = 2, parameter ADDR_WIDTH = 8, parameter DEPTH = 196, MEMFILE="")
    (
    input [ADDR_WIDTH-1:0] i_addr0, i_addr1,
    input [DATA_WIDTH-1:0] i_data0, i_data1,
    input i_write0, i_write1, i_clk0, i_clk1,
    output [DATA_WIDTH-1:0] o_data0, o_data1
     );
    
    reg [DATA_WIDTH-1:0] memory_array [DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] reg_addr0, reg_addr1;
    
    assign o_data0 = memory_array[reg_addr0];
    assign o_data1 = memory_array[reg_addr1];
    
    initial begin
        if (MEMFILE > 0)
        begin
            $display("Loading memory init file '" + MEMFILE + "' into array.");
            $readmemh(MEMFILE, memory_array);
        end
    end
    
    always @(posedge i_clk0)
    begin
        if (i_write0)
            memory_array[i_addr0] <= i_data0;
        reg_addr0 <= i_addr0;
    end
    always @(posedge i_clk1)
    begin
        if (i_write1)
            memory_array[i_addr1] <= i_data1;
        reg_addr1 <= i_addr1;
    end
    endmodule
