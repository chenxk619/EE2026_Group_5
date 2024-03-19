`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: 
//  STUDENT B NAME:
//  STUDENT C NAME: 
//  STUDENT D NAME:  
//
//////////////////////////////////////////////////////////////////////////////////

module Top_Student (
    input btnC,
    input btnD,
    input btnL,
    input btnR,
    input btnU,
    input SW0,
    input CLOCK,
    output [7:0] Jx
);
reg [15:0] oled_data;
wire slow_clk;
wire [12:0] pixel_index;
wire sample_pixel, sending_pixels, frame_begin;
wire [6:0] x;
wire [5:0] y;
assign Jx[2] = 0;
reg start = 0;
reg [28:0]horizontal_count = 0;
reg[28:0]vertical_count = 0;
reg[6:0]horizontal = 45;
reg[6:0]vertical = 55;
reg[22:0]speed_1 = 2_222_000;
reg[23:0]speed_2 = 3_333_000;
reg[24:0]speed_3 = 6_666_000;

clk6p25m runslow(CLOCK, slow_clk);

//x and y coordinates
assign x = pixel_index % 96;
assign y = pixel_index / 96; 


always @ (posedge CLOCK) begin
    
    if (btnC) begin
        start = 1;
        horizontal <= 45;
        vertical <= 55;
    end
    
    if (start) begin
    
        if (btnL) begin
            if (SW0) begin
                horizontal_count <= (horizontal_count == speed_2) ? 0 : horizontal_count + 1;
            end else begin
                horizontal_count <= (horizontal_count == speed_1) ? 0 : horizontal_count + 1;
            end
            if (horizontal_count == 0) begin
                if (horizontal <= 89) begin
                    horizontal <= horizontal + 1;
                end
            end
        end
        
        if (btnR) begin
            if (SW0) begin
                horizontal_count <= (horizontal_count == speed_2) ? 0 : horizontal_count + 1;
            end else begin
                horizontal_count <= (horizontal_count == speed_1) ? 0 : horizontal_count + 1;
            end
            if (horizontal_count == 0) begin
                if (horizontal >= 2) begin
                    horizontal <= horizontal - 1;
                end
            end
        end
        
        if (btnD) begin
            if (SW0) begin
                vertical_count <= (vertical_count == speed_3) ? 0 : vertical_count + 1;
            end else begin
                vertical_count <= (vertical_count == speed_1) ? 0 : vertical_count + 1;
            end
            if (vertical_count == 0) begin
                if (vertical >= 2) begin
                    vertical <= vertical - 1;
                end
            end
        end
        if ((x >= horizontal) && (x <= horizontal + 5)
        && (y >= vertical) && (y <= vertical + 5)) begin
            oled_data <= 16'b11111_111111_11111;
        end else begin
            oled_data <= 16'b00000_000000_00000;
        end
    
    
    end else begin
        if (x >= 2 && x <= 7 && y >= 2 && y <= 7) begin
            oled_data <= 16'b00000_000000_11111;
        end else begin
            oled_data <= 16'b00000_000000_00000;
        end
   end

end


Oled_Display alias (slow_clk, btnU, frame_begin, sending_pixels,
  sample_pixel, pixel_index, oled_data, Jx[0], Jx[1], Jx[3], Jx[4], Jx[5], Jx[6],
  Jx[7]);

endmodule