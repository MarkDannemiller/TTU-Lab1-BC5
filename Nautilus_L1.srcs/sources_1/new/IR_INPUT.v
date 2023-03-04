`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2023 06:19:58 PM
// Design Name: 
// Module Name: IR_INPUT
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


module IR_INPUT(

input clk,
input IR_Pin,
output LED
    );
assign LED = IR_Pin; 
endmodule

/**
@Author: Silas Rodriguez
@Date: 3/1/2023
@Description: This module is used to receive morse code for 20 WPM, use a 100MHz clock from the BASYS3 board change period if otherwise: char_period = 1.2/WPM 
              period = char_period * clk_freq
@Inputs: clk, ir, res -> clock, input from infrared, reset signal
@Outputs: morse_char -> character received from morse code -> needs to be decoded by another module and then converted to printable format
@Notes: If the timing appears off, or the character is not decoded correctly, change the period value to the correct value + Nonblocking assignment to blocking assignment (<= to =)
        Morse code behaves similarly to serial communication, so this module is similar to a serial reciever, this start bit sequence needs to be known to the reciever and the sender + implimented in the code
        This module is not a complete morse code reciever, it only recieves the morse code and stores it in an array, it does not decode the morse code
*/
module morse_receiver (
    input clk,
    input ir,
    input res,
    output reg [21:0] morse_char //array of 22 bits to store the morse code (0 being longest) -> 5 dash = 15 periods + 4 breaks (1 period ea) + 3 terminate bits (1period ea) = 22 periods
);
    
    localparam period = 6000000; //period per unit of time -> morse code with 100 MHz clock
    localparam letter_space = 3'B000;    //important that this number is 000 for spaces
    localparam word_space = 7'B0000000; //important that this number is 0000000 for spaces

    reg [22:0] counter;     //counter for the clock
    reg [21:0] i;            //counter for morse_char array | this could be declared single line
    reg [21:0] char_buffer;  //buffer for the character

    //assume a clock ~ 100 MHz
    always @(posedge clk) begin
        if (res) begin
            counter <= 0;
            i <=0;
            morse_char <= 0;
            char_buffer <= 0;
        end
        else begin
            //increment counter + sample ir waveform
            counter <= counter + 1;
            if (counter >= period) begin
                counter <= 0;   //reset counter
                //update buffer
                char_buffer[21-i] <= ir;
                i <= i + 1;
            end
            //if char seperator or word separator exists, process char_buffer
            if (i>=2 && char_buffer[21-i+2:21-i] == letter_space) begin //checks current pointer of i and the previous read ins
                //process char_buffer to morse_char and reset i and char_buffer to 0
                morse_char <= char_buffer;
                i <= 0;
                char_buffer <= 0;
            end
            //if word seperator exists, process char_buffer
            else if (i>=6 && char_buffer[21-i+6:21-i] == word_space) begin
                //process char_buffer to morse_char and reset i and char_buffer to 0
                morse_char <= char_buffer;
                i <= 0;
                char_buffer <= 0;
            end
        end
    end
endmodule

/**
@Author: Silas Rodriguez
@Date: 3/3/2023
@Description: This module is used to decode morse code from the morse_reciever module
@Inputs: clk, morse_char -> clock, morse code character received from morse_reciever module
@Outputs: morse_char_decoded -> decoded character from morse code to be used by other 7 segment display modules or displayed in some other ways (customizable via bits)
@Notes: The inputs are mapped in binary for how the numbers are expected to be displayed at the receiver (draw waveforms to see how the bits are mapped)
*/
module morse_decoder (
    input clk,
    input [21:0] morse_char,
    output reg [7:0] morse_char_decoded
);
    always @(posedge clk) begin
        case(morse_char)
        //1
        22'b0000000000000000000000: morse_char_decoded = 8'b00000001; //1
        //2
        22'b0000000000000000000001: morse_char_decoded = 8'b00000010; //2
        //3
        22'b0000000000000000000011: morse_char_decoded = 8'b00000100; //3
        //4
        22'b0000000000000000000111: morse_char_decoded = 8'b00001000; //4
        //5
        22'b0000000000000000001111: morse_char_decoded = 8'b00010000; //5
        //6
        22'b0000000000000000011111: morse_char_decoded = 8'b00100000; //6
        //7
        22'b0000000000000000111111: morse_char_decoded = 8'b01000000; //7
        //8
        22'b0000000000000001111111: morse_char_decoded = 8'b10000000; //8
        //9
        22'b0000000000000011111111: morse_char_decoded = 8'b00000011; //9
        //0
        22'b0000000000000111111111: morse_char_decoded = 8'b00000110; //0
        //assuming a word space was processed if none of the character spaces were processed
        default:
            morse_char_decoded = 8'b00000000;   //output a space? something else?
        endcase
    end
endmodule

/*
    Insert the seven seg / printing module here
*/

