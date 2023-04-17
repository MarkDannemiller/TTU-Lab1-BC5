`timescale 1us / 1us
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
wire[3:0] val;
wire over;
reg[16:0] value_ONE= 17'b11101110111011101;
reg[14:0] value_TWO= 15'b111011101110101;
reg[12:0] value_THREE= 13'b1110111010101;
reg[10:0] value_SMALL = 11'b11101110101;//Three minus last two bits
reg[18:0] value_LARGE= 19'b0111011101110111010;//One plus a zero on each end
reg[20:0] value_STRANGE= 21'b00011111111111111000;

localparam MS_TO_UNIT = 1000; //microsecond = 1/1000 of a ms (but clock switches every 2 us)

//SET CLOCK CYCLES PER MS
IR_INPUT #(500) IR(
    .enable(enable),
    .IR_Pin(IR_in),
    .overflow(over),
    .value(val),
    .clk(clock)
    );
    
wire[59:0] process_stream = IR.process_stream;
wire[59:0] bit_stream = IR.bitstream;
wire[16:0] ms_counter = IR.ms_counter; 
wire[11:0] ms_timer = IR.ms_timer;
wire[5:0] bit_index = IR.bit_index;
wire start = IR.start;

wire morse_en = IR.decode_en;
wire morse_ready = IR.morse_ready;
wire dot_match = IR.dot_match;
wire dash_match = IR.dash_match;
wire morse_fallback = IR.morse_fallback;

wire[7:0] shift_counter = IR.decoder.shift_counter;
wire[59:0] temp_stream = IR.decoder.temp_stream;

    
always begin
#1;
clock=~clock;
end

reg[14:0] two_holder;

initial begin

two_holder = value_TWO;

//CONTINUOUS TEST
/*clock = 0;
enable = 0;
IR_in = 0;
#(60 * MS_TO_UNIT)
enable = 1;
#(60 * MS_TO_UNIT)
IR_in = 1;
#(60 * MS_TO_UNIT);
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);

for(i = 0; i<15; i=i+1)begin
    IR_in=value_TWO[0];
    #(60 * MS_TO_UNIT);
    value_TWO = value_TWO >> 1;
    end
IR_in = 0;//000
#(420 * MS_TO_UNIT);
value_TWO = two_holder;

for(integer i = 0; i<15; i=i+1)begin
    IR_in=value_TWO[0];
    #(60 * MS_TO_UNIT);
    value_TWO = value_TWO >> 1;
 end
IR_in = 0;//000
#(420 * MS_TO_UNIT);
value_TWO = two_holder;


for(integer i = 0; i<15; i=i+1)begin
    IR_in=value_TWO[0];
    #(60 * MS_TO_UNIT);
    value_TWO = value_TWO >> 1;
end
IR_in = 0;//000
#(420 * MS_TO_UNIT);
value_TWO = two_holder;


for(integer i = 0; i<15; i=i+1)begin
    IR_in=value_TWO[0];
    #(60 * MS_TO_UNIT);
    value_TWO = value_TWO >> 1;
 end
IR_in = 0;//000
#(420 * MS_TO_UNIT);
value_TWO = two_holder;


for(integer i = 0; i<15; i=i+1)begin
    IR_in=value_TWO[0];
    #(60 * MS_TO_UNIT);
    value_TWO = value_TWO >> 1;
 end
IR_in = 0;//000
#(420 * MS_TO_UNIT);
value_TWO = two_holder;
*/

//ENABLE / REENABLE TEST
clock = 0;
enable = 0;
IR_in = 0;
#(60 * MS_TO_UNIT)
enable = 1;
#(60 * MS_TO_UNIT)
IR_in = 1;
#(60 * MS_TO_UNIT);
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);

for(integer i = 0; i<15; i=i+1)begin
    IR_in=value_TWO[0];
    #(60 * MS_TO_UNIT);
    value_TWO = value_TWO >> 1;
    
    end
IR_in = 0;//000
#(420 * MS_TO_UNIT);
IR_in = 1; //needs to start seeing a new string to begin decoding
#(120 * MS_TO_UNIT);   
enable=0;
IR_in = 0;
#(120 * MS_TO_UNIT);   
enable=1;
IR_in = 1;
#(60 * MS_TO_UNIT);
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);

for(integer i = 0; i<17; i=i+1)begin
    IR_in=value_ONE[0];
    #(60 * MS_TO_UNIT);
    value_ONE = value_ONE >> 1;
    
    end
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);
IR_in = 1; //needs to start seeing a new string to begin decoding
#(120 * MS_TO_UNIT);   
enable=0;
#(120 * MS_TO_UNIT);   
enable=1;
IR_in = 1;
#(60 * MS_TO_UNIT);
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);

for(i = 0; i<13; i=i+1)begin
    IR_in=value_THREE[0];
    #(60 * MS_TO_UNIT);
    value_THREE = value_THREE >> 1;
    
    end
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);
IR_in = 1; //needs to start seeing a new string to begin decoding
#(120 * MS_TO_UNIT);   
enable=0;
IR_in = 0;
#(120 * MS_TO_UNIT);   
enable=1;
IR_in = 1;
#(60 * MS_TO_UNIT);
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);

for(i = 0; i<11; i=i+1)begin
    IR_in=value_SMALL[0];
    #(60 * MS_TO_UNIT);
    value_SMALL = value_SMALL >> 1;
    
    end
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);
IR_in = 1; //needs to start seeing a new string to begin decoding
#(100 * MS_TO_UNIT);   
enable=0;
IR_in = 0;
#(120 * MS_TO_UNIT);   
enable=1;
IR_in = 1;
#(60 * MS_TO_UNIT);
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);

for(i = 0; i<19; i=i+1)begin
    IR_in=value_LARGE[0];
    #(60 * MS_TO_UNIT);
    value_LARGE = value_LARGE >> 1;
    
    end
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);
IR_in = 1; //needs to start seeing a new string to begin decoding
#(120 * MS_TO_UNIT);   
enable=0;
IR_in = 0;
#(120 * MS_TO_UNIT);   
enable=1;
IR_in = 1;
#(60 * MS_TO_UNIT);
IR_in = 0;//0000000
#(420 * MS_TO_UNIT);
for(integer i = 0; i<21; i=i+1)begin
    IR_in=value_STRANGE[0];
    #(60 * MS_TO_UNIT);
    value_STRANGE = value_STRANGE >> 1;
    
    end

IR_in = 0;//0000000
#(420 * MS_TO_UNIT);
IR_in = 1;
#(120 * MS_TO_UNIT);   
enable=0;
IR_in = 0;

end    
endmodule
