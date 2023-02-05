`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2023 08:56:55 AM
// Design Name: 
// Module Name: Main_tb
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


module Main_tb;

wire[6:0] seg;
wire dp;
wire[3:0] an;
reg[19:0] data;
reg clk;

Main top(seg, dp, an, data, clk);

//Create 100Mhz clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    data = 20'b11111111111111111111; //display F.FFF
    #300;
    data = 20'b10000100001000010000; //display 0.000
    #300;
    data = 20'b00000100001000010000; //display -.000
    #300;
    data = 20'b00000000001000010000; //display -.-00
    #300;
    data = 20'b00000000000000010000; //display -.--0
    #300;
    data = 20'b00000000000000000000; //display -.---
    
    #300;
    data = 20'b11111111111111111111; //display F.FFF
    #300;
    data = 20'b10001100001000011010; //display 1.00A
end
endmodule
