`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LAB GROUP 5
// Engineer: MDANNEMI
// 
// Create Date: 01/30/2023 12:37:36 AM
// Design Name: 
// Module Name: Main
// Project Name: MINI PROJECT
// Target Devices: BASYS BOARD
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision: 0.1
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Main(
    //DISPLAY
    input wire[15:0] sw,
    output wire[15:0] led,
    output wire[6:0] seg,
    output dp,
    output wire[3:0] an,
    input sysClk,
    
    //MOTOR CONTROL
    output wire[7:0] JA,
    //need to connect switches to motor control
    
    //CURRENT CONTROL
    input wire[7:0] JXADC
    );
    
    //PMOD PINS 5, 6, 11, 12 ARE VCC AND GNDS
    parameter ENA_PMOD = 0; //PIN 1
    parameter IN1_PMOD = 6; //PIN 7
    parameter IN2_PMOD = 7; //PIN 8
    
    assign led = sw;    //pair Switches to LEDs
    
    wire m_interr;
    wire[19:0] d_data;
    
    parameter adc_channel = 7'h16; //XA1 (XADC CHANNEL 6)
    
    CURR_CTRL over_curr(JXADC[0], JXADC[4], adc_channel, sysClk, m_interr, d_data); //0=XA1_P ; 4=XA1_N (XADC CHANNEL 6)
    
    DISPLAY curr_display(d_data, sysClk, 4'b1000, seg, dp, an);
    
    MOTOR_CTRL m_motor(sw[4], sw[5], m_interr, sw[3:0], sysClk, 
                       JA[ENA_PMOD], JA[IN1_PMOD], JA[IN2_PMOD]);
//#endregion

endmodule
