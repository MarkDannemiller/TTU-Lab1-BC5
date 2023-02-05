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
    input an_pos_in, //JA[4]
    input an_neg_in, //JA[0]
    input clk,
    output interrupt,
    output [19:0] data
    );
    
    wire [15:0] do_out;  // ADC value; useful part are only [15:4] bits

    //wire [4:0] channel_out//;
    //assign led[4:0] = channel_out;
    //wire eoc_out;
    //assign led[5] = eoc_out;
    
    // instantiate IP XADC using IP Catatlog / FPGA Features and Design / XADC / XADC Wizard
    // BASIC TAB: DRP, Continuous Mode; Single Channel rest default
    // ADC Setup TAB: Seqencer Mode: Off; Channel Averaging: None; Enable CALIBRATION Averagin checked; (rest unchecked or default)
    // Alarms Tab:  Turn off all alarms
    // Single Channel Tab:  Slected Channel: VAUXP5 VAUXN5; Channel Enable: checked (rest un checked)
    ///----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG  THIS IS THE CONTINOUS MODE
    xadc_wiz_0 CoolADCd (
        //.di_in(di_in),              // input wire9 [15 : 0] di_in
        //.daddr_in(channel_out),        // input wire [6 : 0] daddr_in
        //.den_in(eoc_out),            // input wire den_in
        .dwe_in(1'b0),            // input wire dwe_in
        //.drdy_out(drdy_out),        // output wire drdy_out
        .do_out(do_out),            // output wire [15 : 0] do_out
        .dclk_in(clk),          // input wire dclk_in
        //.reset_in(sw[14]),        // input wire reset_in
        .vauxp5(analog_pos_in),            // note since vauxn5, channel 5, is used  .daddr_in(ADC_ADDRESS), ADC_ADRESS = 15h, i.e., 010101 
        .vauxn5(analog_neg_in)            // note since vauxn5, channel 5, is used  .daddr_in(ADC_ADDRESS), ADC_ADRESS = 15h, i.e., 010101     
        //.channel_out(channel_out),  // output wire [4 : 0] channel_out
        //.eoc_out(eoc_out),          // output wire eoc_out
        //.alarm_out(led[6]),      // output wire alarm_out
        //.eos_out(led[7]),         // output wire eos_out
        //.busy_out(led[8])        // output wire busy_out
    );
    
    reg [20:0] curr_data;
    
    //SET A MAXIMUM CURRENT THRESHOLD AND ASSIGN DATA TO EITHER THAT OR "O.F"
    parameter max_curr = 16'b1111111111111111; //replace with maximum current threshold
    assign data = (do_out >= max_curr) ? 20'b10000111110000000000 : curr_data;
    assign interrupt = (do_out >= max_curr) ? 1 : 0; //INTERRUPT MOTOR CONTROL = 1
    
    //CONVERT 
    wire [15:0] convert_out;
    wire done;
    bin2dec convert(clk, 1'b1, do_out, convert_out);
    
    //UPDATE CURRENT DATA WHEN CONVERT IS COMPLETE
    always @(posedge done) begin
        curr_data[19] = 1'b1;
        curr_data[18:15] = 4'h3;//convert_out[15:12];
        curr_data[14] = 1'b1;
        curr_data[13:10] = 4'h3;//convert_out[11:8];
        curr_data[9] = 1'b1;
        curr_data[8:5] = 4'h3;//convert_out[7:4];
        curr_data[4] = 1'b1;
        curr_data[3:0] = 4'hA; //A=amps
    end
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

/*module CURR_TO_HEX (
    input [11:0] value,
    output [19:0] data
);

assign data[19] = 1'b1; //to enable 7-seg
//assign data[18:14]

assign data[19] = 0;
assign data[15] = value[11] & value[10] value[9] & value[8] //1 or 0
                        & value[7] & value[6] &value[5] & value[4]
                        & value[3] & value[2] & value[1] & value[0];

assign data[4:0] = 5'hA; //A stands for amps


endmodule*/
