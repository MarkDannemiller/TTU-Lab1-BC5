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
output reg overflow,
output [3:0] value
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
                        else if (ms_timer >= UNIT_THRESHOLD * CHAR_MS * 2 && ms_timer < UNIT_THRESHOLD * CHAR_MS * 3) begin
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
                            bit_index = bit_index + 3;
                        end
                        //otherwise the bit that was processed was too short; bit index remains the same and the program will try again with the next bit
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

/**
* MODULE THAT DECODES A 13b-15b MORSE BITSTREAM TO 1, 2, OR 3.
* IMPLEMENTS ONE OF TWO PROCESSES BASED ON WHETHER INCOMING STREAM PERFECTLY MATCHES ONE OF THE THREE MORSE VALUES
* IF STREAM DOES NOT PERFECTLY MATCH, ATTEMPTS TO INTERPOLATE BASED ON NUMBER OF DOTS AND DASHES EXPECTED
* IF STREAM SIZE IS NOT COMPARABLE TO ANY NUMBER OR IF BIT STREAMS ARE NONSENSE, RETURNS FALSE/0
* 
**/
module MORSE_DECODER (input enable, input clk, input[59:0] bitstream, 
                      output reg ready, output reg fallback, output reg dot_match, output reg dash_match, 
                      output reg [3:0] out);

    localparam true = 1;
    localparam false = 0;
    localparam ONE = 16'b11101110111011101; //10111011101110111; //IN READING ORDER
    localparam TWO = 14'b111011101110101; //101011101110111; //READING ORDER L->R
    localparam THREE = 12'b1110111010101; //1010101110111; //READING ORDER L->R

    localparam ONE_SIZE = 10'd16;
    localparam TWO_SIZE = 10'd14;
    localparam THREE_SIZE = 10'd12;

    reg[7:0] shift_counter;
    reg[4:0] one_counter;
    reg[4:0] dot_counter;
    reg[4:0] dash_counter;

    reg[59:0] temp_stream;

    reg[4:0] compare_dot;
    reg[4:0] compare_dash;
    reg[9:0] compare_separator; //separation value from ones and dashes
    reg[9:0] stream_end_val; //index of the end stream
    
    reg enable_last;

    always@(posedge clk) begin

        //SET DECODE BACK TO READY WHEN MODULE HAS BEEN ENABLED AND PREVIOUS DECODE HAS COMPLETED
        if(enable && ready && enable != enable_last) begin
            ready <= false;
            temp_stream <= bitstream;
            one_counter <= 5'b0;
            dot_counter <= 5'b0;
            dash_counter <= 5'b0;
            shift_counter <= 8'b0;
            
            enable_last = enable;

                            
            //SET NUMBER OF DASHES/DOTS TO COMPARE TO FOR FALLBACK DECODING PROCESS
            if(bitstream[18:16] == 3'b000) begin
                    compare_dash <= 5'd04;
                    compare_dot <= 5'd01;
                    compare_separator <= 10'd01; //EXPECTED INDEX TO SWITCH FROM DOTS TO DASHES
                    stream_end_val <= ONE_SIZE;
            end
            else if(bitstream[17:15] == 3'b000) begin
                    compare_dash <= 5'd03;
                    compare_dot <= 5'd02;
                    compare_separator <= 10'd03;
                    stream_end_val <= TWO_SIZE;
            end
            else if(bitstream[15:13] == 3'b000) begin
                    compare_dash <= 5'd02;
                    compare_dot <= 5'd03;
                    compare_separator <= 10'd05;
                    stream_end_val <= THREE_SIZE;
            end
            //IF STREAM DOES NOT MATCH LENGTH OF ANY KNOWN NUMBER
            else begin
                    ready = true;
                    out = false; //0=false=NOT FOUND
                    fallback = true;
            end
        end

        if(enable && !ready) begin
            //TO BEGIN, CHECK AGAINST PERFECT CASES
            if (bitstream[15:0] == ONE) begin
                out = 4'd1;
                ready = true;
                fallback = false;
                dot_match = true;
                dash_match = true;
            end
            else if (bitstream[14:0] == TWO) begin
                out = 4'd2;
                ready = true;
                fallback = false;
                dot_match = true;
                dash_match = true;
            end
            else if (bitstream[12:0] == THREE) begin
                out = 4'd3;
                ready = true;
                fallback = false;
                dot_match = true;
                dash_match = true;
            end
            //IF NO PERFECT CASE WAS FOUND, GUESS AGAINST NUMBER OF DASHES/DOTS RECEIVED (FALLBACK DECODING MODE)
            else begin
                fallback = true; //trigger such that upper modules know that fallback was hit

                //BEGIN BY CHECKING FOR A SINGLE ERRONEOUS BIT BASED ON BITSTREAM LENGTH (WILL CHECK IF DASHES ARE CORRECT, THEN DOTS)
                if(temp_stream[0] == 1 || shift_counter != compare_separator) begin
                    one_counter = one_counter + 1;
                end
                //DECIPHER STREAM OF ONES WHEN 0 IS ENCOUNTERED
                else begin
                    //CASE WHEN DASHES APPEAR NORMAL OR BIGGER BETWEEN 3->6 ONES LONG (IF A DASH IS 5 ONES LONG, THEN THE RESULT SHOULD NOT OCCUR BASED ON DASHES)
                    if(one_counter > 2 && one_counter < 7 && shift_counter > compare_separator) begin
                        dash_counter = dash_counter + 1;
                    end
                    //CASE WHEN AN EXTRA 1 WAS READ EX: (11101110111011111)
                    else if((one_counter == 1 || one_counter == 2) && shift_counter <= compare_separator) begin
                        dot_counter = dot_counter + 1;
                    end
                    //EDGE CASE WHERE A 0 BETWEEN DOTS 0101 IS A ONE SOMEHOW (0101 -> 0111)
                    else if(one_counter == 3 && shift_counter < compare_separator) begin
                        dot_counter = dot_counter + 1;
                    end

                    one_counter = 0;
                end

                shift_counter = shift_counter + 1;
                temp_stream = temp_stream >> 1; //shift temp_stream for next bit handling

                //DECODER REACHED END OF STREAM
                if(shift_counter > stream_end_val) begin

                    out = false; //overriden if counters found a match
                    ready <= true;

                    if(dot_counter >= compare_dot) begin
                        dot_match = true;
                        out = stream_end_val == ONE_SIZE ? 4'd1 :
                              stream_end_val == TWO_SIZE ? 4'd2 :
                              stream_end_val == THREE_SIZE ? 4'd3 :
                              false; //should never happen
                    end
                    else
                        dot_match = false;
                    if(dash_counter >= compare_dash) begin
                        dash_match = true;
                        out = stream_end_val == ONE_SIZE ? 4'd1 :
                              stream_end_val == TWO_SIZE ? 4'd2 :
                              stream_end_val == THREE_SIZE ? 4'd3 :
                              false; //should never happen
                    end
                    else
                        dash_match = false;
                end
            end
        end
    end

endmodule