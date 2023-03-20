`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2023 09:15:28 PM
// Design Name: 
// Module Name: PWM_tb
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

//Testbench to test motor control with PWM
//NOTE: SET PARAM IN pwm_src TO 2
module PWM_tb;
   
    
    //#region inputs
    reg m_en;
    reg direction;
    reg[3:0] mode;
    reg clk;
    //#endregion
    
    //#region outputs
    wire ENA;
    wire IN1;
    wire IN2;
    //#endregion
    
    MOTOR_CTRL driver(m_en, direction, mode, clk, ENA, IN1, IN2);
   
   
   //Create 100Mhz clock
    initial begin
        clk = 0;
        //forever #5 clk = ~clk;
        forever #1 clk = ~clk;
    end

    initial begin
    
        //CLOCK ENABLE, MOTOR ENABLE, MOTOR DIRECTION FORWARD, MODE 0
        clk = 1'b1;
        m_en = 1'b1;
        direction = 1'b1;
        
        //cycle mode from 0->15
        for(integer x=0; x<16; x = x + 1) begin
            mode = x;
            #1500;
        end
        
        mode = 4'b1000; //MODE 8
        direction = 1'b0; //REVERSE DIR
        #1500;
        m_en = 1'b0; //DISABLE MOTOR
        #3000;
        m_en = 1'b1; //ENABLE MOTOR
        direction = 1'b1; //FORWARD DIRECTION;
    end

endmodule
