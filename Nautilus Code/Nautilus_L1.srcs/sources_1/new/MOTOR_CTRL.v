`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Boat Crew 5
// Engineer: Mark Dannemiller
// 
// Create Date: 02/01/2023 12:07:17 AM
// Design Name: 
// Module Name: MOTOR_CTRL
// Project Name: Nautilus
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
// **Code is free to use as long as you attribute our GitHub repository for others to find the same resources.**
// 
//////////////////////////////////////////////////////////////////////////////////


module MOTOR_CTRL(
    input enable,
    input direction,
    input interrupt,
    
    //#region PWM MODULE VALUES
    input[6:0] mode,
    input clk,

    output ENA,
    output IN1,
    output IN2
    //#endregion
    );
    
    wire pwm;
    
    PWM_SRC src(clk, mode, pwm); //module to convert clock signal into pwm value
    
    //CHANGED THIS BIT TO BRAKE ON 0
    assign ENA = (pwm || mode==0) & enable & ~interrupt; //outputs pwm signal if module is enabled
    assign IN1 = direction || mode==0;
    assign IN2 = ~direction || mode==0;
    
endmodule
