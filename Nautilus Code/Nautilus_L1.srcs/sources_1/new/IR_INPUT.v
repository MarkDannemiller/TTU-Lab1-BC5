`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Boat Crew 5
// Engineer: Mark Dannemiller
// 
// Create Date: 03/02/2023 06:19:58 PM
// Design Name: 
// Module Name: IR_INPUT
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


/*
KEY CONCEPTS:
1 = DOT
111 = DASH
0 = PERIOD BETWEEN UNITS
000 = END CHARACTER

In this module, data is processed from the IR receiver into a bit stream.  Each bit is measured in time
and entered into a time register such that any random noise can be filtered out
*/

module IR_INPUT
#(parameter CLOCK_TO_MS = 100000)(

input enable,
input clk,
input IR_Pin,
output LED,
output reg[59:0] process_stream,
output reg overflow,
output wire dot_match,
output wire dash_match,
output morse_fallback,
output [3:0] value,
output morse_ready
);
assign LED = IR_Pin;

localparam START_LENGTH = 7; //LENGTH OF START/END CHARACTER IN UNITS

localparam true = 1;
localparam false = 0;
localparam CHAR_MIN_MS = 55;
//dlocalparam UNIT_THRESHOLD = 0.75; //MIN AMOUNT OF TIME A UNIT WAS PROCESSED FOR IT TO BE CONSIDERED ACCURATE
localparam CHAR_MS = 60; //60 MS IS EXPECTED PER CHARACTER

reg start;
reg reset; //auto resets when finished processing, for continuos processing
reg found_start_char; //reg storing bool value of whether start character is found

reg[59:0] bitstream; //stream of data that should only ever be 20 units of data long before end character
reg incoming_bit;
reg[59:0] new_val;
reg[5:0] bit_index;

//255ms max time per bit accounts for a maximum of 4 units (0.06s)*4=240ms observed which accounts for dashes and start/end strings 
reg[19:0] ms_counter; //counter that counts to 1ms
reg[11:0] ms_timer; //timer that counts up to 1024ms maximum

reg[11:0] ms_timer_carry; //used when IR value is too small
reg IR_carry; //used when IR value is too small

//DECODER VALUES
reg decode_en;

MORSE_DECODER decoder (
    .enable(decode_en),
    .clk(clk),
    .bitstream(process_stream),
    .ready(morse_ready),
    .fallback(morse_fallback),
    .dot_match(dot_match),
    .dash_match(dash_match),
    .out(value)
);

initial begin
    bitstream <= 60'b0;
    process_stream <= 60'b0;
    bit_index <= 0;
    start <= false;
    reset <= false;
    decode_en <= 0;
end

reg force_update; //to force update at end of code process for immediate next start

always@(posedge clk) begin

    if(morse_ready && decode_en)
        decode_en = false;

    //disable module and reset registers
    if(!enable) begin
        bitstream = 60'b0;
        bit_index <= 0;
        reset <= false;
        start = false;
        decode_en <= 0;
        ms_counter <= 0;
        ms_timer <= 0;
        found_start_char <= 0;
        force_update <= false;
    end
    //IF ENABLED, PROCESS IR MORSE CODE
    else begin

        //WHEN READY OCCURS, DISABLE MORSE DECODER. THIS MEANS THAT OUTPUT VALUE WILL THEN BE STATIC UNTIL WE WANT TO PASS NEXT VALUE TO DECODE
        if(morse_ready && decode_en)
            decode_en = false;

        //ONLY START PROCESSING ONCE IR IS DETECTED. I.E: DETECTING OFF FOR A LONG TIME IS NOT THE BEGINNING
        //ALSO RESTARTS UPON RESET
        if((IR_Pin == 1 && !start) || reset) begin
            start <= true;
            reset <= false;
            incoming_bit <= IR_Pin;
            bit_index <= 0;
            bitstream = 60'b0;
            found_start_char <= false;
            overflow <= false;
        end
        
        if(force_update)
            found_start_char <= true; //set to true as 
        
        if(start) begin
            //TRACK MS TIME THAT ON BIT HAS BEEN RECEIVED
            ms_counter = ms_counter + 1;
            if(ms_counter > CLOCK_TO_MS-1) begin
                ms_timer = ms_timer + 1; //increment in ms
                ms_counter = 0;
            end

            //case when last bit was too short and needs to be merged with this one
            if(ms_timer_carry != 0 && incoming_bit != IR_Pin) begin

                //bias the incoming bit to larger state out of the current and previous state
                incoming_bit = ms_timer > ms_timer_carry ? incoming_bit : IR_carry;
                ms_timer =  ms_timer + ms_timer_carry; //the times of each value are appended as if ms_timer never reset
                ms_timer_carry = 0;

                //if value of ms_timer is still too low, then the process will repeat!
            end

            //IF IR HAS CHANGED
            if(incoming_bit != IR_Pin) begin
                //if starting character is found, then we write to the bitstream
                if(found_start_char) begin
                    if(force_update) begin
                        force_update = false;
                        new_val = 60'b0;
                    end
                    //was 1 processed?
                    else if(ms_timer >= CHAR_MIN_MS && ms_timer < CHAR_MS + CHAR_MIN_MS) begin
                        //overflow condition
                        if(bit_index > 59) begin
                            overflow <= true;
                        end
                        
                        //new_val is 1 or 0
                        new_val = incoming_bit << bit_index; //shift incoming bit to correct position in 60 bit array
                        bit_index = bit_index + 1;
                    end
                    //or was 11 or 00 processed? (shouldn't be)
                    else if (ms_timer >= CHAR_MIN_MS * 2 && ms_timer < CHAR_MS * 2 + CHAR_MIN_MS) begin
                        //overflow condition
                        if(bit_index + 1 > 59) begin
                            overflow <= true;
                        end
                        
                        //new_val is 11 or 00
                        new_val = (incoming_bit << bit_index) | (incoming_bit << bit_index+1);
                        bit_index = bit_index + 2;
                    end
                    //or was 111 or 000 processed? (dash case)
                    else if(ms_timer >= CHAR_MIN_MS * 3 && ms_timer < CHAR_MS * 3 + CHAR_MIN_MS) begin
                        //overflow condition
                        if(bit_index + 2 > 59) begin
                            overflow <= true;
                        end
                        
                        //new_val is 111 or 000
                        new_val = (incoming_bit << bit_index) | (incoming_bit << bit_index+1) | (incoming_bit << bit_index+2);
                        bit_index = bit_index + 3;
                    end
                    //or was 1111 or 00000 processed? (EDGE CASE)
                    else if(ms_timer >= CHAR_MIN_MS * 4 && ms_timer < CHAR_MS * 4 + CHAR_MIN_MS) begin
                        //overflow condition
                        if(bit_index + 2 > 59) begin
                            overflow <= true;
                        end
                        
                        //new_val is 1111 or 0000
                        new_val = (incoming_bit << bit_index) | (incoming_bit << bit_index+1) | (incoming_bit << bit_index+2) | (incoming_bit << bit_index+3);
                        bit_index = bit_index + 4;
                    end
                    //or was 11111 or 00000 processed? (EDGE CASE)
                    else if(ms_timer >= CHAR_MIN_MS * 5 && ms_timer < CHAR_MS * 5 + CHAR_MIN_MS) begin
                        //overflow condition
                        if(bit_index + 2 > 59) begin
                            overflow <= true;
                        end
                        
                        //new_val is 11111 or 00000
                        new_val = (incoming_bit << bit_index) | (incoming_bit << bit_index+1) | (incoming_bit << bit_index+2) | (incoming_bit << bit_index+3) | (incoming_bit << bit_index+4);
                        bit_index = bit_index + 5;
                    end
                    //or was 111111 or 000000 processed? (EDGE CASE)
                    else if(ms_timer >= CHAR_MIN_MS * 6 && ms_timer < CHAR_MS * 6 + CHAR_MIN_MS) begin
                        //overflow condition
                        if(bit_index + 2 > 59) begin
                            overflow <= true;
                        end
                        
                        //new_val is 111111 or 000000
                        new_val = (incoming_bit << bit_index) | (incoming_bit << bit_index+1) | (incoming_bit << bit_index+2 | (incoming_bit << bit_index+3) | (incoming_bit << bit_index+4) | (incoming_bit << bit_index+5));
                        bit_index = bit_index + 6;
                    end
                    else new_val = 60'b0;

                    //when value is too short, there must have been a spike that needs smoothing
                    //either the next sequence will be larger or smaller than this one
                    if (ms_timer < CHAR_MIN_MS)begin
                        ms_timer_carry = ms_timer;
                        IR_carry = incoming_bit;
                    end
                    else begin
                        ms_timer_carry = 0;
                    end
                    
                    bitstream = bitstream | new_val;
                end
                //program monitors until finding start bit
                else if(incoming_bit == 0 && ms_timer > CHAR_MIN_MS * START_LENGTH) begin
                    found_start_char <= true;
                end        
                ms_counter = 0;
                ms_timer = 0;
            end
            //the case that the end character was found. Pass value to decoder
            else if(found_start_char && IR_Pin == 0 && ms_timer > CHAR_MIN_MS * START_LENGTH && !force_update) begin
                reset <= true;
                process_stream = bitstream;
                decode_en = true; //START DECODER
                force_update = true; //FORCE AN UPDATE OF THE NEXT BITSTREAM TO SEE START CHARACTER IMMEDIATELY
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
* IF STREAM SIZE IS NOT COMPARABLE TO ANY NUMBER OR IF BIT STREAMS ARE NONSENSE, RETURNS FALSE/E
* 
**/
module MORSE_DECODER (input enable, input clk, input[59:0] bitstream, 
                      output reg ready, output reg fallback, output reg dot_match, output reg dash_match, 
                      output reg [3:0] out);

    localparam true = 1;
    localparam false = 0;
    localparam ONE = 17'b11101110111011101; //10111011101110111; //IN READING ORDER
    localparam TWO = 15'b111011101110101; //101011101110111; //READING ORDER L->R
    localparam THREE = 13'b1110111010101; //1010101110111; //READING ORDER L->R

    localparam ONE_SIZE = 10'd17;
    localparam TWO_SIZE = 10'd15;
    localparam THREE_SIZE = 10'd13;

    reg[7:0] shift_counter;
    reg[4:0] one_counter;
    reg[4:0] dot_counter;
    reg[4:0] dash_counter;

    reg[59:0] temp_stream;

    reg[4:0] compare_dot;
    reg[4:0] compare_dash;
    reg[9:0] compare_separator; //separation value from ones and dashes
    reg[9:0] stream_end_val; //index of the end stream
    
    reg enable_last; //MODULE MUST BE DISABLED THEN RENABLED

    always@(posedge clk) begin
    
        if(!enable)
            ready <= false; //necessary, otherwise upper module will detect that decode module is ready as soon as it is enabled again
    
        //RESET DECODE PROCESS WHEN MODULE HAS BEEN REENABLED AFTER A MANUAL RESET
        if(enable && enable != enable_last) begin
            ready <= false;
            temp_stream = bitstream;
            one_counter <= 5'b0;
            dot_counter <= 5'b0;
            dash_counter <= 5'b0;
            shift_counter <= 8'b0;
            dot_match <= false;
            dash_match <= false;

                            
            //SET NUMBER OF DASHES/DOTS TO COMPARE TO FOR FALLBACK DECODING PROCESS
            //THIS CODE BASICALLY CHECKS THE SIZE OF THE INPUT
            if(bitstream[THREE_SIZE+6:THREE_SIZE] == 7'b0000000) begin
                    compare_dash <= 5'd02;
                    compare_dot <= 5'd03;
                    compare_separator <= 10'd05;
                    stream_end_val <= THREE_SIZE;
            end
            else if(bitstream[TWO_SIZE+6:TWO_SIZE] == 7'b0000000) begin
                    compare_dash <= 5'd03;
                    compare_dot <= 5'd02;
                    compare_separator <= 10'd03;
                    stream_end_val <= TWO_SIZE;
            end
            else if(bitstream[ONE_SIZE+6:ONE_SIZE] == 7'b0000000) begin
                    compare_dash <= 5'd04;
                    compare_dot <= 5'd01;
                    compare_separator <= 10'd01; //EXPECTED INDEX TO SWITCH FROM DOTS TO DASHES
                    stream_end_val <= ONE_SIZE;
            end
            //IF STREAM DOES NOT MATCH LENGTH OF ANY KNOWN NUMBER
            else begin
                    ready = true;
                    out = 4'hE; //4=NOT FOUND
                    fallback = true;
            end
        end
        else if(enable && !ready) begin
            //TO BEGIN, CHECK AGAINST PERFECT CASES
            if (bitstream[ONE_SIZE-1:0] == ONE) begin
                out = 4'd1;
                ready = true;
                fallback = false;
                dot_match = true;
                dash_match = true;
            end
            else if (bitstream[TWO_SIZE-1:0] == TWO) begin
                out = 4'd2;
                ready = true;
                fallback = false;
                dot_match = true;
                dash_match = true;
            end
            else if (bitstream[THREE_SIZE-1:0] == THREE) begin
                out = 4'd3;
                ready = true;
                fallback = false;
                dot_match = true;
                dash_match = true;
            end
            //IF NO PERFECT CASE WAS FOUND, GUESS AGAINST NUMBER OF DASHES/DOTS RECEIVED (FALLBACK DECODING MODE)
            else begin
                fallback = true; //trigger such that upper modules know that fallback was hit
                
                //when compare_separator is reached, add another dot if one_counter is greater than 0.  After this, the code will begin searching for dashes
                if(shift_counter == compare_separator) begin
                    if(temp_stream[0] == 1) begin
                        one_counter = one_counter + 1;
                    end
                
                    if(one_counter != 0) begin
                        dot_counter = dot_counter + 1;
                    end
                    one_counter = 0;
                end
                //BEGIN BY CHECKING FOR A SINGLE ERRONEOUS BIT BASED ON BITSTREAM LENGTH (WILL CHECK IF DASHES ARE CORRECT, THEN DOTS)
                else if(temp_stream[0] == 1) begin
                    one_counter = one_counter + 1;
                end
                //DECIPHER STREAM OF ONES WHEN 0 IS ENCOUNTERED
                else begin
                    //CASE WHEN DASHES APPEAR NORMAL OR BIGGER BETWEEN 3->6 ONES LONG (IF A DASH IS 5 ONES LONG, THEN THE RESULT SHOULD NOT OCCUR BASED ON DASHES)
                    if(one_counter > 2 && one_counter < 7 && shift_counter > compare_separator) begin
                        dash_counter = dash_counter + 1;
                    end
                    //CASE WHEN AN EXTRA 1 WAS READ EX: (11101110111011111)
                    else if((one_counter == 1 || one_counter == 2) && shift_counter < compare_separator) begin
                        dot_counter = dot_counter + 1;
                    end

                    one_counter = 0;
                end

                shift_counter = shift_counter + 1;
                temp_stream = temp_stream >> 1; //shift temp_stream for next bit handling

                //DECODER REACHED END OF STREAM
                if(shift_counter > stream_end_val) begin

                    out = 4'hE; //overriden if counters found a match
                    ready <= true;

                    if(dot_counter == compare_dot) begin
                        out = compare_dot == 5'd01 ? 4'd1 :
                              compare_dot == 5'd02 ? 4'd2 :
                              compare_dot == 5'd03 ? 4'd3 :
                              out;
                        dot_match = out != 4'hE ? true : false;
                    end
                    else
                        dot_match = false;
                    if(dash_counter == compare_dash) begin                 
                        dash_match = true;
                        out = compare_dash == 5'd04 ? 4'd1 :
                              compare_dash == 5'd03 ? 4'd2 :
                              compare_dash == 5'd02 ? 4'd3 :
                              out;
                              
                        dot_match = 5 - dash_match == dot_counter ? true : false; //when dash is found, the dot found must match the pair.
                    end
                    else
                        dash_match = false;
                end
            end
        end
        
        enable_last = enable;
    end

endmodule