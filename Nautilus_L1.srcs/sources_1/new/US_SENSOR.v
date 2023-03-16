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


module US_SENSOR(
    input clk, //input clock for reading pulse
    input echo_pin, //INVERTED LOGIC DUE TO PULLUP RESISTOR
    input module_enable,
        
    output detected,//outputs high  if something is detected in the target distance
    output trigger,//sends signal to US sensor to trigger pulse
    output[29:0] distance
    );
    
    localparam true = 1;
    localparam false = 0;
    
    localparam target_distance = 16; //cm
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
    //assign detected = (final_timer_val<=(7));
    
    reg rising_edge = false;
    
    //increment timer if we are receiving echo OR increment trigger timer if we are sending pulse
    always@(posedge clk)begin
        
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
