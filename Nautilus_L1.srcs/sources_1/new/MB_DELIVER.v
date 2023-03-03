`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2023 06:19:58 PM
// Design Name: 
// Module Name: MB_DELIVER
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


module MB_DELIVER(
    input wire[2:0] S_STATE, // Set state of all 3 servos
    input clk,  //Clock for PWM
    output Bar1, //PWM output of Barrel 1
    output Bar2, //PWM output of Barrel 2
    output Bar3 //PWM output of Barrel 3
    ); 
endmodule
