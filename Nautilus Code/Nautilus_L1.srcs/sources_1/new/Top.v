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
    //output wire[7:0] JA,
    
    output wire JA1_ENA,
    output wire JA2_IN1,
    output wire JA3_IN2,
    output wire JA7_ENB,
    output wire JA8_IN3,
    output wire JA9_IN4,
    
    inout wire JA4_I2C_SDA,
    inout wire JA10_I2C_SCL,

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
   
    
    //LEFT MOTOR: PMOD PINS 5, 6, 11, 12 ARE VCC AND GNDS
    /*parameter ENA_PMOD = 0; //PIN 1
    parameter IN1_PMOD = 1; //PIN 2
    parameter IN2_PMOD = 2; //PIN 3        
    //LEFT MOTOR INTERRUPT AND CURRENT DISPLAY DATA
    wire m_interr_left;
    wire[19:0] d_data_left;
    
    //RIGHT MOTOR: PMOD PINS 5, 6, 11, 12 ARE VCC AND GNDS
    parameter ENB_PMOD = 4; //PIN 7
    parameter IN3_PMOD = 5; //PIN 8
    parameter IN4_PMOD = 6; //PIN 9
    
    localparam I2C_SDA = 3; //PIN 4
    localparam I2C_SCL = 7; //PIN 10*/
    
    //RIGHT MOTOR INTERRUPT AND CURRENT DISPLAY DATA
    wire m_interr_right;
    wire[19:0] d_data_right;
    
        
    //https://digilent.com/reference/basys3/xadcdemo
    localparam CH6 = 8'h16; //desired xadc channel for left motor
    localparam CH14 = 8'h1E; //desired xadc channel for right motor
    localparam CH7 = 8'h17; 
    
    //IPS MOTOR CONTROL PINS
    wire IPS_motor_en_l;
    wire IPS_motor_en_r;
    wire IPS_dir_l;
    wire IPS_dir_r;
    wire[3:0] IPS_motor_mode;
         
    reg motor_en_l;
    reg motor_en_r;
    reg dir_l;
    reg dir_r;
    reg[3:0] motor_mode;
    
//#REGION PDU           
    wire[4:0] PDU_STATE;
    wire[3:0] PDU_MARBLE_VAL;
    
    //these values should match BOX_ID
    localparam DRIVE = 0;
    localparam FRONT_DETECT = 1;
    localparam BACK_DETECT = 2;
    localparam SCANNING = 3;
    localparam DISPENSE = 4;
    
    localparam BOX_DETECT_SPEED = 4'd3; //go slow when finding box
    
    assign led[10:7] = motor_mode;
    //wire[3:0] ips_state;
//#ENDREGION
    
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
        
        wire[19:0] IR_display_data;
    
        DATA_HANDLER data_handler (
        //.data(d_data_left), 
        //.data(us_data),
        .data(IR_display_data),
        .clk(sysClk), 
        .dpEnable(4'b1000), 
        .segPorts(seg), 
        .dpPort(dp), 
        .anode(an),
        
        .sda(JA4_I2C_SDA),
        .scl(JA10_I2C_SCL)
    );
    
    //#region left_motor
    CURR_CTRL over_curr_left(
        .CURR_CTRL_EN(sw[15]),
        //.direction(sw[5]),
        .direction(dir_l),
        .clk(sysClk), 
        .interrupt(m_interr_left), 
        .data(d_data_left), 
        //.led(dummy_led_left),
        .raw_xa_data(xa_data),
        .xa_channel(active_adc_ch),
        .m_channel(CH6),
        .xa_ready(xa_ready)
    );
    
    MOTOR_CTRL m_left(
        .enable(sw[0]), 
        //.direction(sw[5]), 
        //.enable(motor_en_l), 
        .direction(dir_l),
        .interrupt(m_interr_left),
        //.mode(sw[3:0]),
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
        //.direction(sw[7]),
        .direction(dir_r),
        .clk(sysClk), 
        .interrupt(m_interr_right), 
        .data(d_data_right), 
        //.led(dummy_led),
        .raw_xa_data(xa_data),
        .xa_channel(active_adc_ch),
        .m_channel(CH14),
        .xa_ready(xa_ready)
    );
    
    MOTOR_CTRL m_right(
        .enable(sw[0]), 
        //.direction(sw[7]), 
        //.enable(motor_en_r), 
        .direction(dir_r), 
        .interrupt(m_interr_right),
        //.mode(sw[3:0]),
        .mode(motor_mode), 
        .clk(sysClk), 
        .ENA(JA7_ENB),
        .IN1(JA8_IN3),
        .IN2(JA9_IN4)
    );
    //#endregion
    
    IPS_ARRAY ips_array(
        .motor_en_l(IPS_motor_en_l),
        .motor_en_r(IPS_motor_en_r),
        .dir_l(IPS_dir_l),
        .dir_r(IPS_dir_r),
        .mode(IPS_motor_mode),
        .m_state(led[15:11]),
        .clk(sysClk),
        .ips_front(JB0_IPS),
        .ips_left(JB1_IPS),
        .ips_right(JB2_IPS),
        .ips_mid(JB3_IPS)
    );
        
    BOX_ID PDU (
        .sysClk(sysClk),
        .echo_back(JC9_ECHO),
        .trigger_back(JC10_TRIGGER),
        .echo_front(JC7_ECHO),
        .trigger_front(JC8_TRIGGER),
        .IR_in(JC1_IR),
        .continue(btnC), //dummy value
        .us_distance(us_distance),
        .front_detected(led[1]),
        .back_detected(led[0]),
        .IR_display_data(IR_display_data),
        .ir_detect(led[2]),
        .marble_val(PDU_MARBLE_VAL),
        .STATE(PDU_STATE)
    );
    
    assign led[6:3] = PDU_STATE; //will not keep track of dispense as it will display as 
        
    MB_DELIVER MBD(
        .clk(sysClk),
        //.S_STATE(sw[14:12]),
        .S_STATE(PDU_MARBLE_VAL),
        .Barr1(JB7),
        .Barr2(JB8),
        .Barr3(JB9)
    );

    
    //HANDLE ROVER NAVIGATION BASED ON IPS RIGH AND PAYLOAD DESIGNATION UNIT
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
