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
    output Barr1, //PWM output of Barrel 1
    output Barr2, //PWM output of Barrel 2
    output Barr3 //PWM output of Barrel 3
    ); 
    
    //Setting registers for Servo States
    reg [3:0] S1_State;
    reg [3:0] S2_State;
    reg [3:0] S3_State;
    
    //Setting open and close for servos as local parameters
    //localparam OPEN = 4'h1;
    //localparam CLOSED = 4'h2;
    
    localparam OPEN = 7'd5;
    localparam CLOSED = 7'd10;
    
    
    PWM_SRC #(50) S1_PWM(clk, S1_State, Barr1);
    PWM_SRC #(50) S2_PWM(clk, S2_State, Barr2);    
    PWM_SRC #(50) S3_PWM(clk, S3_State, Barr3);
    
   
    always @ (*) begin
        
        case (S_STATE)                      // Case statement setting open/closed status of each servo for states given by morse code module
            0 : begin
                S1_State = CLOSED;
                S2_State = CLOSED;
                S3_State = CLOSED;
            end
            
            1 : begin
                S1_State = OPEN;
                S2_State = CLOSED;
                S3_State = CLOSED;
            end
            
            2 : begin
                S1_State = CLOSED;
                S2_State = OPEN;
                S3_State = CLOSED;
            end
            
            3 : begin
                S1_State = CLOSED;
                S2_State = CLOSED;
                S3_State = OPEN;
            end

            4 : begin
                S1_State = OPEN;
                S2_State = OPEN;
                S3_State = OPEN;
            end
        endcase
    end
endmodule
