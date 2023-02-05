`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2023 12:07:17 AM
// Design Name: 
// Module Name: PWM_SRC
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

//PWM MODULE THAT CONVERTS THE 100MHZ TO 100HZ
module PWM_SRC (input clk, input [3:0] mode, output pwm);

    //parameter pwm2system = 2; //SET GLOBAL FREQUENCY CONVERSION FOR MODULE HERE (set to 1000000 for 100hz, 10 for test)
    parameter pwm2system = 10000; //SET GLOBAL FREQUENCY CONVERSION FOR MODULE HERE (set to 1000000 for 100hz, 10 for test)
    parameter s = pwm2system == 0 ? 1 : $clog2(2 * pwm2system * 100); //DYNAMIC SIZING FOR FREQUENCY

    wire[21:0] p_duty; 
    reg[21:0] count; //, n_count;
    reg PWM_REG;

    assign pwm = PWM_REG;
    assign p_duty = (mode==4'b0000)? 21'd0*pwm2system: //6
                    (mode==4'b0001)? 21'd16*pwm2system:
                    (mode==4'b0010)? 21'd22*pwm2system:
                    (mode==4'b0011)? 21'd28*pwm2system:
                    (mode==4'b0100)? 21'd34*pwm2system:
                    (mode==4'b0101)? 21'd40*pwm2system:
                    (mode==4'b0110)? 21'd46*pwm2system:
                    (mode==4'b0111)? 21'd52*pwm2system:
                    (mode==4'b1000)? 21'd58*pwm2system:
                    (mode==4'b1001)? 21'd64*pwm2system:
                    (mode==4'b1010)? 21'd70*pwm2system:
                    (mode==4'b1011)? 21'd76*pwm2system:
                    (mode==4'b1100)? 21'd82*pwm2system:
                    (mode==4'b1101)? 21'd88*pwm2system:
                    (mode==4'b1110)? 21'd94*pwm2system:
                    (mode==4'b1111)? 21'd100*pwm2system:
                    21'd0;
                
    initial begin
        count = 0;
    end
                
    always @ (posedge clk)
    begin
        count = count + 1;
        if (count < p_duty) begin
            PWM_REG = 1;
        end
        else if (count < pwm2system * 100) begin
            PWM_REG = 0;
        end
        else begin
            count = 0;
        end
    end

endmodule




/*        DEPRECATED USE OF P_DUTY AND N_DUTY       
assign n_duty = (mode==4'b0000)? 21'd94*pwm2system:
                (mode==4'b0001)? 21'd88*pwm2system:
                (mode==4'b0010)? 21'd82*pwm2system:
                (mode==4'b0011)? 21'd76*pwm2system:
                (mode==4'b0100)? 21'd70*pwm2system:
                (mode==4'b0101)? 21'd64*pwm2system:
                (mode==4'b0110)? 21'd58*pwm2system:
                (mode==4'b0111)? 21'd52*pwm2system:
                (mode==4'b1000)? 21'd46*pwm2system:
                (mode==4'b1001)? 21'd40*pwm2system:
                (mode==4'b1010)? 21'd34*pwm2system:
                (mode==4'b1011)? 21'd28*pwm2system:
                (mode==4'b1100)? 21'd22*pwm2system:
                (mode==4'b1101)? 21'd16*pwm2system:
                (mode==4'b1110)? 21'd10*pwm2system:
                (mode==4'b1111)? 21'd4*pwm2system:
                21'd0;*/