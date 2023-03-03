`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LAB GROUP 5
// Engineer: MDANNEMI
// 
// Create Date: 01/30/2023 12:37:36 AM
// Design Name: 
// Module Name: Top
// Project Name: NAUTILUS_L1
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


module Top (
    //DISPLAY
    input wire[15:0] sw,
    output wire[15:0] led,
    output wire[6:0] seg,
    output dp,
    output wire[3:0] an,
    input sysClk,
    
    //ADC ports
    input vauxp6,
    input vauxn6,
    input vauxp7,
    input vauxn7,
    input vauxp15,
    input vauxn15,
    input vauxp14,
    input vauxn14,
    input vp_in,
    input vn_in,
    
    //MOTOR CONTROL
    output wire[7:0] JA,
    output wire[6:0] JB,
    input wire JB_IR
    );
    
    //PMOD PINS 5, 6, 11, 12 ARE VCC AND GNDS
    parameter ENA_PMOD = 0; //PIN 1
    parameter IN1_PMOD = 4; //PIN 9
    parameter IN2_PMOD = 5; //PIN 10
    
    wire m_interr;
    wire[19:0] d_data;
    
    parameter adc_channel = 8'h16; //XA1 (XADC CHANNEL 6)
    
    //0=XA1_P ; 4=XA1_N (XADC CHANNEL 6)
    CURR_CTRL over_curr(
        .CURR_CTRL_EN(sw[15]),
        .direction(sw[5]),
        .an_pos_in(vauxp6),   .an_neg_in(vauxn6), 
        .vauxp14(vauxp14),    .vauxn14(vauxn14), 
        .vauxp7(vauxp7),      .vauxn7(vauxn7), 
        .vauxp15(vauxp15),    .vauxn15(vauxn15),
        .vp_in(vp_in),        .vn_in(vn_in), 
        .channel_out(adc_channel), 
        .clk(sysClk), 
        .interrupt(m_interr), 
        .data(d_data), 
        .led(led)); 
    
    DISPLAY curr_display(
        .data(d_data), 
        .clk(sysClk), 
        .dpEnable(4'b1000), 
        .segPorts(seg), 
        .dpPort(dp), 
        .anode(an));
    
    MOTOR_CTRL m_motor(
        .enable(sw[4]), 
        .direction(sw[5]), 
        .interrupt(m_interr),
        .mode(sw[3:0]), 
        .clk(sysClk), 
        .ENA(JA[ENA_PMOD]),
        .IN1(JA[IN1_PMOD]),
        .IN2(JA[IN2_PMOD]));
//#endregion
IR_INPUT IR (
    .clk(sysClk),
    .IR_Pin(JB_IR),
    .LED(JB[1]));
endmodule
