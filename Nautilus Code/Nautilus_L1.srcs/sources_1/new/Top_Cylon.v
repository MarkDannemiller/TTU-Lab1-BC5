`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Boat Crew 5
// Engineer: Mark Dannemiller
// 
// Create Date: 01/30/2023 12:37:36 AM
// Design Name: 
// Module Name: Top
// Project Name: CYLON
// Target Devices: BASYS BOARD
// Tool Versions: 
// Description: 
//
//  This module is the top-most module, and bridges the outside I/O with the Verilog modules created for this project
//  Each module contains its own inputs and outputs which are linked by the top module.  In this way, each module
//  can be treated as its own "black box" and diagnosed internally when errors occur.  By modulating the HDL design,
//  we create a system that is easier to look at and similar to Object Oriented Programming.  The only logic that this
//  Top module controls is the loop at the bottom determining which navigation logic to follow based on the state of our
//  bin detection sensors.
//
// 
// Deendencies: 
// 
// Revision: 0.1
// Revision 0.01 - File Created
// Additional Comments:
//
// **Code is free to use as long as you attribute our GitHub repository for others to find the same resources.**
// 
//////////////////////////////////////////////////////////////////////////////////


//Top module loaded for the Cylon platform (Black / Battlestar Galactica version of Nautilus)
module Top_Cylon (

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
    input wire JB3_IPS, //JB4 RIGHT 
    input wire JB2_IPS //JB3 MID
    
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
        .ack_led(),
        .scl_led(),
        .sda_led(),
        
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
        //.led(led)
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
        .ips_right(JB3_IPS),
        .ips_mid(JB2_IPS)
    );

    
    //HANDLE ROVER NAVIGATION BASED ON IPS
    always@(posedge sysClk) begin
            motor_mode = IPS_motor_mode;
            motor_en_l = IPS_motor_en_l;
            motor_en_r = IPS_motor_en_r;
            dir_l = IPS_dir_l;
            dir_r = ~IPS_dir_r;
    end
endmodule
