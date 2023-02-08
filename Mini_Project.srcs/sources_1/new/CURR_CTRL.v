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
    input an_pos_in, //JXADC[0] => Ch6 XA1_P
    input an_neg_in, //JXADC[4] -> Ch6 XA1_N
    input wire [6:0] channel_out,
    input clk,
    output interrupt,
    output [19:0] data
    );
    
    wire [15:0] do_out;  // ADC value; useful part are only [15:4] bits
    wire xadc_en; //for adc to renable itsefl when finished sampling
    
    //binary to decimal converter signals
    reg [32:0] count;
    reg b2d_start;
    reg [15:0] b2d_din;
    wire b2d_done;
    wire [15:0] convert_out;
    
    //STATES FOR CONVERSION OUTPUT
    localparam S_IDLE = 0;
    localparam S_FRAME_WAIT = 1;
    localparam S_CONVERSION = 2;
    reg [1:0] state = S_IDLE;
    
    // instantiate IP XADC using IP Catatlog / FPGA Features and Design / XADC / XADC Wizard
    // BASIC TAB: DRP, Continuous Mode; Single Channel rest default
    // ADC Setup TAB: Seqencer Mode: Off; Channel Averaging: None; Enable CALIBRATION Averagin checked; (rest unchecked or default)
    // Alarms Tab:  Turn off all alarms
    // Single Channel Tab:  Slected Channel: VAUXP5 VAUXN5; Channel Enable: checked (rest un checked)
    ///----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG  THIS IS THE CONTINOUS MODE
    xadc_wiz_0 CoolADCd (
        .di_in(1'b0),              // input wire9 [15 : 0] di_in
        .daddr_in(channel_out),        // input wire [6 : 0] daddr_in
        .den_in(xadc_en),            // input wire den_in
        .dwe_in(1'b0),            // input wire dwe_in
        //.drdy_out(drdy_out),        // output wire drdy_out
        .do_out(do_out),            // output wire [15 : 0] do_out
        .dclk_in(clk),          // input wire dclk_in
        //.reset_in(sw[14]),        // input wire reset_in
        .vauxp6(analog_pos_in),            // note since vauxn6, channel 6, is used  .daddr_in(ADC_ADDRESS), ADC_ADRESS = 16h, i.e., 010110 
        .vauxn6(analog_neg_in),            // note since vauxn6, channel 6, is used  .daddr_in(ADC_ADDRESS), ADC_ADRESS = 16h, i.e., 010110     
        .channel_out(),  // output wire [4 : 0] channel_out
        .eoc_out(xadc_en),          // output wire eoc_out
        .alarm_out(),      // output wire alarm_out
        //.eos_out(led[7]),         // output wire eos_out
        .busy_out()        // output wire busy_out
    );
    
    reg [20:0] curr_data;
    
    //SET A MAXIMUM CURRENT THRESHOLD AND ASSIGN DATA TO EITHER THAT OR "O.F"
    parameter max_curr = 16'hFFD01; //replace with maximum current threshold; 0xFFD01 = 1.0V/A
    assign data = (do_out >= max_curr) ? 20'b10000111110000000000 : curr_data;
    assign interrupt = (do_out >= max_curr) ? 1 : 0; //INTERRUPT MOTOR CONTROL = 1
    
    
    //binary to decimal conversion
    always @ (posedge(clk)) begin
        case (state)
        S_IDLE: begin
            state <= S_FRAME_WAIT;
            count <= 1'b0;
        end
        S_FRAME_WAIT: begin
            if (count >= 10000000) begin
                if (do_out > 16'hFFD0) begin
                    curr_data <= 20'b10001100001000011010; //1.00A
                    state <= S_IDLE;
                end else begin
                    b2d_start <= 1'b1;
                    b2d_din <= do_out;
                    state <= S_CONVERSION;
                end
            end else
                count <= count + 1'b1;
        end
        S_CONVERSION: begin
            b2d_start <= 1'b0;
            if (b2d_done == 1'b1) begin
                curr_data[19] <= 1'b1;
                curr_data[18:15] <= convert_out[15:12];
                curr_data[14] <= 1'b1;
                curr_data[13:10] <= convert_out[11:8];
                curr_data[9] <= 1'b1;
                curr_data[8:5] <= convert_out[7:4];
                curr_data[4] <= 1'b1;
                curr_data[3:0] <= convert_out[3:0];//4'hA; //A=amps
                state <= S_IDLE;
            end
        end
        endcase
    end
    
    //bin2dec convert(clk, 1'b1, do_out, convert_out);
    
    bin2dec m_b2d (
        .clk(clk),
        .start(b2d_start),
        .din(b2d_din),
        .done(b2d_done),
        .dout(convert_out)
    );
endmodule

// Tool Versions: Vivado 2016.4
// Description: converts an input in the range (0x0000-0xFFFF) to a hex string in the range (16'h0000-16'h1000)
//              assert start & din, some amount of time later, done is asserted with valid dout
// Dependencies: none
// 
// 03/23/2017(ArtVVB): Created
//
//////////////////////////////////////////////////////////////////////////////////

module bin2dec (
    input clk,
    input start,
    input [15:0] din,
    output done,
    output reg [15:0] dout
);
    //{0x0000-0xFFFF}->{"0000"-"1000"} 
    localparam  S_IDLE=0,
                S_DONE=1,
                S_DIVIDE=2,
                S_NEXT_DIGIT=3,
                S_CONVERT=4;
    reg [2:0] state=S_IDLE;
    reg [31:0] data;
    reg [31:0] div;
    reg [3:0] mod;
    reg [1:0] byte_count;
    
    assign done = (state == S_IDLE || state == S_DONE) ? 1 : 0;
    
    always@(posedge clk)
        case (state)
        S_IDLE: begin
            if (start == 1) begin
                state <= S_DIVIDE;
                data <= ({16'b0, din} * 1000) >> 16;
                byte_count <= 0;
            end
        end
        S_DONE: begin
            if (start == 0)
                state <= S_IDLE;
        end
        S_DIVIDE: begin
            div <= data / 10;
            mod <= data % 10;
            state <= S_CONVERT;
        end
        S_NEXT_DIGIT: begin
            if (byte_count == 3)
                state <= S_DONE;
            else
                state <= S_DIVIDE;
            data <= div;
            byte_count <= byte_count + 1;
        end
        S_CONVERT: begin
            dout[11:0] <= dout[15:4];
            dout[15:12] <= mod[3:0];
            state <= S_NEXT_DIGIT;
        end
        default: begin
            state <= S_IDLE;
        end
        endcase
    
endmodule
