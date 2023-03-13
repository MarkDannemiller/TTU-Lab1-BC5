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


/*
KEY CONCEPTS:
1 = DOT
111 = DASH
0 = PERIOD BETWEEN UNITS
000 = END CHARACTER

In this module, data is processed from the IR receiver into a bit stream.  Each bit is measured in time
and entered into a time register such that any random noise can be filtered out
*/

module IR_INPUT(

input enable,
input clk,
input IR_Pin,
output LED,
output reg overflow
    );
assign LED = IR_Pin;

localparam true = 1;
localparam false = 0;
localparam START_CHAR_MS = 180;
localparam UNIT_THRESHOLD = 0.75; //MIN AMOUNT OF TIME A UNIT WAS PROCESSED FOR IT TO BE CONSIDERED ACCURATE
localparam CHAR_MS = 60; //60 MS IS EXPECTED PER CHARACTER

reg start;
reg reset;
reg found_start_char; //reg storing bool value of whether start character is found

reg[59:0] bitstream; //stream of data that should only ever be 20 units of data long before end character
reg incoming_bit;
reg[59:0] new_val;

//DECODER VALUES
reg[59:0] process_stream; //stream that will only update when full stream is processed and sent to decoder
//reg[471:0] timestream;
reg decode_en;

reg[5:0] bit_index;

//255ms max time per bit accounts for a maximum of 4 units (0.06s)*4=240ms observed which accounts for dashes and start/end strings
//reg[471:0] timestream; //time in ms each on/off bit was observed (60 bit slots * 240ms each)
reg[16:0] ms_counter; //counter that counts to 1ms
reg[7:0] ms_timer; //timer that counts up to 255ms maximum

reg[8:0] time_index;


initial begin
    bitstream <= 60'b0;
    process_stream <= 60'b0;
    //timestream = 472'b0;
    bit_index <= 0;
    time_index <= 0;
    start <= false;
    reset <= false;
    decode_en <= 0;
end

always@(posedge clk) begin

    //disable module and reset registers
    if(!enable) begin
        bitstream = 60'b0;
        //timestream = 472'b0;
        start = false;
    end
    //IF ENABLED, PROCESS IR MORSE CODE
    else begin
        //ONLY START PROCESSING ONCE IR IS DETECTED. I.E: DETECTING OFF FOR A LONG TIME IS NOT THE BEGINNING
        //ALSO RESTARTS UPON RESET
        if((IR_Pin == 1 && !start) || reset) begin
            start <= true;
            reset <= false;
            incoming_bit <= IR_Pin;
            ms_counter <= 0;
            ms_timer <= 0;
            bit_index <= 0;
            time_index <= 0;
            found_start_char <= 0;
            overflow <= false;
        end
        if(start) begin
            //TRACK MS TIME THAT ON BIT HAS BEEN RECEIVED
            ms_counter = ms_counter + 1;
            if(ms_counter > 999) begin
                ms_timer = ms_timer + 1; //increment in ms
                ms_counter = 0;
            end

            //IF IR HAS CHANGED
            if(incoming_bit != IR_Pin) begin
                //program monitors until finding start bit
                if(!found_start_char && incoming_bit == 0) begin
                    found_start_char <= true;
                end
                else if(found_start_char) begin
                    //the case that the start/end character was found
                    if(incoming_bit == 0 && ms_timer > START_CHAR_MS * UNIT_THRESHOLD) begin
                        reset <= true;
                        process_stream <= bitstream;
                    end
                    else begin
                        //was 1 processed?
                        if(ms_timer >= UNIT_THRESHOLD * CHAR_MS && ms_timer < UNIT_THRESHOLD* CHAR_MS *2) begin
                            //overflow condition
                            if(bit_index > 59) begin
                                overflow <= true;
                            end
                            
                            //new_val is 1 or 0
                            new_val = incoming_bit << bit_index; //shift incoming bit to correct position in 60 bit array
                            bit_index = bit_index + 1;
                        end
                        //or was 11 processed? (shouldn't be)
                        else if (ms_timer >= UNIT_THRESHOLD * CHAR_MS * 2 && ms_timer < UNIT_THRESHOLD * CHAR_MS *2) begin
                            //overflow condition
                            if(bit_index + 1 > 59) begin
                                overflow <= true;
                            end
                            
                            //new_val is 11 or 00
                            new_val = (incoming_bit << bit_index) | (incoming_bit << bit_index+1);
                            bit_index = bit_index + 2;
                        end
                        //or was 111 processed? (dash case)
                        else if(ms_timer >= UNIT_THRESHOLD * CHAR_MS * 3) begin
                            //overflow condition
                            if(bit_index + 2 > 59) begin
                                overflow <= true;
                            end
                            
                            //new_val is 111 or 000 (note, 000 should have been caught as an end character)
                            new_val = (incoming_bit << bit_index) | (incoming_bit << bit_index+1) | (incoming_bit << bit_index+2);
                            bit_index = bit_index + 2;
                        end
                        //otherwise the bit that was processed was too short
                        else begin
                            new_val = 60'b0;
                        end
                        
                         bitstream = bitstream | new_val;
                    end
                end
            end
            incoming_bit = IR_Pin;
        end
    end
end

endmodule


module MORSE_DECODER (input enable, input[59:0] bitstream, output ready, output [3:0] out);


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

