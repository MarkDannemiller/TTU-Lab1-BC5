`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Boat Crew 5
// Engineer: Mark Dannemiller
// 
// Create Date: 03/02/2023 06:19:58 PM
// Design Name: 
// Module Name: IPS_ARRAY
// Project Name: Nautilus
// Target Devices: 
// Tool Versions: 
// Description: 
// This module handles the detection of the tape and the current state of the robot.  It outputs the current movement state and motor information
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
// **Code is free to use as long as you attribute our GitHub repository for others to find the same resources.**
// 
//////////////////////////////////////////////////////////////////////////////////


module IPS_ARRAY(
    output motor_en_l,
    output motor_en_r,
    output dir_l,
    output dir_r,
    output[6:0] mode,
    output[4:0] m_state,
    
    input clk,
    input ips_front,
    input ips_left,
    input ips_right,
    input ips_mid
    );
    
    reg front;
    reg left;
    reg right;
    reg mid;
    
    parameter tolerance = 50; //degrees tolerance
    parameter turn_speed_d = 10; //degrees per second expected rotation speed
    
    /*parameter FORWARD_SPEED = 4'd15; //specification of 4 bit speed mode for forward
    parameter REVERSE_SPEED = 4'd10; //specification of 4 bit speed mode for reverse
    parameter TURN_SPEED = 4'd10; //specification of 4 bit turning speed

    parameter FORWARD_SLOW_SPEED = 4'd5;
    parameter TURN_SLOW_SPEED = 4'd8;*/
    parameter FORWARD_SPEED = 7'd100; //specification of 4 bit speed mode for forward
    parameter REVERSE_SPEED = 7'd75; //specification of 4 bit speed mode for reverse
    parameter TURN_SPEED = 7'd85; //specification of 4 bit turning speed

    parameter FORWARD_SLOW_SPEED = 7'd30;
    parameter TURN_SLOW_SPEED = 7'd60;

    /*parameter FORWARD_SPEED = 7'd80; //specification of 4 bit speed mode for forward
    parameter REVERSE_SPEED = 7'd60; //specification of 4 bit speed mode for reverse
    parameter TURN_SPEED = 7'd75; //specification of 4 bit turning speed

    parameter FORWARD_SLOW_SPEED = 7'd30;
    parameter TURN_SLOW_SPEED = 7'd60;*/
    
    
    //The states of the IPS navigation system
    localparam FORWARD = 1;
    localparam REVERSE = 2;
    localparam ROTATE = 3;
    localparam FORWARD_SPECIAL = 4;
    
    reg[4:0] state = FORWARD; //start forward
    assign m_state = state;
    
    reg rotate_dir = 0;
    
    //temp registers for motor states
    reg left_enable;
    reg right_enable;
    reg dir_left;
    reg dir_right;
    reg[6:0] speed;
    
    //assign outputs to temp registers
    assign motor_en_l = left_enable;
    assign motor_en_r = right_enable;
    assign dir_l = !dir_left;
    assign dir_r = dir_right;
    assign mode = speed;
    
    reg[15:0] rotate_timer = 0; //timer in ms that measures rotate time
    reg[19:0] ms_counter = 0; //counter that counts up to one milisecond
    
    reg current_ips_right;
    reg current_ips_left;
    
    initial begin
        current_ips_right = ips_right;
        current_ips_left = ips_left;
        rotate_timer = 0;
        ms_counter = 0;
        speed = FORWARD_SPEED;
    end
    
    always@(posedge clk) begin
        //motors always on
        left_enable = 1;
        right_enable = 1;
        
        front = !ips_front;
        left = !ips_left;
        right = !ips_right;
        mid = !ips_mid;
        
        ms_counter = ms_counter + 1;
        
        //count up timer in ms
        if(ms_counter > 100000) begin
            rotate_timer = rotate_timer + 1;
        end    
    
        //BEHAVIOR SHALL CHANGE BASED ON THE STATE OF THE ROVER. SEE NAVIGATION FLOWCHART FOR MORE INFORMATION
        case (state)
        FORWARD: begin
            dir_left = 1;
            dir_right = 1;
            
            //just added a check to make sure it only updates on rising edge
            //also, if front sensor is off and both sensors were just on but one just left then the sensor that is still on takes priority
            if((right && right != current_ips_right))/* || 
               (!front && !current_ips_right && !current_ips_left && !left))*/ begin //VALUES OF CURRENT_IPS ARE INVERTED WHEN FRONT IS OFF TAPE TO PRESERVE FUNCTIONALITY WHEN FRONT HITS TAPE AGAIN
                rotate_dir = 1;
            end
            else if(left && (left != current_ips_left)) /*|| 
                    (!front && !current_ips_left && !current_ips_right && !right))*/ begin
                rotate_dir = 0;
            end
            else
                speed = FORWARD_SPEED;
            
            //slow down at edge
            if(!front && mid) begin
                speed = FORWARD_SLOW_SPEED;
            end
            
            //IF FRONT AND MIDDLE SENSOR RAN OFF TRACK, REVERSE UNTIL EDGE OF TAPE IS FOUND BY MID
            if(!front && !mid) begin
                if(!right && !left) begin
                    state = REVERSE;
                end
                else if(right) begin
                    rotate_dir = 1;
                    state = ROTATE;
                end
                else if(left) begin
                    rotate_dir = 0;
                    state = ROTATE;
                end
            end
            //IF MIDDLE SENSOR RUNS OFF TRACK BUT FRONT IS ON, THEN CONTINUE FORWARD UNTIL MIDDLE HAS REACHED EDGE
            if(front && !mid) begin
                state = FORWARD_SPECIAL;
                speed = FORWARD_SPEED;
            end
        end
        
        REVERSE: begin
            speed = REVERSE_SPEED;
            dir_left = 0;
            dir_right = 0;
            
            if(mid) begin
                state = ROTATE;
                rotate_timer = 0;
                ms_counter = 0;
            end
        end
        
        ROTATE: begin
            dir_left = rotate_dir; //positive rotation is counter clockwise
            dir_right = !rotate_dir;
            ms_counter = ms_counter + 1;
            
            //100,000 cycles = 1ms
            if(ms_counter > 100000) begin
               rotate_timer = rotate_timer + 1; 
            end
            
            //slow down when sensor picks up edge
            if(left || right) begin
                speed = TURN_SLOW_SPEED;
            end
            else
                speed = TURN_SPEED;
            
            //ROTATE UNTIL FRONT IPS SENSOR HAS FOUND TAPE
            //180/turn_speed = time to rotate 180 degrees
            if(front) begin
                //checks rotate time was over or under time to rotate 180 degrees then checks
                //if(rotate_timer < 180/turn_speed_d && 180/turn_speed_d - rotate_timer > tolerance/turn_speed_d
                //|| rotate_timer > 180/turn_speed_d && rotate_timer - 180/turn_speed_d > tolerance/turn_speed_d) begin
                    state = FORWARD;
                //end
            end
        end
        
        //SPECIAL MODE WHEN MIDDLE SENSOR IS OFF BUT FRONT SENSOR IS ON.  MOVE FORWARD UNTIL MIDDLE SENSOR HAS FOUND TAPE
        FORWARD_SPECIAL: begin
            speed = FORWARD_SPEED;
            
            //just added a check to make sure it only updates on rising edge
            //also, if front sensor is off and both sensors were just on but one just left then the sensor that is still on takes priority
            if((right && right != current_ips_right))/* || 
               (!front && !current_ips_right && !current_ips_left && !left))*/ begin //VALUES OF CURRENT_IPS ARE INVERTED WHEN FRONT IS OFF TAPE TO PRESERVE FUNCTIONALITY WHEN FRONT HITS TAPE AGAIN
                rotate_dir = 1;
            end
            else if(left && (left != current_ips_left)) /*|| 
                    (!front && !current_ips_left && !current_ips_right && !right))*/ begin
                rotate_dir = 0;
            end
            
            //IF BOTH CENTER SENSORS ARE OFF BUT A DIRECTION SENSOR IS FOUND, ROTATE THAT DIRECTION!
            //NOTICE THAT THIS CODE IS SIMILAR TO FORWARD MODE BUT EXCLUDES THE REVERSE CASE
            if(!front && !mid) begin
                //ROVER IS CENTERED IF BOTH ARE ON
                if(right && !left) begin
                    rotate_dir = 1;
                    state = ROTATE;
                end
                else if(left && !right) begin
                    rotate_dir = 0;
                    state = ROTATE;
                end
            end
            
            if(mid) begin
                state = FORWARD;
            end
        end
        endcase
        
        current_ips_right = right;
        current_ips_left = left;
    end
endmodule
