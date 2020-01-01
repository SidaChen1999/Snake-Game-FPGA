`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2019 05:53:16 PM
// Design Name: 
// Module Name: top
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


module top #(parameter MAP_WIDTH=14, MAP_HEIGHT=14, MAP_DEPTH=196, MAP_A_WIDTH=8, MAP_D_WIDTH=2)(
    input wire M_CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire M_pix_stb,         // 25MHz pixel strobe
    input wire M_RST_BTN,         // reset button
    // input wire M_move_clk,        // 1Hz Moving clk
    input wire [3:0] i_head_pos_x,
    input wire [3:0] i_head_pos_y,
    input wire [3:0] i_tail_pos_x,
    input wire [3:0] i_tail_pos_y,
    input wire [3:0] i_apple_pos_x,
    input wire [3:0] i_apple_pos_y,
    input wire [1:0] i_game_state,
    output wire M_VGA_HS_O,       // horizontal sync output
    output wire M_VGA_VS_O,       // vertical sync output
    output reg [3:0] M_VGA_R,     // 4-bit VGA red output
    output reg [3:0] M_VGA_G,     // 4-bit VGA green output
    output reg [3:0] M_VGA_B,      // 4-bit VGA blue output
    output reg [15:0] LED
    );

    // wire rst = ~RST_BTN;    // reset is active low on Arty & Nexys Video
    wire rst = M_RST_BTN;  // reset is active high on Basys3 (BTNC)
    
    wire [9:0] x;       // current pixel x position: 10-bit value: 0-1023
    wire [8:0] y;       // current pixel y position:  9-bit value: 0-511
    wire blanking;      // high within the blanking period
    wire active;        // high during active pixel drawing
    wire screenend;     // high for one tick at the end of screen
    wire animate;       // high for one tick at end of active drawing
    
    // position changing buffer
    reg [7:0] head_pos_x_buff = 8'b01000100;
    reg [7:0] head_pos_y_buff = 8'b01110111;
    reg [7:0] tail_pos_x_buff = 8'b00100010;
    reg [7:0] tail_pos_y_buff = 8'b01110111;
    reg [7:0] apple_pos_x_buff = 8'b10111011;
    reg [7:0] apple_pos_y_buff = 8'b01110111;
    
    reg [11:0] color;

    vga640x360 display (
        .i_clk(M_CLK), 
        .i_pix_stb(M_pix_stb),
        .i_rst(rst),
        .o_hs(M_VGA_HS_O), 
        .o_vs(M_VGA_VS_O), 
        .o_x(x), 
        .o_y(y),
        .o_blanking(blanking),
        .o_active(active),
        .o_screenend(screenend),
        .o_animate(animate)
    );

    // VRAM frame buffers (read-write)
    localparam SCREEN_WIDTH = 640;
    localparam SCREEN_HEIGHT = 360;

    // sprite buffer (read-only)
    localparam SPRITE_SIZE = 16;  // dimensions of square sprites in pixels

    reg [MAP_A_WIDTH-1:0] address0, address1;
    reg [MAP_D_WIDTH-1:0] datain0, datain1;
    wire [MAP_D_WIDTH-1:0] dataout0, dataout1;
    
    reg map_rw = 0; // read write enable
    // map memory
    dpsram #(
        .ADDR_WIDTH(MAP_A_WIDTH), 
        .DATA_WIDTH(MAP_D_WIDTH), 
        .DEPTH(MAP_DEPTH), 
        .MEMFILE("map.mem"))
        map (
        .i_addr0    (address0), 
        .i_addr1    (address1),
        .i_clk0     (M_CLK), 
        .i_clk1     (M_pix_stb),
        .i_write0   (1),
        .i_write1   (0),
        .i_data0    (datain0), 
        .i_data1    (datain1),
        // .rst    (M_RST_BTN),
        .o_data0    (dataout0),
        .o_data1    (dataout1)
        );
    
    // white blank calculation
    localparam Y_BLANK = (SCREEN_HEIGHT - MAP_HEIGHT * SPRITE_SIZE) / 2;
    localparam X_BLANK = (SCREEN_WIDTH - MAP_WIDTH * SPRITE_SIZE)/ 2;
    
    
    // update FSM
    reg [2:0] update_state;

    always @ (posedge M_CLK)
    begin
        /*
        // reset drawing
        if (rst)
        begin

        end
        */
        if (i_game_state[0] == 0)
        begin
        // update FSM
        case (update_state)
        3'b000: // idle state
        begin
            head_pos_x_buff [7:4] <= head_pos_x_buff [3:0];
            head_pos_x_buff [3:0] <= i_head_pos_x;
            head_pos_y_buff [7:4] <= head_pos_y_buff [3:0];
            head_pos_y_buff [3:0] <= i_head_pos_y;
            tail_pos_x_buff [7:4] <= tail_pos_x_buff [3:0];
            tail_pos_x_buff [3:0] <= i_tail_pos_x;
            tail_pos_y_buff [7:4] <= tail_pos_y_buff [3:0];
            tail_pos_y_buff [3:0] <= i_tail_pos_y;
            apple_pos_x_buff [7:4] <= apple_pos_x_buff [3:0];
            apple_pos_x_buff [3:0] <= i_apple_pos_x;
            apple_pos_y_buff [7:4] <= apple_pos_y_buff [3:0];
            apple_pos_y_buff [3:0] <= i_apple_pos_y;
            if (apple_pos_x_buff [7:4] ^ apple_pos_x_buff [3:0] | apple_pos_y_buff [7:4] ^ apple_pos_y_buff [3:0])
                update_state <= 3'b100;
            else if (head_pos_x_buff [7:4] ^ head_pos_x_buff [3:0] | head_pos_y_buff [7:4] ^ head_pos_y_buff [3:0])
                update_state <= 3'b001;
            else if (tail_pos_x_buff [7:4] ^ tail_pos_x_buff [3:0] | tail_pos_y_buff [7:4] ^ tail_pos_y_buff [3:0])
                update_state <= 3'b010;
        end
        3'b001: // put new head
        begin
            // map_rw <= 1;
            address0 <= head_pos_x_buff [3:0] + head_pos_y_buff [3:0] * MAP_WIDTH;
            datain0 <= 2'h3;
            head_pos_x_buff [7:4] <= head_pos_x_buff [3:0];
            head_pos_x_buff [3:0] <= i_head_pos_x;
            head_pos_y_buff [7:4] <= head_pos_y_buff [3:0];
            head_pos_y_buff [3:0] <= i_head_pos_y;
            if (tail_pos_x_buff [7:4] ^ tail_pos_x_buff [3:0] | tail_pos_y_buff [7:4] ^ tail_pos_y_buff [3:0])
                update_state <= 3'b010;
            else if (apple_pos_x_buff [7:4] ^ apple_pos_x_buff [3:0] | apple_pos_y_buff [7:4] ^ apple_pos_y_buff [3:0])
                update_state <= 3'b011;
            else update_state <= 3'b000;
        end
        
        3'b010: // return old tail // having problem
        begin
            // map_rw <= 1;
            address0 <= tail_pos_x_buff [7:4] + tail_pos_y_buff [7:4] * MAP_WIDTH;
            datain0 <= ((tail_pos_x_buff [7:4] % 2) ^ (tail_pos_y_buff [7:4] % 2)) ? 2'h1 : 2'h0;
            tail_pos_x_buff [7:4] <= tail_pos_x_buff [3:0];
            tail_pos_x_buff [3:0] <= i_tail_pos_x;
            tail_pos_y_buff [7:4] <= tail_pos_y_buff [3:0];
            tail_pos_y_buff [3:0] <= i_tail_pos_y;
            if (head_pos_x_buff [7:4] ^ head_pos_x_buff [3:0] | head_pos_y_buff [7:4] ^ head_pos_y_buff [3:0])
                update_state <= 3'b001;
            else if (apple_pos_x_buff [7:4] ^ apple_pos_x_buff [3:0] | apple_pos_y_buff [7:4] ^ apple_pos_y_buff [3:0])
                update_state <= 3'b011;
            else update_state <= 3'b000;
        end
        
        3'b011: // put new apple
        begin
            // map_rw <= 1;
            address0 <= apple_pos_x_buff [3:0] + apple_pos_y_buff [3:0] * MAP_WIDTH;
            datain0 <= 2'h3; // why I put black but turn out white?
            apple_pos_x_buff [7:4] <= apple_pos_x_buff [3:0];
            apple_pos_x_buff [3:0] <= i_apple_pos_x;
            apple_pos_y_buff [7:4] <= apple_pos_y_buff [3:0];
            apple_pos_y_buff [3:0] <= i_apple_pos_y;
            if (head_pos_x_buff [7:4] ^ head_pos_x_buff [3:0] | head_pos_y_buff [7:4] ^ head_pos_y_buff [3:0])
                 update_state <= 3'b001;
            if (tail_pos_x_buff [7:4] ^ tail_pos_x_buff [3:0] | tail_pos_y_buff [7:4] ^ tail_pos_y_buff [3:0])
                 update_state <= 3'b010;
            else update_state <= 3'b000;
            // update_state <= 3'b100;
        end
        
        3'b100: // turn old apple to head // useless now
        begin
            // map_rw <= 1;
            address0 <= apple_pos_x_buff [7:4] + apple_pos_y_buff [7:4] * MAP_WIDTH;
            datain0 <= 2'h2;
            apple_pos_x_buff [7:4] <= apple_pos_x_buff [3:0];
            apple_pos_x_buff [3:0] <= i_apple_pos_x;
            apple_pos_y_buff [7:4] <= apple_pos_y_buff [3:0];
            apple_pos_y_buff [3:0] <= i_apple_pos_y;

            if (head_pos_x_buff [7:4] ^ head_pos_x_buff [3:0] | head_pos_y_buff [7:4] ^ head_pos_y_buff [3:0])
                 update_state <= 3'b001;
            if (tail_pos_x_buff [7:4] ^ tail_pos_x_buff [3:0] | tail_pos_y_buff [7:4] ^ tail_pos_y_buff [3:0])
                 update_state <= 3'b010;
            else update_state <= 3'b000;
        end
        
        default:
            begin
                head_pos_x_buff [7:4] <= head_pos_x_buff [3:0];
                head_pos_x_buff [3:0] <= i_head_pos_x;
                head_pos_y_buff [7:4] <= head_pos_y_buff [3:0];
                head_pos_y_buff [3:0] <= i_head_pos_y ;
                tail_pos_x_buff [7:4] <= tail_pos_x_buff [3:0];
                tail_pos_x_buff [3:0] <= i_tail_pos_x ;
                tail_pos_y_buff [7:4] <= tail_pos_y_buff [3:0];
                tail_pos_y_buff [3:0] <= i_tail_pos_y ;
                apple_pos_x_buff [7:4] <= apple_pos_x_buff [3:0];
                apple_pos_x_buff [3:0] <= i_apple_pos_x ;
                apple_pos_y_buff [7:4] <= apple_pos_y_buff [3:0];
                apple_pos_y_buff [3:0] <= i_apple_pos_y;
                if (apple_pos_x_buff [7:4] ^ apple_pos_x_buff [3:0] | apple_pos_y_buff [7:4] ^ apple_pos_y_buff [3:0])
                    update_state <= 3'b100;
                else if (head_pos_x_buff [7:4] ^ head_pos_x_buff [3:0] | head_pos_y_buff [7:4] ^ head_pos_y_buff [3:0])
                    update_state <= 3'b001;
                else if (tail_pos_x_buff [7:4] ^ tail_pos_x_buff [3:0] | tail_pos_y_buff [7:4] ^ tail_pos_y_buff [3:0])
                    update_state <= 3'b010;
            end
        endcase
        end
        /*
        // detection of changes in address
        if (head_pos_x_buff [7:4] ^ head_pos_x_buff [3:0] || head_pos_y_buff [7:4] ^ head_pos_y_buff [3:0])
        begin
            LED [6] <= ~LED [6];
            map_rw <= 1;
            // put new head
            address_m = head_pos_x_buff [3:0] + head_pos_y_buff [3:0] * MAP_WIDTH;
            datain_m = 2'h3;
        end
        
        if (tail_pos_x_buff [7:4] ^ tail_pos_x_buff [3:0] || tail_pos_y_buff [7:4] ^ tail_pos_y_buff [3:0])
        begin
            LED [7] <= ~LED [7];
            map_rw <= 1;
            // return old tail to background
            address_m = tail_pos_x_buff [7:4] + tail_pos_y_buff [7:4] * MAP_WIDTH;
            datain_m <= (tail_pos_x_buff [7:4] % 2) ^ (tail_pos_y_buff [7:4] % 2) ? 2'h1 : 2'h0;
        end

        
        if (apple_pos_x_buff [7:4] ^ apple_pos_x_buff [3:0] || apple_pos_y_buff [7:4] ^ apple_pos_y_buff [3:0])
        begin
            LED [8] <= ~LED [8];
            map_rw <= 1;
            // put new apple
            address_m = apple_pos_x_buff [3:0] + apple_pos_y_buff [3:0] * MAP_WIDTH;
            datain_m = 2'h2;
            
            // turn old apple to head
            address_m = apple_pos_x_buff [7:4] + apple_pos_y_buff [7:4] * MAP_WIDTH;
            datain_m = 2'h3;
            // (apple_pos_x_buff [7:4] % 2) ^ (apple_pos_y_buff [7:4] % 2) ? 2'h1 : 2'h0;
        end
        */

        // draw at the same time as output
        if (M_pix_stb)  // once per pixel
        // map_rw <= 0; // 0 to read
        begin
            if (x < X_BLANK + 1 || x > SCREEN_WIDTH - X_BLANK + 1 || y < Y_BLANK || y > SCREEN_HEIGHT - Y_BLANK - 1) // having problem
            begin
                color <= active ? 12'hfff : 0;
            end
            else
            begin
                // map_rw <= 0; // 0 to read
                // calculate address of map buffer
                address1 <= (x - X_BLANK) / SPRITE_SIZE + ((y - Y_BLANK) / SPRITE_SIZE) * MAP_WIDTH; 
                case (dataout1)
                    2'h0: //lime green
                    begin
                        color <= active ? 12'h7f0 :0;
                    end
                
                    2'h1: // grass green
                    begin
                        color <= active ? 12'h080 : 0;
                    end
                
                    2'h2: // white
                    begin
                        color <= active ? 12'hfff : 0;
                    end
                
                    2'h3: // black
                    begin
                        color <= active ? 12'h000: 0;
                    end
                
                    default:
                    begin
                        color <= active ? 12'hfff : 0;
                    end
                endcase
            
            end
        end
        
        /*
        if (M_move_clk)
        begin
            map_rw <= 1;
            case (i_game_state)
                2'b00: // normal
                begin
                    // replace old head with body
                    address_m <= head_old;
                    datain_m <= 5'h10;
                    // replace old tail with background color based on coordinate
                    address_m <= tail_old;
                    datain_m <= {(tail_old % MAP_WIDTH % 2) ^ (tail_old  / MAP_WIDTH % 2), 2'b00};
                    // put new head at new position
                    address_m <= i_head_pos_x + i_head_pos_y * MAP_WIDTH;
                    datain_m <= 5'hc;
                    // put new tail at new position
                    address_m <= i_tail_pos_x + i_tail_pos_y * MAP_WIDTH;
                    datain_m <= 5'h8;
                end
        
                2'b01: // eat apple
                begin
                    // replace old head with eat body
                    address_m <= head_old;
                    datain_m <= 5'h14;
                    // no need to replace old tail with new tail, cause they are the same
                    // put new head at new position
                    address_m <= i_head_pos_x + i_head_pos_y * MAP_WIDTH;
                    datain_m <= 5'hc;
                end
        
                2'b10: // dead
                begin
                    // replace old head with dead head
                    address_m <= head_old;
                    datain_m <= 5'h18;
                end
        
                default:
                begin
                    address_m <= head_old;
                    datain_m <= 5'h10;
                    address_m <= tail_old;
                    datain_m <= {(tail_old % MAP_WIDTH % 2) ^ (tail_old  / MAP_WIDTH % 2), 2'b00};
                    address_m <= i_head_pos_x + i_head_pos_y * MAP_WIDTH;
                    datain_m <= 5'hc;
                    address_m <= i_tail_pos_x + i_tail_pos_y * MAP_WIDTH;
                    datain_m <= 5'h8;
                end
            endcase
        end
        */
        
        M_VGA_R <= color[11:8];
        M_VGA_G <= color[7:4];
        M_VGA_B <= color[3:0];
        
    end
endmodule
