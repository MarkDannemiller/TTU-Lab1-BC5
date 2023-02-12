`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2023 12:07:17 AM
// Design Name: 
// Module Name: CURR_CTRL
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

//ADC AUX channel 5
//https://digilent.com/reference/programmable-logic/basys-3/demos/xadc
//https://sites.google.com/a/umn.edu/mxp-fpga/home/vivado-notes/basys3-analog-to-digital-converter-xadc?pli=1
module CURR_CTRL(
    input CURR_CTRL_EN, //OFF/0 = EN
    input direction,
    input an_pos_in, //JXADC[0] => Ch6 XA1_P
    input an_neg_in, //JXADC[4] -> Ch6 XA1_N
    input vauxp7,
    input vauxn7,
    input vauxp14,
    input vauxn14,
    input vauxp15,
    input vauxn15,
    input vp_in,
    input vn_in,
    input wire [7:0] channel_out,
    input clk,
    output interrupt,
    output [19:0] data,
    output reg [15:0] led
    );
    
    wire [15:0] xa_data;  // ADC value; useful part are only [15:4] bits
    wire xadc_en; //for adc to renable itsefl when finished sampling
    wire ready;
    
    reg [6:0] Address_in; //
    
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
    reg [19:0] curr_data;
    
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
    assign data = overflow ? 20'b10000111110000000000 : curr_data; //display O.F or current
    assign interrupt = overflow ? 1 : 0; //INTERRUPT MOTOR CONTROL = 1
    
    //xadc instantiation connect the eoc_out .den_in to get continuous conversion
    xadc_wiz_0 CoolADCd (
        .daddr_in(Address_in),        // input wire [6 : 0] daddr_in
        .dclk_in(clk),          // input wire dclk_in
        .den_in(xadc_en),            // input wire den_in
        .di_in(0),              // input wire9 [15 : 0] di_in
        .dwe_in(0),            // input wire dwe_in
        .busy_out(),        // output wire busy_out
        .vauxp6(an_pos_in),            // note since vauxn6, channel 6, is used  .daddr_in(ADC_ADDRESS), ADC_ADRESS = 16h, i.e., 010110 
        .vauxn6(an_neg_in),            // note since vauxn6, channel 6, is used  .daddr_in(ADC_ADDRESS), ADC_ADRESS = 16h, i.e., 010110     
        .vauxp7(vauxp7),
        .vauxn7(vauxn7),
        .vauxp14(vauxp14),
        .vauxn14(vauxn14),
        .vauxp15(vauxp15),
        .vauxn15(vauxn15),
        .vn_in(vn_in), 
        .vp_in(vp_in),
        .alarm_out(),      // output wire alarm_out
        .do_out(xa_data),            // output wire [15 : 0] xa_data
        .eoc_out(xadc_en),          // output wire eoc_out
        .channel_out(),  // output wire [4 : 0] channel_out
        .drdy_out(ready)
    );
    
    //led visual dmm              
    always @(posedge(clk)) begin            
        if(ready == 1'b1) begin
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
    end
    
    //binary to decimal conversion
    always @ (posedge(clk)) begin
        case (state)
        S_IDLE: begin
            state <= S_FRAME_WAIT;
            count <= 'b0;
        end
        S_FRAME_WAIT: begin
            if (count >= 10000000) begin
                if (xa_data > 16'hFFD0) begin
                    curr_data[19:5] <= 20'b100011000010000; //1.00
                    curr_data[4] <= 1'b1;
                    curr_data[3:0] <= direction ? 4'hF : 4'hB; //1.00F | 1.00B
                    state <= S_IDLE;
                end else begin
                    b2d_start <= 1'b1;
                    b2d_din <= xa_data;
                    state <= S_CONVERSION;
                end
            end else
                count <= count + 1'b1;
        end
        S_CONVERSION: begin
            b2d_start <= 1'b0;
            if (b2d_done == 1'b1) begin
                curr_data[19] <= 1'b1;
                curr_data[18:15] <= b2d_dout[15:12];
                curr_data[14] <= 1'b1;
                curr_data[13:10] <= b2d_dout[11:8];
                curr_data[9] <= 1'b1;
                curr_data[8:5] <= b2d_dout[7:4];
                curr_data[4] <= 1'b1;
                curr_data[3:0] <= direction ? 4'hF : 4'hB; //display forward or backward
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
        Address_in <= channel_out; // 16=XA1/AD6 1e=14
        
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