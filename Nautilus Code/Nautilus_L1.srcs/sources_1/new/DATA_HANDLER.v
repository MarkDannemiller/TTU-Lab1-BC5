`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2023 12:07:17 AM
// Design Name: 
// Module Name: DISPLAY
// Project Name: NAUTILUS_L1
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

/**
* THIS MODULES DUTY IS TO DISPLAY DATA ON THE 7 SEGMENT AND SEND DATA TO THE ESP32 VIA I2C
* This module also serves as an updater of constant data for items like rover speed, detection distance, etc for live updating the device
**/
module DATA_HANDLER (
    input [19:0] data,      //5 bits per display, MSB enable with 4 bits for hex code
    input clk,
    //input [3:0] display_en,
    input [3:0] dpEnable,   //decimal point enable for each display
    output [6:0] segPorts,   //ports corresponding to each segment (all displays share these ports)
    output dpPort,
    output [3:0] anode,      //specifies which of the 4 displays to be temp turned on while cycling
    
    //20 BYTES OF BASYS DATA TO SEND TO ESP
    input [7:0] battery_volts,      //val_0
    input [7:0] curr_left,          //val_1
    input [7:0] curr_right,         //val_2
    input [7:0] ips_state,          //val_3
    input [7:0] pdu_state,          //val_4
    input [7:0] us_dist_front,      //val_5
    input [7:0] us_dist_back,       //val_6
    input [7:0] process_stream_1,   //val_7
    input [7:0] process_stream_2,   //val_8
    input [7:0] process_stream_3,   //val_9
    input [7:0] decoded_val,        //val_10
    input [7:0] flags,              //val_11
    input [7:0] val_12,             //val_12
    input [7:0] val_13,             //val_13
    input [7:0] val_14,             //val_14
    input [7:0] val_15,             //val_15
    input [7:0] val_16,             //val_16
    input [7:0] val_17,             //val_17
    input [7:0] val_18,             //val_18
    input [7:0] val_19,             //val_19
        
    
    //I2C pins
    inout sda,
    //inout scl
    input scl
    );
    
    wire[159:0] basys_data;
    wire[159:0] esp_data;
    
    //ASSIGN ALL 20 BYTES OF BASYS DATA FOR FEEDING INTO ESP
    assign basys_data[7:0] = battery_volts;
    assign basys_data[(1+1)*8-1:(1)*8] = curr_left;
    assign basys_data[(2+1)*8-1:(2)*8] = curr_right;
    assign basys_data[(3+1)*8-1:(3)*8] = ips_state;
    assign basys_data[(4+1)*8-1:(4)*8] = pdu_state;
    assign basys_data[(5+1)*8-1:(5)*8] = us_dist_front;
    assign basys_data[(6+1)*8-1:(6)*8] = us_dist_back;
    assign basys_data[(7+1)*8-1:(7)*8] = process_stream_1;
    assign basys_data[(8+1)*8-1:(8)*8] = process_stream_2;
    assign basys_data[(9+1)*8-1:(9)*8] = process_stream_3;
    assign basys_data[(10+1)*8-1:(10)*8] = decoded_val;
    assign basys_data[(11+1)*8-1:(11)*8] = 8'hAA;//flags;
    assign basys_data[(12+1)*8-1:(12)*8] = 8'hAB;// val_12;
    assign basys_data[(13+1)*8-1:(13)*8] = val_13;
    assign basys_data[(14+1)*8-1:(14)*8] = val_14;
    assign basys_data[(15+1)*8-1:(15)*8] = val_15;
    assign basys_data[(16+1)*8-1:(16)*8] = val_16;
    assign basys_data[(17+1)*8-1:(17)*8] = val_17;
    assign basys_data[(18+1)*8-1:(18)*8] = val_18;
    assign basys_data[(19+1)*8-1:(19)*8] = 8'hEE; //val_19;
    
    wire[10:0] bitcount; //debug
    
    I2C_COMMS esp_comms (
    .CLCK(clk), 
    .SCL(scl),
    .SDA(sda),
    .basys_data(basys_data),
    .esp_data(esp_data),
    .bitcount(bitcount)
    );
    
    
    //Cycle clock to display data to each of the 4 displays
    //For a decent test, change to 2.  For FPGA, change to 16
    parameter CLKBIT = 16;
    reg [CLKBIT:0] clk_div = 0;
    always @(posedge clk) begin
		clk_div <= clk_div + 1;	
	end 
	
	wire [1:0] digit_select; //used to select 1 of 4 displays
	assign digit_select = clk_div[CLKBIT:CLKBIT-1]; //use two MSB to select digits
	
	//now multiplex, i.e., send alternate 1 bit enable and 4 bits of the input value to the display
	wire [4:0] seg_data;	
	/*assign seg_data = (digit_select ==  2'b00 ) ? data[4:0]:
							 (digit_select ==  2'b01 ) ? data[9:5]:
							 (digit_select ==  2'b10 ) ? data[14:10]:
							 (digit_select ==  2'b11 ) ? data[19:15]:
							 4'b1111;*/
    ////////////////////////////////////////////////
	assign seg_data[3:0] = (digit_select ==  2'b00 ) ? esp_data[3:0]:
							 (digit_select ==  2'b01 ) ? esp_data[7:4]:
							 (digit_select ==  2'b10 ) ? bitcount[7:4]:
							 (digit_select ==  2'b11 ) ? bitcount[3:0]:
							 4'b111;
	assign seg_data[4] = 1;
	///////////////////////////////////////////////						 
    ENABLE_DIGIT M_EnableDigit(digit_select, anode);
    SEVEN_SEG M_Seg(seg_data[3:0], seg_data[4], dpEnable[digit_select], segPorts, dpPort);
    endmodule


/*
https://sites.google.com/a/umn.edu/mxp-fpga/home/vivado-notes/phys4051-course-related-fpga-documents-and-verilog-code?authuser=0
Module take 4 bit binary value and displays its value in hex on a 7-seg display
args:   value = 4 bit value to display
        en = unit enable
        segOut = 7-segment encoding of hex value
        
          0
         ---
      5 |   | 1
         --- <--6
      4 |   | 2
         ---
          3
          
 Display Pin Outs:
		The pins for the 7 bit "sevenSegOut" must be assigned with a "synthesis attribute" statement and they correspond
		to pins: "P83 P17 P20 P21 P23 P16 P25" 
*/
module SEVEN_SEG (
    input [3:0] value, //HEX NUM TO DISPLAY
    input en, //HIGH=ENABLE DISPLAY, LOW=DISABLE DISPLAY
    input dpData,
    output [6:0] segOut,
    output dpOut
    );
    
    assign segOut =  ((value == 4'b0000)& en) ? 7'b1000000:   // 1
								 ((value == 4'b0001)& en) ? 7'b1111001:   // 1
								 ((value == 4'b0010)& en) ? 7'b0100100:   // 2
								 ((value == 4'b0011)& en) ? 7'b0110000:   // 3
								 ((value == 4'b0100)& en) ? 7'b0011001:   // 4
								 ((value == 4'b0101)& en) ? 7'b0010010:   // 5
								 ((value == 4'b0110)& en) ? 7'b0000010:   // 6
								 ((value == 4'b0111)& en) ? 7'b1111000:   // 7
								 ((value == 4'b1000)& en) ? 7'b0000000:   // 8
								 ((value == 4'b1001)& en) ? 7'b0010000:   // 9
								 ((value == 4'b1010)& en) ? 7'b0001000:   // A
								 ((value == 4'b1011)& en) ? 7'b0000011:   // b
								 ((value == 4'b1100)& en) ? 7'b1000110:   // C
								 ((value == 4'b1101)& en) ? 7'b0100001:   // d
								 ((value == 4'b1110)& en) ? 7'b0000110:   // E
								 ((value == 4'b1111)& en) ? 7'b0001110:   // F
								 7'b1111111;   // default i.e. all segments off!
	assign dpOut = ~dpData; //inverted for clarity so that 1=HIGH
endmodule




//Module takes a 2 bit binary input value and enables one of the four 7-segment displays.
//
// Arguments:
//		Input: "digitSelectIn" a 2 bit value which enables one of the four display digits, with 0 
//				corresponding to the rightmost one, and 3 to the leftmost.
//		Output: "digSelectOut" the 4 bit value corresponding to "digitSelectIn" that turns only
//				one of the 4 displays on by setting its corresponding anode pin low.
//
// Display Pin Outs:
//		The pins to turn a digit on or off must be assigned with a "synthesis attribute" statement and they correspond
// 	to pins: "P26  P32 P33 P34"
module ENABLE_DIGIT( digitSelectIn, digSelectOut);
	input [1:0] digitSelectIn; //0 is right most digit, 1 is 2nd rightmost etc, 3 is leftmost
	output [3:0] digSelectOut; //digit selections to turn individual digit (anodes) on or off	
	assign digSelectOut = (digitSelectIn == 2'b00) ? 4'b1110:   // right most digit
								 (digitSelectIn == 2'b01) ? 4'b1101:   // 2nd right most digit
								 (digitSelectIn == 2'b10) ? 4'b1011:   // 3rd right most digit
								 (digitSelectIn == 2'b11) ? 4'b0111:   // left most digit
								 4'b0000;   //DEFAULT: enable all digits
      
			
endmodule
