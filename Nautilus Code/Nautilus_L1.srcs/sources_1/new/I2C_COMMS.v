`timescale 1ns / 1ps


module I2C_COMMS (
    input CLCK, 
    input SCL, 
    inout SDA,
    
    input[159:0] basys_data, //20 bytes of data to send
    output reg[159:0] esp_data, //20 bytes of constants data received from esp
    output reg[10:0] bitcount=5,
    output reg stop,
    output reg ack,
    output reg incycle = 1'b0
    );

    parameter SEND_BYTES = 20; //Num of bytes this module will send to esp
    parameter RECEIVE_BYTES = 20; //Num of bytes this module will receive from esp
    parameter slaveaddress = 7'b1110010; //address = 114
    
    reg[159:0] esp_data_processing=5; //the current esp data being processed
    reg[159:0] send_data;
    reg data_received; //whether data from esp has been fully received
    
    //Sample registers to send to requesting device
    //reg[4:0] valuecnt = 5'd20; //Count of bytes to be sent. Basys will send 20 bytes of info
    
    //Synch SCL edge to the BASYS clock
    reg [2:0] SCLSynch = 3'b000;  
    always @(posedge CLCK) 
        SCLSynch <= {SCLSynch[1:0], SCL};
        
    wire SCL_posedge = (SCLSynch[2:1] == 2'b01);  
    wire SCL_negedge = (SCLSynch[2:1] == 2'b10);  

    //Synch SDA to the BASYS clock
    reg [2:0] SDASynch = 3'b000;
    always @(posedge CLCK) 
        SDASynch <= {SDASynch[1:0], SDA};
        
    wire SDA_synched = SDASynch[0] & SDASynch[1] & SDASynch[2];
    
    //Detect start and stop
    reg start = 1'b0;
    always @(negedge SDA)
        start = SCL;
    always @(posedge SDA)
        stop = SCL;
    
    //Set cycle state 
    //reg incycle = 1'b0;
    always @(posedge start or posedge stop)
        if (start)
        begin
            if (incycle == 1'b0)
                incycle = 1'b1;
        end
        else if (stop)
        begin
            if (incycle == 1'b1)
                incycle = 1'b0;	
        end
        
    //Address and incomming data handling
    //reg[10:0] bitcount = 0;
    reg[4:0] bit_num=1;
    reg[4:0] bit_num_write=1;
    reg [5:0] currRead = 0;
    reg[6:0] address = 7'b0000000;
    //reg[7:0] datain = 8'b00000000;
    reg rw = 1'b0;
    reg addressmatch = 1'b0;
    always @(posedge SCL_posedge or negedge incycle)
       if (~incycle) begin
            //Reset the bit counter at the end of a sequence
            bitcount = 0;
            esp_data = esp_data_processing;//esp data is finalized at end of cycle
            bit_num = 1;
       end
       else begin
            bitcount = bitcount + 1;
            
           //Get the address
            if (bitcount < 8)
                address[7 - bitcount] = SDA_synched;
            
            if (bitcount == 8)
            begin
                rw = SDA_synched;
                addressmatch = (slaveaddress == address) ? 1'b1 : 1'b0;
            end
            
            //READ DATA ONLY WHEN OUT OF ADDRESS PHASE AND NOT WITHIN THE ACK FRAME.  EACH ACK FRAME SHOULD FOLLOW THE 8 BIT READ SEQUENCE
            if ((bitcount > 9) & (~rw) & (bitcount != (currRead)*8 + currRead)) begin
                //Receive data (currently only one byte)
                //esp_data_processing[17 - bitcount] = SDA_synched;
                //esp_data_processing[159 - bitcount] = SDA_synched;
                 esp_data_processing[currRead*8 - bit_num] = SDA_synched; //starts at 159 and counts down
                 bit_num = bit_num > 7 ? 1 : bit_num + 1;
             end
        end
    
    //reg ack=0; //test bench register to see when serial data is driven low
    //ACK's and out going data
    reg sdadata = 1'bz; 
    reg [5:0] write_byte = 	0; //previously currVal.  Value will be 0 during 1st byte and 19 at the 20th byte
    always @(posedge SCL_negedge) begin
        if(~incycle) begin
            //send_data = basys_data; //LATCH IN DATA UP UNTIL DATA IS SENDING
        end
        //set currread to 0 after address phase
        if (bitcount == 8 | ~incycle) begin
            currRead = 0;
            bit_num_write = 1;
            send_data = basys_data; //LATCH IN DATA UP UNTIL DATA IS SENDING
        end
        //ACK's -> ACKNOWLEDGE TO MASTER THAT ADDRESS WAS ACCEPTED
        if ((bitcount == 8) | ((bitcount == (currRead+1)*8 + currRead) & ~rw) & (addressmatch) & incycle)
        //if ((bitcount == 8) | (((bitcount - 8) % 9 == 0) & ~rw) & (addressmatch))
        begin
            sdadata = 1'b0;
            //sdadata = 1'bz; //test
            ack=1;
            currRead = currRead + 1; //move on to reading next value
            write_byte = 0;
        end
        //Data write
        else if ((bitcount >= 9) & (rw) & (addressmatch) & (write_byte < SEND_BYTES) & incycle)
        begin
            //Send Data  
            if (((bitcount - 9) - (write_byte * 9)) == 8) //triggered at end of each byte
            begin
                //Release SDA so master can ACK/NAK
                sdadata = 1'bz;
                write_byte = write_byte + 1;
                ack=0;
            end
            else begin
                //sdadata = basys_data[159 - (bitcount - write_byte - 9)]; //send the bitcounth (subtract 9 due to the first 9 begin address and ack) also subtracts ammount of acks from data
                //sdadata = esp_data_processing[7 - ((bitcount - 9) - (write_byte * 9))]; //Modify this to send actual data, currently echoing incomming data valuecnt times
                sdadata = send_data[(write_byte+1)*8 - bit_num_write];
                //sdadata = 1'bz; //test
                ack=sdadata;
                bit_num_write = bit_num_write > 7 ? 1 : bit_num_write + 1;
            end
        end
        //Nothing (cause nothing tastes like fresca)
        else  begin
            sdadata = 1'bz;
            ack=0;
        end
    end
    
    assign SDA = sdadata;
    
endmodule
