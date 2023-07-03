`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Boat Crew 5
// Engineer: Mark Dannemiller
// 
// Create Date: 03/02/2023 06:19:58 PM
// Design Name: 
// Module Name: ADC_HANDLER
// Project Name: Nautilus
// Target Devices: 
// Tool Versions: 
// Description: 
//
// This module handles sequencing the XADC channels and outputting the channel sequenced and the raw ADC data.
// ADC stands for analog-to-digital-conversion.  This module can handle a voltage reference between 0v and 1v
// and outputs the result in 16 bit resolution.  This means that the ADC could be used instead of comparators
// in your designs for current control or other voltage monitoring operations.
//
// This specific module monitors ALL ADC ports and outputs what channel it is currently monitoring so that outside
// modules can utilize whatever port they need.  Simply read the two links below and connect the XADC pins in the
// same way here or see the online Wiki on the ADC to use this module.
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

//ADC AUX channel 5
//https://digilent.com/reference/programmable-logic/basys-3/demos/xadc
//https://sites.google.com/a/umn.edu/mxp-fpga/home/vivado-notes/basys3-analog-to-digital-converter-xadc?pli=1
module ADC_HANDLER (
    input clk,
    input vauxp6, //JXADC[0] => Ch6 XA1_P
    input vauxn6, //JXADC[4] -> Ch6 XA1_N
    input vauxp7,
    input vauxn7,
    input vauxp14,
    input vauxn14,
    input vauxp15,
    input vauxn15,
    input vp_in,
    input vn_in,
    output wire [7:0] channel_out,
    
    output wire [15:0] xa_data,
    output reg [15:0] ch_6,
    output reg [15:0] ch_7,
    output reg [15:0] ch_14,
    output ready
    );
    
       
    wire xadc_en; //for adc to renable itself when finished sampling
    
    //CHANNELS : 6=16h, 7=17h, 14=1Eh, 15=1Fh
    localparam CH6 = 8'h16;
    localparam CH7 = 8'h17;
    localparam CH14 = 8'h1E;
    localparam CH15 = 8'h1F;
    
    localparam MULTIPLIER = 10000; //switch every 10,000 cycles, REMEMBER TO CHANGE BITS ON COUNTER
    
    reg [7:0] Address_in = CH6;
    reg[15:0] counter = 0;
    
    assign channel_out = Address_in; //output address for other modules to check
        
    //xadc instantiation connect the eoc_out .den_in to get continuous conversion
    xadc_wiz_0 CoolADCd (
        .daddr_in(Address_in),      // input wire [6 : 0] daddr_in
        .dclk_in(clk),              // input wire dclk_in
        .den_in(xadc_en),           // input wire den_in
        .di_in(0),                  // input wire9 [15 : 0] di_in
        .dwe_in(0),                 // input wire dwe_in
        .busy_out(),                // output wire busy_out
        .vauxp6(vauxp6),            // note since vauxn6, channel 6, is used  .daddr_in(ADC_ADDRESS), ADC_ADRESS = 16h, i.e., 010110 
        .vauxn6(vauxn6),            // note since vauxn6, channel 6, is used  .daddr_in(ADC_ADDRESS), ADC_ADRESS = 16h, i.e., 010110     
        .vauxp7(vauxp7),
        .vauxn7(vauxn7),
        .vauxp14(vauxp14),
        .vauxn14(vauxn14),
        .vauxp15(vauxp15),
        .vauxn15(vauxn15),
        .vn_in(vn_in), 
        .vp_in(vp_in),
        .alarm_out(),               // output wire alarm_out
        .do_out(xa_data),           // output wire [15 : 0] xa_data
        .eoc_out(xadc_en),          // output wire eoc_out
        .channel_out(),             // output wire [4 : 0] channel_out
        .drdy_out(ready)
    );
    
    //SEQUENCE EACH CHANNEL, IE SWITCH WHICH CHANNEL TO SAMPLE EVERY SO OFTEN
    always @(posedge clk) begin
        if(counter >= 4 * MULTIPLIER)
            counter = 0;
        
        counter = counter + 1;
        
        //CYCLE THROUGH EACH CHANNEL
        if(counter < MULTIPLIER)
            Address_in = CH6;
        else if(counter < 2 * MULTIPLIER)
            Address_in = CH7;
        else if(counter < 3 * MULTIPLIER)
            Address_in = CH14;
        else if(counter < 4 * MULTIPLIER)
            Address_in = CH15;
            
       
       //update each channel as an output
       if(ready) begin
            if(Address_in == CH6)
                ch_6 = xa_data;
            else if(Address_in == CH7)
                ch_7 = xa_data;
            else if(Address_in == CH14)
                ch_14 = xa_data;
       end
    
    end
endmodule
