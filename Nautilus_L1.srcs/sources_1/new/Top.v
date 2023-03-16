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
    output wire[7:0] JA,
    
    //IR
    output wire JB_7,
    input wire JB0_IPS,
    input wire JB1_IPS,
    input wire JB2_IPS,
    input wire JB3_IPS,
    input wire JB_IR,
    
    //US SENSOR
    output wire JB_TRIGGER,
    input wire JB_ECHO,
    
    //MARBLE DELIVERY PORTS
    output wire[7:0] JC
    
    );
    
    
    
    //LEFT MOTOR: PMOD PINS 5, 6, 11, 12 ARE VCC AND GNDS
    parameter ENA_PMOD = 0; //PIN 1
    parameter IN1_PMOD = 1; //PIN 2
    parameter IN2_PMOD = 2; //PIN 3        
    //LEFT MOTOR INTERRUPT AND CURRENT DISPLAY DATA
    wire m_interr_left;
    wire[19:0] d_data_left;
    
    //RIGHT MOTOR: PMOD PINS 5, 6, 11, 12 ARE VCC AND GNDS
    parameter ENB_PMOD = 4; //PIN 7
    parameter IN3_PMOD = 5; //PIN 8
    parameter IN4_PMOD = 6; //PIN 9
    //RIGHT MOTOR INTERRUPT AND CURRENT DISPLAY DATA
    wire m_interr_right;
    wire[19:0] d_data_right;
    
        
    localparam CH6 = 8'h16; //desired xadc channel for left motor
    localparam CH7 = 8'h17; //desired xadc channel for right motor
    
    wire motor_en_l;
    wire motor_en_r;
    wire dir_l;
    wire dir_r;
    wire[3:0] ips_motor_mode;
    
    assign led[10:7] = ips_motor_mode;
    //wire[3:0] ips_state;
    
    //parameter adc_channel = 8'h16; //XA1 (XADC CHANNEL 6)
    wire[7:0] active_adc_ch;
    wire[15:0] xa_data;
    wire xa_ready;
    
    //0=XA1_P ; 4=XA1_N (XADC CHANNEL 6)
    ADC_HANDLER adc (
        .clk(sysClk),
        .vauxp6(vauxp6),      .vauxn6(vauxn6), 
        .vauxp14(vauxp14),    .vauxn14(vauxn14), 
        .vauxp7(vauxp7),      .vauxn7(vauxn7), 
        .vauxp15(vauxp15),    .vauxn15(vauxn15),
        .vp_in(vp_in),        .vn_in(vn_in), 
        .channel_out(active_adc_ch),
        .xa_data(xa_data),
        .ready(xa_ready)
    );
          
        //WIRE AND REG FOR DISPLAYING ULTRASONIC DATA 
        wire[29:0] us_distance;
        wire[19:0] us_data;
        assign us_data[19] = 1;
        assign us_data[18:15] = us_distance[15:12];
        assign us_data[14] = 1;
        assign us_data[13:10] = us_distance[11:8];
        assign us_data[9] = 1;
        assign us_data[8:5] = us_distance[7:4];
        assign us_data[4] = 1;  
        assign us_data[3:0] = us_distance[3:0];
    
        DISPLAY curr_display(
        //.data(d_data_left), 
        .data(us_data),
        .clk(sysClk), 
        .dpEnable(4'b1000), 
        .segPorts(seg), 
        .dpPort(dp), 
        .anode(an)
    );
    
    wire[15:0] dummy_led_left;
    
    //#region left_motor
    CURR_CTRL over_curr_left(
        .CURR_CTRL_EN(sw[15]),
        //.direction(sw[5]),
        .direction(dir_l),
        .clk(sysClk), 
        .interrupt(m_interr_left), 
        .data(d_data_left), 
        .led(dummy_led_left),
        .raw_xa_data(xa_data),
        .xa_channel(active_adc_ch),
        .m_channel(CH6),
        .xa_ready(xa_ready)
    );
    
    MOTOR_CTRL m_left(
        .enable(sw[4]), 
        //.direction(sw[5]), 
        //.enable(motor_en_l), 
        .direction(dir_l),
        .interrupt(m_interr_left),
        //.mode(sw[3:0]),
        .mode(ips_motor_mode), 
        .clk(sysClk), 
        .ENA(JA[ENA_PMOD]),
        .IN1(JA[IN1_PMOD]),
        .IN2(JA[IN2_PMOD])
    );
    //#endregion

    wire[15:0] dummy_led; //led with no purpose since right motor is disconnected from the basys display

    //#region right_motor
    CURR_CTRL over_curr_right(
        .CURR_CTRL_EN(sw[15]),
        //.direction(sw[7]),
        .direction(dir_r),
        .clk(sysClk), 
        .interrupt(m_interr_right), 
        .data(d_data_right), 
        .led(dummy_led),
        .raw_xa_data(xa_data),
        .xa_channel(active_adc_ch),
        .m_channel(CH7),
        .xa_ready(xa_ready)
    );
    
    MOTOR_CTRL m_right(
        .enable(sw[6]), 
        //.direction(sw[7]), 
        //.enable(motor_en_r), 
        .direction(dir_r), 
        .interrupt(m_interr_right),
        //.mode(sw[3:0]),
        .mode(ips_motor_mode), 
        .clk(sysClk), 
        .ENA(JA[ENB_PMOD]),
        .IN1(JA[IN3_PMOD]),
        .IN2(JA[IN4_PMOD])
    );
    //#endregion
    
    IPS_ARRAY ips_array(
        .motor_en_l(motor_en_l),
        .motor_en_r(motor_en_r),
        .dir_l(dir_l),
        .dir_r(dir_r),
        .mode(ips_motor_mode),
        .m_state(led[15:11]),
        .clk(sysClk),
        .ips_front(JB0_IPS),
        .ips_left(JB1_IPS),
        .ips_right(JB2_IPS),
        .ips_mid(JB3_IPS)
    );
    
    US_SENSOR us_sens(
        .clk(sysClk),
        .echo_pin(JB_ECHO),
        .trigger(JB_TRIGGER),
        .detected(led[0]),
        .distance(us_distance)
    );

//#endregion
//    IR_INPUT IR (
//        .clk(sysClk),
//        .IR_Pin(JB_IR),
//        .LED(JB[1]));
        
    MB_DELIVER MBD(
        .clk(sysClk),
        .S_STATE(sw[14:12]),
        .Bar1(JC[0]),
        .Bar2(JC[1]),
        .Bar3(JC[2])
    );
endmodule
