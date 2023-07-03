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
// This is a super easy to implement PWM module.  You can choose either the 7 bit control mode below or a 4 bit control mode
// and attach the mode to 4 switches on the Basys for easy testing of 16 different speeds.  The advantage of the 7 bit mode
// is that the inputted mode in decimal form directly corresponds to the duty cycle that the module will output!
//
// The frequency can be changed from 100hz directly in this file, or see the "Marble Delivery" module for an example of how to change it
// on a use-by use basis.  This module is implemented in the "Motor Control" and "Marble Delivery" modules.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//PWM MODULE THAT CONVERTS THE 100MHZ TO 100HZ
//FREQ = Output frequency of this module
module PWM_SRC #(parameter FREQ = 100)(input clk, input [6:0] mode, output pwm);

    wire[21:0] p_duty; 
    reg[21:0] count; //, n_count;
    reg PWM_REG;

    assign pwm = PWM_REG;
    
    //Another method that uses a 4 bit control instead of 7 bit (useful because you can utilize 4 switches to test)
    /*assign p_duty = (mode==4'b0000)? 21'd0*(100000000/FREQ)/100:
                    (mode==4'b0001)? 21'd16*(100000000/FREQ)/100:
                    (mode==4'b0010)? 21'd22*(100000000/FREQ)/100:
                    (mode==4'b0011)? 21'd28*(100000000/FREQ)/100:
                    (mode==4'b0100)? 21'd34*(100000000/FREQ)/100:
                    (mode==4'b0101)? 21'd40*(100000000/FREQ)/100:
                    (mode==4'b0110)? 21'd46*(100000000/FREQ)/100:
                    (mode==4'b0111)? 21'd52*(100000000/FREQ)/100:
                    (mode==4'b1000)? 21'd58*(100000000/FREQ)/100:
                    (mode==4'b1001)? 21'd64*(100000000/FREQ)/100:
                    (mode==4'b1010)? 21'd70*(100000000/FREQ)/100:
                    (mode==4'b1011)? 21'd76*(100000000/FREQ)/100:
                    (mode==4'b1100)? 21'd82*(100000000/FREQ)/100:
                    (mode==4'b1101)? 21'd88*(100000000/FREQ)/100:
                    (mode==4'b1110)? 21'd94*(100000000/FREQ)/100:
                    (mode==4'b1111)? 21'd100*(100000000/FREQ)/100:
                    21'd0;*/

    //This control scheme means that the decimal input is directly the duty percent of the signal
     assign p_duty = (mode==7'd0)? 21'd0*(100000000/FREQ)/100:
                    (mode==7'd1)? 21'd1*(100000000/FREQ)/100:
                    (mode==7'd2)? 21'd2*(100000000/FREQ)/100:
                    (mode==7'd3)? 21'd3*(100000000/FREQ)/100:
                    (mode==7'd4)? 21'd4*(100000000/FREQ)/100:
                    (mode==7'd5)? 21'd5*(100000000/FREQ)/100:
                    (mode==7'd6)? 21'd6*(100000000/FREQ)/100:
                    (mode==7'd7)? 21'd7*(100000000/FREQ)/100:
                    (mode==7'd8)? 21'd8*(100000000/FREQ)/100:
                    (mode==7'd9)? 21'd9*(100000000/FREQ)/100:
                    (mode==7'd10)? 21'd10*(100000000/FREQ)/100:
                    (mode==7'd11)? 21'd11*(100000000/FREQ)/100:
                    (mode==7'd12)? 21'd12*(100000000/FREQ)/100:
                    (mode==7'd13)? 21'd13*(100000000/FREQ)/100:
                    (mode==7'd14)? 21'd14*(100000000/FREQ)/100:
                    (mode==7'd15)? 21'd15*(100000000/FREQ)/100:
                    (mode==7'd16)? 21'd16*(100000000/FREQ)/100:
                    (mode==7'd17)? 21'd17*(100000000/FREQ)/100:
                    (mode==7'd18)? 21'd18*(100000000/FREQ)/100:
                    (mode==7'd19)? 21'd19*(100000000/FREQ)/100:
                    (mode==7'd20)? 21'd20*(100000000/FREQ)/100:
                    (mode==7'd21)? 21'd21*(100000000/FREQ)/100:
                    (mode==7'd22)? 21'd22*(100000000/FREQ)/100:
                    (mode==7'd23)? 21'd23*(100000000/FREQ)/100:
                    (mode==7'd24)? 21'd24*(100000000/FREQ)/100:
                    (mode==7'd25)? 21'd25*(100000000/FREQ)/100:
                    (mode==7'd26)? 21'd26*(100000000/FREQ)/100:
                    (mode==7'd27)? 21'd27*(100000000/FREQ)/100:
                    (mode==7'd28)? 21'd28*(100000000/FREQ)/100:
                    (mode==7'd29)? 21'd29*(100000000/FREQ)/100:
                    (mode==7'd30)? 21'd30*(100000000/FREQ)/100:
                    (mode==7'd31)? 21'd31*(100000000/FREQ)/100:
                    (mode==7'd32)? 21'd32*(100000000/FREQ)/100:
                    (mode==7'd33)? 21'd33*(100000000/FREQ)/100:
                    (mode==7'd34)? 21'd34*(100000000/FREQ)/100:
                    (mode==7'd35)? 21'd35*(100000000/FREQ)/100:
                    (mode==7'd36)? 21'd36*(100000000/FREQ)/100:
                    (mode==7'd37)? 21'd37*(100000000/FREQ)/100:
                    (mode==7'd38)? 21'd38*(100000000/FREQ)/100:
                    (mode==7'd39)? 21'd39*(100000000/FREQ)/100:
                    (mode==7'd40)? 21'd40*(100000000/FREQ)/100:
                    (mode==7'd41)? 21'd41*(100000000/FREQ)/100:
                    (mode==7'd42)? 21'd42*(100000000/FREQ)/100:
                    (mode==7'd43)? 21'd43*(100000000/FREQ)/100:
                    (mode==7'd44)? 21'd44*(100000000/FREQ)/100:
                    (mode==7'd45)? 21'd45*(100000000/FREQ)/100:
                    (mode==7'd46)? 21'd46*(100000000/FREQ)/100:
                    (mode==7'd47)? 21'd47*(100000000/FREQ)/100:
                    (mode==7'd48)? 21'd48*(100000000/FREQ)/100:
                    (mode==7'd49)? 21'd49*(100000000/FREQ)/100:
                    (mode==7'd50)? 21'd50*(100000000/FREQ)/100:
                    (mode==7'd51)? 21'd51*(100000000/FREQ)/100:
                    (mode==7'd52)? 21'd52*(100000000/FREQ)/100:
                    (mode==7'd53)? 21'd53*(100000000/FREQ)/100:
                    (mode==7'd54)? 21'd54*(100000000/FREQ)/100:
                    (mode==7'd55)? 21'd55*(100000000/FREQ)/100:
                    (mode==7'd56)? 21'd56*(100000000/FREQ)/100:
                    (mode==7'd57)? 21'd57*(100000000/FREQ)/100:
                    (mode==7'd58)? 21'd5*(100000000/FREQ)/100:
                    (mode==7'd59)? 21'd59*(100000000/FREQ)/100:
                    (mode==7'd60)? 21'd60*(100000000/FREQ)/100:
                    (mode==7'd61)? 21'd61*(100000000/FREQ)/100:
                    (mode==7'd62)? 21'd62*(100000000/FREQ)/100:
                    (mode==7'd63)? 21'd63*(100000000/FREQ)/100:
                    (mode==7'd64)? 21'd64*(100000000/FREQ)/100:
                    (mode==7'd65)? 21'd65*(100000000/FREQ)/100:
                    (mode==7'd66)? 21'd66*(100000000/FREQ)/100:
                    (mode==7'd67)? 21'd67*(100000000/FREQ)/100:
                    (mode==7'd68)? 21'd68*(100000000/FREQ)/100:
                    (mode==7'd69)? 21'd69*(100000000/FREQ)/100: //nice
                    (mode==7'd70)? 21'd70*(100000000/FREQ)/100:
                    (mode==7'd71)? 21'd71*(100000000/FREQ)/100:
                    (mode==7'd72)? 21'd72*(100000000/FREQ)/100:
                    (mode==7'd73)? 21'd73*(100000000/FREQ)/100:
                    (mode==7'd74)? 21'd74*(100000000/FREQ)/100:
                    (mode==7'd75)? 21'd75*(100000000/FREQ)/100:
                    (mode==7'd76)? 21'd76*(100000000/FREQ)/100:
                    (mode==7'd77)? 21'd77*(100000000/FREQ)/100:
                    (mode==7'd78)? 21'd78*(100000000/FREQ)/100:
                    (mode==7'd79)? 21'd79*(100000000/FREQ)/100:
                    (mode==7'd80)? 21'd80*(100000000/FREQ)/100:
                    (mode==7'd81)? 21'd81*(100000000/FREQ)/100:
                    (mode==7'd82)? 21'd82*(100000000/FREQ)/100:
                    (mode==7'd83)? 21'd83*(100000000/FREQ)/100:
                    (mode==7'd84)? 21'd84*(100000000/FREQ)/100:
                    (mode==7'd85)? 21'd85*(100000000/FREQ)/100:
                    (mode==7'd86)? 21'd86*(100000000/FREQ)/100:
                    (mode==7'd87)? 21'd87*(100000000/FREQ)/100:
                    (mode==7'd88)? 21'd88*(100000000/FREQ)/100:
                    (mode==7'd89)? 21'd89*(100000000/FREQ)/100:
                    (mode==7'd90)? 21'd90*(100000000/FREQ)/100:
                    (mode==7'd91)? 21'd91*(100000000/FREQ)/100:
                    (mode==7'd92)? 21'd92*(100000000/FREQ)/100:
                    (mode==7'd93)? 21'd93*(100000000/FREQ)/100:
                    (mode==7'd94)? 21'd94*(100000000/FREQ)/100:
                    (mode==7'd95)? 21'd95*(100000000/FREQ)/100:
                    (mode==7'd96)? 21'd96*(100000000/FREQ)/100:
                    (mode==7'd97)? 21'd97*(100000000/FREQ)/100:
                    (mode==7'd98)? 21'd98*(100000000/FREQ)/100:
                    (mode==7'd99)? 21'd99*(100000000/FREQ)/100:
                    (mode==7'd100)? 21'd100*(100000000/FREQ)/100:
                    21'd0;
                
    initial begin
        count = 0;
    end
                
    always @ (posedge clk)
    begin
        count = count + 1;
        if (count < p_duty) begin
            PWM_REG <= 1;
        end
        else if (count < 100000000/FREQ) begin
            PWM_REG <= 0;
        end
        else begin
            count = 0;
        end
    end

endmodule
