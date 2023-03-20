`timescale 1ms / 1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2023 09:05:23 PM
// Design Name: 
// Module Name: IR_TB
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


module IR_TB();
reg IR_in;
reg clock;
reg enable;
wire val;
wire over;
reg[16:0] value_ONE= 17'b11101110111011101;
reg[14:0] value_TWO= 15'b111011101110101;
reg[12:0] value_THREE= 13'b1110111010101;
reg[10:0] value_SMALL = 11'b11101110101;//Three minus last two bits
reg[18:0] value_LARGE= 19'b0111011101110111010;//One plus a zero on each end
reg[20:0] value_STRANGE= 21'b00011111111111111000;
integer i;
IR_INPUT IR(
    .enable(enable),
    .IR_Pin(IR_in),
    .overflow(over),
    .value(val),
    .clk(clock)
    );
always begin
#1;
clock=~clock;
end
initial begin
clock = 0;
enable = 1;
IR_in = 1;
#60;
IR_in = 0;//000
#180;

for(i = 0; i<17; i=i+1)begin
    IR_in=value_ONE[0];
    #60;
    value_ONE = value_ONE >> 1;
    
    end
IR_in = 0;//000
#1000;
#120;   
enable=0;
#120;   
enable=1;
IR_in = 1;
#60;
IR_in = 0;//000
#180;

for(i = 0; i<15; i=i+1)begin
    IR_in=value_TWO[0];
    #60;
    value_TWO = value_TWO >> 1;
    
    end
IR_in = 0;//000
#180;
#120;   
enable=0;
#120;   
enable=1;
IR_in = 1;
#60;
IR_in = 0;//000
#180;

for(i = 0; i<13; i=i+1)begin
    IR_in=value_THREE[0];
    #60;
    value_THREE = value_THREE >> 1;
    
    end
IR_in = 0;//000
#180;
#120;   
enable=0;
#120;   
enable=1;
IR_in = 1;
#60;
IR_in = 0;//000
#180;

for(i = 0; i<11; i=i+1)begin
    IR_in=value_SMALL[0];
    #60;
    value_SMALL = value_SMALL >> 1;
    
    end
IR_in = 0;//000
#180;
#120;   
enable=0;
#120;   
enable=1;
IR_in = 1;
#60;
IR_in = 0;//000
#180;

for(i = 0; i<19; i=i+1)begin
    IR_in=value_LARGE[0];
    #60;
    value_LARGE = value_LARGE >> 1;
    
    end
IR_in = 0;//000
#180;
#120;   
enable=0;
#120;   
enable=1;
IR_in = 1;
#60;
IR_in = 0;//000
#180;
for(i = 0; i<21; i=i+1)begin
    IR_in=value_STRANGE[0];
    #60;
    value_STRANGE = value_STRANGE >> 1;
    
    end

IR_in = 0;//000
#180;
#120;   
enable=0;
#60;
IR_in = 1;
#60;
IR_in = 0;//000
#180;

end    
endmodule
