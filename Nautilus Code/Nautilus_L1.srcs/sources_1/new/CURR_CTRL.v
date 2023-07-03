`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Boat Crew 5
// Engineer: Mark Dannemiller
// 
// Create Date: 02/01/2023 12:07:17 AM
// Design Name: 
// Module Name: CURR_CTRL
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


module CURR_CTRL(
    input CURR_CTRL_EN, //OFF/0 = EN
    input direction,
    input clk,
    output interrupt,
    output [19:0] data,
    output reg [15:0] led,
    
    //input[15:0] raw_xa_data,
    input[15:0] xa_data
    //input[7:0] xa_channel, //varying channel from ADC_Handler
    //input[7:0] m_channel, //desired current channel for this module to monitor
    //input xa_ready
    );
    
    //localparam CH6 = 8'h16; //desired xadc channel
    
    //reg[15:0] xa_data; //only updates when xa_channel = CH6
    
    //binary to decimal converter signals
    reg [32:0] count;
    reg b2d_start;
    reg [15:0] b2d_din;
    wire [15:0] b2d_dout;
    wire b2d_done;
    
    //STATES FOR CONVERSION OUTPUT
    localparam S_IDLE = 0;
    localparam S_FRAME_WAIT = 1;
    localparam S_CONVERSION = 2;
    reg [1:0] state = S_IDLE;
    
    //DATA TO BE SENT TO DISPLAY    
    reg [15:0] curr_data;
    
    //OVERFLOW AND LATCH CONTROL
    reg overflow;
    reg[32:0] latchCount = 0;
    reg[32:0] overWait = 0;
    localparam wait_time = 50000000; //Wait 0.5 second before attempting to overflow again
    localparam latch_time = 300000000; //3 seconds
    localparam S_NORMAL = 0;
    localparam S_SAMPLE = 1;
    localparam S_OVERFLOW = 2;
    reg[1:0] o_state = S_NORMAL;
   
    //SET A MAXIMUM CURRENT THRESHOLD AND ASSIGN DATA TO EITHER THAT OR "O.F"
    parameter max_curr = 16'hFFF0; //replace with maximum current threshold; 0xFFD0 = DEFAULT
    assign data = /*overflow ? 20'b10000111110000000000 :*/ curr_data; //display O.F or current
    assign interrupt = overflow ? 1 : 0; //INTERRUPT MOTOR CONTROL = 1

    
    //led visual dmm              
    always @(posedge(clk)) begin
   
        //if(xa_ready == 1'b1 && xa_channel == m_channel) begin
            //xa_data = raw_xa_data;
            
            case (xa_data[15:12])
            1:  led <= 16'b11;
            2:  led <= 16'b111;
            3:  led <= 16'b1111;
            4:  led <= 16'b11111;
            5:  led <= 16'b111111;
            6:  led <= 16'b1111111; 
            7:  led <= 16'b11111111;
            8:  led <= 16'b111111111;
            9:  led <= 16'b1111111111;
            10: led <= 16'b11111111111;
            11: led <= 16'b111111111111;
            12: led <= 16'b1111111111111;
            13: led <= 16'b11111111111111;
            14: led <= 16'b111111111111111;
            15: led <= 16'b1111111111111111;                        
            default: led <= 16'b1; 
            endcase
        end
    
    reg[15:0] peak_data = 0;
    
    //binary to decimal conversion
    always @ (posedge(clk)) begin
        case (state)
        S_IDLE: begin
            state <= S_FRAME_WAIT;
            count <= 'b0;
        end
        S_FRAME_WAIT: begin
            if(xa_data > peak_data)
                peak_data = xa_data;
            if (count >= 10000000) begin
                if (peak_data > 16'hFFD0) begin
                    curr_data <= 16'b0001000000000000; //1.00
                    state <= S_IDLE;
                end else begin
                    b2d_start <= 1'b1;
                    b2d_din <= peak_data;
                    state <= S_CONVERSION;
                end
                peak_data = 0;
            end else
                count <= count + 1'b1;
        end
        S_CONVERSION: begin
            b2d_start <= 1'b0;
            if (b2d_done == 1'b1) begin
                curr_data = b2d_dout;
                state <= S_IDLE;
            end
        end
        endcase
    end
    
    bin2dec m_b2d (
        .clk(clk),
        .start(b2d_start),
        .din(b2d_din),
        .done(b2d_done),
        .dout(b2d_dout)
    );
    
    
//HANDLING OF OVERFLOW AND LATCH
    always @(posedge(clk)) begin
        
        case(o_state)
            //NORMAL OPERATION OF MOTOR
            S_NORMAL: begin
                overflow <= 0;
                latchCount <= 0;
                overWait <= 0;
                if(xa_data > max_curr && !CURR_CTRL_EN) //ALLOW OVERFLOW IF CURRENT EXCEEDS MAX AND CURRENT CONTROL IS ENABLED
                    o_state <= S_SAMPLE;
            end
            //OVERFLOW DETECTED BUT SAMPLE TO BE SURE
            S_SAMPLE: begin
                overWait <= overWait + 1;
                if(overWait > wait_time && xa_data > max_curr && !CURR_CTRL_EN) //ALLOW OVERFLOW IF CURRENT EXCEEDS MAX AND CURRENT CONTROL IS ENABLED
                    o_state <= S_OVERFLOW;
				else if (overWait > wait_time)
					o_state <= S_NORMAL;
            end
            //OVERFLOW CONFIRMED AND HALT MOTOR
            S_OVERFLOW: begin
                overflow <= 1;
                
                latchCount <= latchCount + 1;
                if(latchCount > latch_time || CURR_CTRL_EN) //RETURN TO NORMAL IF OVER LATCH OR IF MODULE DISABLED
                    o_state <= S_NORMAL;
            end
        endcase
    end
    
endmodule