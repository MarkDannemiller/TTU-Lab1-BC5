`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2023 06:19:58 PM
// Design Name: 
// Module Name: US_SENSOR
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


module US_SENSOR #(parameter SAMPLE_MS = 10, parameter SAMPLE_PERCENT = 90)(
    input clk, //input clock for reading pulse
    input echo_pin, //INVERTED LOGIC DUE TO PULLUP RESISTOR
    input module_enable,
        
    output detected,//outputs high  if something is detected in the target distance
    output reg sampled, //sampled is a filtered version of detected over a user-specified sample time. percentage determines how much of the signal is high for a detect
    output trigger,//sends signal to US sensor to trigger pulse
    output[29:0] distance
    );
    
    localparam true = 1;
    localparam false = 0;
    localparam CLOCK_TO_MS = 100000; //100,000 CLOCK CYCLES IN 1 MS
    
    localparam target_distance = 13; //maximum detection distance in [cm]
    reg [29:0] timer = 0; //measured in microseconds, max of 23,200*2^15
    reg timer_enable=0;
    reg [6:0] counter =0;
    
    assign distance = final_timer_val;
    reg[29:0] final_timer_val = 99999;
    
    reg[14:0] trigger_timer=0;
    reg[6:0] trigger_counter = 0;
    reg trig_reg = 0;
    assign trigger = trig_reg;
    
    //2300 IS TIME BETWEEN TRIGGER AND ECHO RECEPTION
    assign detected = (final_timer_val<(target_distance*58)) ? 1 : 0; //converts target distance from cm to time    
    reg rising_edge = false;
    
    //SAMPLED IS A VARIABLE THAT IS A FILTERED VERSION OF DETECTED OVER A SPECIFIED SAMPLE PERIOD
    reg[29:0] detected_counter=0; //counts ammount of detected signals over a certain period
    reg[29:0] sample_counter=0;
    
    //increment timer if we are receiving echo OR increment trigger timer if we are sending pulse
    always@(posedge clk)begin
    
        //THIS BLOCK OF CODE SAMPLES EVERY SAMPLE_MS AND OUTPUTS WHETHER AN ON WAS DETECTED FOR SAMPLE_PERCENT OF THE TIME
        sample_counter <= sample_counter + 1;
        detected_counter <= detected_counter + detected; //detected is 1 or 0
        if(sample_counter > SAMPLE_MS * CLOCK_TO_MS-1) begin
            sampled = (detected_counter > (SAMPLE_MS * CLOCK_TO_MS-1) * SAMPLE_PERCENT/100);
            sample_counter <= 0;
            detected_counter <=0;
        end
        
        //DISABLE TIMER WHEN NEGATIVE EDGE OF ECHO OCCURS
        if(!echo_pin && timer_enable) begin
            rising_edge = true;
            
            counter=counter+1;
               
            if(counter>99)begin
                timer <= timer+1;
                counter <= 0;
                end
        end
        
        //GET FINAL TIMER VALUE AT NEGATIVE EDGE OF ECHO
        if(echo_pin && timer_enable && rising_edge) begin
            final_timer_val <= timer;
            timer_enable <= false;
            rising_edge <= false;
        end
        
        if(echo_pin) begin
            
            trigger_counter = trigger_counter + 1;
            
            //MEASURE TRIGGER TIMER IN MICROSECONDS
            if(trigger_counter > 99) begin
                trigger_timer <= trigger_timer + 1;
                trigger_counter <= 0;
            end
            
            //TRIGGER FOR 10 MICROSECONDS; AFTER WHICH START COUNTING THE TIMER FOR DISTANCE CALCULATION
            if(trigger_timer > 9 && trigger_timer < 20) begin
                trig_reg <= 1;
                timer <= 0;
                counter <= 0;
                timer_enable <= true;
            end
            else begin
                trig_reg = 0;
            end
        end
        else begin
            trig_reg <= 0;
            trigger_timer <= 0;
            trigger_counter <= 0;
        end
    end
    
        
    
endmodule
