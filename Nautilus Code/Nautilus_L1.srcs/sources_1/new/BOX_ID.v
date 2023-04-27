`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2023 06:19:58 PM
// Design Name: 
// Module Name: BOX_ID
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


module BOX_ID(

    //NEED TO CODE A SWITCH IN TO SET "MEMORY" MODE ON

    input sysClk,
    input echo_back,
    output trigger_back,
    input echo_front,
    output trigger_front,
    input IR_in,

    input continue, //temp var for "receiving ir"
    output[29:0] us_distance,
    
    output front_detected,
    output back_detected,
    output ir_detect,
    output[19:0] IR_display_data,
    output reg[3:0] marble_val,
    output reg[4:0] STATE //0=none detected, 1=front detected, 2=back detected, 3=scanning, 4=dispense
    );

    localparam DRIVE = 0;
    localparam FRONT_DETECT = 1;
    localparam BACK_DETECT = 2; //DEPRECATED
    localparam SCANNING = 3;
    localparam DISPENSE = 4;

    //WILL COMPARE
    reg[3:0] IR_VAL_1;
    reg[3:0] IR_VAL_2;
    reg[3:0] IR_VAL_3;
    reg[2:0] IR_INDEX;
    
    reg[3:0] CURRENT_IR; //stores current value of IR to compare when IR changes

    reg[19:0] ms_counter=0; //counter that counts to 1ms
    reg[19:0] ms_timer=0; //timer that counts up in ms
    
    reg front_us_en=0;
    reg back_us_en=0;
    
    //localparam ESCAPE = 0;
    //reg[3:0] timer_mode;
    
    localparam escape_time = 3000; //time in ms it takes to escape from the bin after reenable
    localparam dispense_time = 3000;
    localparam box_detect_time = 250; //time takes to verify that box was detected

    US_SENSOR us_sens_back(
        .clk(sysClk),
        .echo_pin(echo_back),
        .trigger(trigger_back),
        //.detected(back_detected), //DEPRECATED SINCE SAMPLED IS BETTER
        .sampled(back_detected),
        .module_enable(back_us_en)
        //.distance(us_distance)
    );

    US_SENSOR us_sens_front(
        .clk(sysClk),
        .echo_pin(echo_front),
        .trigger(trigger_front),
        //.detected(front_detected), //DEPRECATED SINCE SAMPLED IS BETTER
        .sampled(front_detected),
        .module_enable(front_us_en),
        .distance(us_distance)
    );
   
   reg ir_enable;
   wire IR_fallback;
   wire[3:0] IR_val;
   wire dot_match;
   wire dash_match;
   
   wire[59:0] bitstream;
   
    assign IR_display_data[19] = 1;
    assign IR_display_data[18:15] = dot_match;
    assign IR_display_data[14] = 1;
    assign IR_display_data[13:10] = dash_match;
    assign IR_display_data[9] = 1;
    assign IR_display_data[8:5] = IR_fallback;
    assign IR_display_data[4] = 1;
    assign IR_display_data[3:0] = IR_val;
    
    /*assign IR_display_data[19] = 1;
    assign IR_display_data[18:15] = bitstream[15:12];
    assign IR_display_data[14] = 1;
    assign IR_display_data[13:10] = bitstream[11:8]; 
    assign IR_display_data[9] = 1;
    assign IR_display_data[8:5] = bitstream[7:4];
    assign IR_display_data[4] = 1;
    assign IR_display_data[3:0] = bitstream[3:0];*/
    
    
    IR_INPUT IR (
        .clk(sysClk),
        .IR_Pin(IR_in),
        .LED(ir_detect),
        .value(IR_val),
        .process_stream(bitstream),
        .dot_match(dot_match),
        .dash_match(dash_match),
        .morse_fallback(IR_fallback),
        .enable(ir_enable) //test always on. write high later
    );
    
    initial begin
        STATE = DRIVE;
        front_us_en = 1;
        back_us_en = 0;
        CURRENT_IR=0;
    end

    always@(posedge sysClk) begin
    
        ms_counter = ms_counter + 1;
        if(ms_counter > 99_999) begin
            ms_counter <= 0;
            ms_timer <= ms_timer + 1;
        end

        case (STATE)
            DRIVE: begin
                ir_enable = 0;
                marble_val = 0;
                front_us_en = 1;
                back_us_en = 0;
                //the rover should have a grace period to escape the box before latching to another box. 
                //This also will wait 3 seconds upon enabling the bot for it to ignore human interference
                if(ms_timer > escape_time) begin
                    if(front_detected) begin
                            STATE <= FRONT_DETECT;
                            ms_timer <= 0;
                            ms_counter <= 0;
                    end
                    else if(back_detected) begin
                            STATE <= BACK_DETECT;
                            ms_timer <= 0;
                            ms_counter <= 0;
                    end
                end
            end
            FRONT_DETECT: begin
                ir_enable = 0;
                marble_val = 0;
                front_us_en = 1;
                back_us_en = 1;
                if(back_detected && !front_detected) begin
                    STATE <= BACK_DETECT;
                    //STATE = SCANNING;
                    ms_timer <=0;
                    ms_counter <= 0;
                end
                else if(front_detected && back_detected) begin
                    STATE = SCANNING;
                    ms_timer <=0;
                    ms_counter <= 0;
                end
                //IN CASE OF ERRONEOUS DETECTION. RETURNS AFTER SOME SECONDS OF NO SIGNAL
                else if(!front_detected && !back_detected && ms_timer > box_detect_time*5) begin
                    STATE = DRIVE;
                    ms_timer <= escape_time;
                    ms_counter <= 0;
                end
            end
            BACK_DETECT: begin
                ir_enable = 0;
                marble_val = 0;
                front_us_en = 1;
                back_us_en = 1;
                if(front_detected && !back_detected) begin
                    STATE <= FRONT_DETECT;
                    ms_timer <=0;
                    ms_counter <= 0;
                end
                else if(front_detected && back_detected) begin
                    STATE <= SCANNING;
                    ms_timer <=0;
                    ms_counter <= 0;
                end
                //IN CASE OF ERRONEOUS DETECTION. RETURNS AFTER 2 SECONDS OF NO SIGNAL
                else if(!front_detected && !back_detected && ms_timer > box_detect_time*5) begin
                    STATE = DRIVE;
                    ms_timer <= escape_time;
                    ms_counter <= 0;
                end
            end
            //ADD TWO MORE STATES FOR FORWARD SEARCH AND REVERSE SEARCH
            SCANNING: begin
                if(ms_timer > box_detect_time) begin
                    //disable ultrasonic for scanning
                    front_us_en = 0;
                    back_us_en = 0;
                    ir_enable = 1; //enable ir
                    
                    //on rising edge of ir value change
                    if(IR_val != CURRENT_IR && IR_val != 4'hE && IR_val != 0) begin
                        if(IR_INDEX == 0) begin
                            IR_VAL_1 = IR_val;
                        end
                        else if(IR_INDEX == 1) begin
                            IR_VAL_2 = IR_val;
                        end
                        else if(IR_INDEX==2) begin
                            IR_VAL_3 = IR_val;
                        end
                        
                        IR_INDEX <= IR_INDEX > 1 ? 0 : IR_INDEX + 1;
                    end
                    
                    //temp process. Need to insert IR decoding / handling here
                    if(continue || ((IR_VAL_1==IR_VAL_2 && IR_VAL_1==IR_VAL_3) && IR_VAL_1 != 0 && IR_VAL_1 != 4'hE)) begin
                        STATE <= DISPENSE;
                        ms_timer <= 0;
                        ms_counter <= 0;
                    end
                end
                else begin
                    ir_enable = 0;
                    front_us_en = 1;
                    back_us_en = 1;
                    if(front_detected && !back_detected) begin
                        STATE <= FRONT_DETECT;
                        ms_timer <=0;
                        ms_counter <= 0;
                    end
                    else if(back_detected && !front_detected) begin
                        STATE <= BACK_DETECT;
                        ms_timer <=0;
                        ms_counter <= 0;
                    end
                end
            end
            DISPENSE: begin
                //marble_val = IR_VAL_1;
                marble_val = IR_VAL_1; //replace with result of decodings
                if(ms_timer > 3000) begin
                    STATE <= DRIVE;
                    ms_timer <= 0;
                    ms_counter <= 0;
                end
            end
        endcase
        
        CURRENT_IR = IR_val;
    end

endmodule
