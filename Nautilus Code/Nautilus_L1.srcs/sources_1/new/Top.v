`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LAB GROUP 5
// Engineer: MDANNEMI
// 
// Create Date: 01/30/2023 12:37:36 AM
// Design Name: 
// Module Name: Top
// Project Name: NAUTILUS_L1
// Target Devices: BASYS BOARD
// Tool Versions: 
// Description: 
//
//  This module is the topmost module, and bridges the outside I/O with the Verilog modules created for this project
//  Each module contains its own inputs and outputs which are linked by the top module.  In this way, each module
//  can be treated as its own "black box" and diagnosed internally when errors occur.  By modulating the HDL design,
//  we create a system that is easier to look at and similar to Object Oriented Programming.  The only logic that this
//  Top module controls is the loop at the bottom determining which navigation logic to follow based on the state of our
//  bin detection sensors.
// 
// Deendencies: 
// 
// Revision: 0.1
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Top (

    //DISPLAY
    input wire[15:0] sw,
    output wire[15:0] led,
    output wire[6:0] seg,
    output dp,
    output wire[3:0] an,
    input sysClk,
    
    //ADC ports
    input vauxp6,
    input vauxn6,
    input vauxp7,
    input vauxn7,
    input vauxp15,
    input vauxn15,
    input vauxp14,
    input vauxn14,
    input vp_in,
    input vn_in,
    
    //MOTOR CONTROL
    output wire JA1_ENA,
    output wire JA2_IN1,
    output wire JA3_IN2,
    output wire JA7_ENB,
    output wire JA8_IN3,
    output wire JA9_IN4,
    
    inout wire JA4_I2C_SDA,
    input wire JA10_I2C_SCL,

    //IPS_SENSOR
    input wire JB0_IPS, //JB1 FRONT
    input wire JB1_IPS, //JB2 LEFT
    input wire JB2_IPS, //JB3 RIGHT 
    input wire JB3_IPS, //JB4 MID
    
    
    //PAYLOAD DESIGNATION UNIT
    //IR
    input wire JC1_IR,
    //US SENSOR BACK
    output wire JC8_TRIGGER,
    input wire JC7_ECHO,
    //US SENSOR FRONT
    output wire JC10_TRIGGER,
    input wire JC9_ECHO,
    input wire btnC, //temp continue for PDU to be replaced by IR decoding
    
    //MARBLE DELIVERY PORTS
    output wire JB7,
    output wire JB8,
    output wire JB9
    
    );
    
    //RIGHT MOTOR INTERRUPT AND CURRENT DISPLAY DATA
    wire m_interr_right;

    
    //IPS MOTOR CONTROL PINS
    wire IPS_motor_en_l;
    wire IPS_motor_en_r;
    wire IPS_dir_l;
    wire IPS_dir_r;
    wire[6:0] IPS_motor_mode;
         
    reg motor_en_l;
    reg motor_en_r;
    reg dir_l;
    reg dir_r;
    reg[6:0] motor_mode;
    
//#REGION PDU           
    wire[4:0] PDU_STATE;
    wire[3:0] PDU_MARBLE_VAL;

    //these values should match BOX_ID
    localparam DRIVE = 0;
    localparam FRONT_DETECT = 1;
    localparam BACK_DETECT = 2;
    localparam SCANNING = 3;
    localparam DISPENSE = 4;
    
    localparam BOX_DETECT_SPEED = 7'd25; //go slow when finding box
//#ENDREGION
    
    wire[7:0] active_adc_ch;
    wire[15:0] xa_data;
    wire xa_ready;       
    //https://digilent.com/reference/basys3/xadcdemo
    localparam CH6 = 8'h16; //desired xadc channel for left motor
    localparam CH14 = 8'h1E; //desired xadc channel for right motor
    localparam CH7 = 8'h17;  //desired xadc channel for battery voltage
    
    //ADC DATA
    wire[15:0] ch_6;
    wire[15:0] ch_7;
    wire[15:0] ch_14;
    
    ADC_HANDLER adc (
        .clk(sysClk),
        .vauxp6(vauxp6),      .vauxn6(vauxn6), 
        .vauxp14(vauxp14),    .vauxn14(vauxn14), 
        .vauxp7(vauxp7),      .vauxn7(vauxn7), 
        .vauxp15(vauxp15),    .vauxn15(vauxn15),
        .vp_in(vp_in),        .vn_in(vn_in), 
        .channel_out(active_adc_ch),
        .xa_data(xa_data),
        .ready(xa_ready),
        .ch_6(ch_6),
        .ch_7(ch_7),
        .ch_14(ch_14)
    );
    
    //DATA FOR DATA HANDLER WHICH EXPORTS DATA THROUGH I2C
    wire[7:0] battery_volts;
    wire[15:0] d_data_left;
    wire[15:0] d_data_right;
    wire[29:0] us_distance_front;
    wire[29:0] us_distance_back;
    wire front_detected;
    wire back_detected;
    wire[3:0]IR_val;
    wire new_ir_val_flag;
    wire reset_flag;
    wire[59:0] bitstream;
    
    DATA_HANDLER data_handler (
        .data(IR_display_data),
        .clk(sysClk), 
        .dpEnable(4'b1000), 
        .segPorts(seg), 
        .dpPort(dp), 
        .anode(an),
        
        //LEDS TO DEBUG STATE OF CLOCK AND DATA I2C LINES
        .ack_led(led[9]),
        .scl_led(led[8]),
        .sda_led(led[7]),
        
        .sda(JA4_I2C_SDA),
        .scl(JA10_I2C_SCL),
        
        //data to send to esp
        .battery_volts(ch_7[12:5]),
        .curr_left(d_data_left[12:5]),
        .curr_right(d_data_right[12:5]),
        .ips_state(ips_state),
        .pdu_state(PDU_STATE),
        .us_dist_front(us_distance_front),
        .us_dist_back(us_distance_back),
        .process_stream_1(bitstream[7:0]),
        .process_stream_2(bitstream[15:8]),
        .process_stream_3(bitstream[23:16]),
        .decoded_val(IR_val),
        .flags(new_ir_val_flag), //only one flag for now
        .reset_ir_flag(reset_flag)
    );
    
    //#region left_motor
    CURR_CTRL over_curr_left(
        .CURR_CTRL_EN(sw[15]),
        .direction(dir_l),
        .clk(sysClk), 
        .interrupt(m_interr_left), 
        .data(d_data_left), 
        .xa_data(ch_6)
    );
    
    MOTOR_CTRL m_left(
        .enable(sw[0]), 
        .direction(dir_l),
        .interrupt(m_interr_left),
        .mode(motor_mode), 
        .clk(sysClk), 
        .ENA(JA1_ENA),
        .IN1(JA2_IN1),
        .IN2(JA3_IN2)
    );
    //#endregion
    
    
    //#region right_motor
    CURR_CTRL over_curr_right(
        .CURR_CTRL_EN(sw[15]),
        .direction(dir_r),
        .clk(sysClk), 
        .interrupt(m_interr_right), 
        .data(d_data_right), 
        .xa_data(ch_14)
    );
    
    MOTOR_CTRL m_right(
        .enable(sw[0]), 
        .direction(dir_r), 
        .interrupt(m_interr_right),
        .mode(motor_mode), 
        .clk(sysClk), 
        .ENA(JA7_ENB),
        .IN1(JA8_IN3),
        .IN2(JA9_IN4)
    );
    //#endregion
    
    wire[4:0] ips_state;
    assign led[15:11] = ips_state;
    
    //METAL TAPE DETECTING ARRAY
    IPS_ARRAY ips_array(
        .motor_en_l(IPS_motor_en_l),
        .motor_en_r(IPS_motor_en_r),
        .dir_l(IPS_dir_l),
        .dir_r(IPS_dir_r),
        .mode(IPS_motor_mode),
        .m_state(ips_state),
        .clk(sysClk),
        .ips_front(JB0_IPS),
        .ips_left(JB1_IPS),
        .ips_right(JB2_IPS),
        .ips_mid(JB3_IPS)
    );

    wire[19:0] IR_display_data;
    
    //HANDLES ULTRASONIC SENSOR AND IR MORSE DECODING
    BOX_ID PDU (
        .sysClk(sysClk),
        .echo_back(JC9_ECHO),
        .trigger_back(JC10_TRIGGER),
        .echo_front(JC7_ECHO),
        .trigger_front(JC8_TRIGGER),
        .IR_in(JC1_IR),
        .cheat_mode(sw[9]),
        .continue(btnC), //dummy value
        .IR_display_data(IR_display_data),
        .ir_detect(led[2]),
        .marble_val(PDU_MARBLE_VAL),
        .STATE(PDU_STATE),
        .us_distance_front(us_distance_front),
        .us_distance_back(us_distance_back),
        .front_detected(front_detected),
        .back_detected(back_detected),
        .bitstream(bitstream),
        .IR_val(IR_val),
        .new_ir_val_flag(new_ir_val_flag),
        .reset_flag(reset_flag)
    );
    
    //LEDs WILL TURN ON/OFF IF BOX IS DETECTED ON FRONT OR BACK EDGE
    assign led[1] = front_detected;
    assign led[0] = back_detected;
    
    assign led[6:3] = PDU_STATE; //will not keep track of dispense as it will display as 
        
    MB_DELIVER MBD(
        .clk(sysClk),
        //.S_STATE(sw[14:12]),
        .S_STATE(PDU_MARBLE_VAL),
        .Barr1(JB7),
        .Barr2(JB8),
        .Barr3(JB9)
    );

    
    //HANDLE ROVER NAVIGATION BASED ON IPS AND PAYLOAD DESIGNATION UNIT
    always@(posedge sysClk) begin
        
        //THE SECOND SWITCH WILL DISABLE PDU BEHAVIOR
        if(!sw[1]) begin
            case(PDU_STATE)
                DRIVE: begin
                    motor_mode = IPS_motor_mode;
                    motor_en_l = IPS_motor_en_l;
                    motor_en_r = IPS_motor_en_r;
                    dir_l = IPS_dir_l;
                    dir_r = IPS_dir_r;
                end
                FRONT_DETECT: begin
                    motor_mode = BOX_DETECT_SPEED;
                    motor_en_l = 1;
                    motor_en_r = 1;
                    //MOVE FORWARDS
                    dir_l = 0;
                    dir_r = 1;
                end
                BACK_DETECT: begin
                motor_mode = BOX_DETECT_SPEED;
                    motor_en_l = 1;
                    motor_en_r = 1;
                    //MOVE BACKWARDS
                    dir_l = 1;
                    dir_r = 0;
                end
                //OTHERWISE SCANNING OR DISPENSE OR DISABLE IF IMPLEMENTED
                default: begin
                    motor_mode = 1'd0;
                    motor_en_l = 0;
                    motor_en_r = 0;
                    //STATIONARY
                    dir_l = 0;
                    dir_r = 1;
                end
            endcase
         end
         else begin
            motor_mode = IPS_motor_mode;
            motor_en_l = IPS_motor_en_l;
            motor_en_r = IPS_motor_en_r;
            dir_l = IPS_dir_l;
            dir_r = IPS_dir_r;
         end
    end
endmodule
