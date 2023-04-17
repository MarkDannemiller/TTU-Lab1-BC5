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


module DATA_HANDLER (
    input [19:0] data,      //5 bits per display, MSB enable with 4 bits for hex code
    input clk,
    input [15:0] battery_data,
    //input [3:0] display_en,
    input [3:0] dpEnable,   //decimal point enable for each display
    output [6:0] segPorts,   //ports corresponding to each segment (all displays share these ports)
    output dpPort,
    output [3:0] anode      //specifies which of the 4 displays to be temp turned on while cycling
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
	assign seg_data = (digit_select ==  2'b00 ) ? data[4:0]:
							 (digit_select ==  2'b01 ) ? data[9:5]:
							 (digit_select ==  2'b10 ) ? data[14:10]:
							 (digit_select ==  2'b11 ) ? data[19:15]:
							 4'b1111;
							 
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
