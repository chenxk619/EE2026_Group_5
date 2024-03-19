`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.03.2024 13:37:10
// Design Name: 
// Module Name: selector
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


module selector(
    input clk,
    input left_pushbutton,    
    input right_pushbutton,
    output reg[3:0] idx = 0
    );
    
    wire dBL;
    wire dBR;    
    reg noCheckL;
    reg noCheckR;
        
    debouncer debouncerL(clk, left_pushbutton, dBL);    
    debouncer debouncerR(clk, right_pushbutton, dBR);

    always @ (posedge clk) begin
        if (dBL && !noCheckL) begin            
            noCheckL <= 1;
            idx <= (idx == 4) ? 4 : idx + 1;       
        end
        if (!dBL) begin
            noCheckL <= 0;        
        end
        if (dBR && !noCheckR) begin            
            noCheckR <= 1;
            idx <= (idx == 0) ? 0 : idx - 1;         
        end
        if (!dBR) begin            
            noCheckR <= 0;  
        end    
    end
    
endmodule
