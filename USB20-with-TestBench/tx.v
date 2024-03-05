`timescale 1ns / 10ps


module tx(
	clock, reset, SYN_GEN_LD, halt_tx_shift, TX_LOAD, TX_DATA, CRC_16, 
        TX_LAST_BYTE, TDO, TCS, TX_READY_LD, T_lastbit, 
        shift_tx_crc16, shift_tx_crc5);

input CRC_16 ;                   // = 1 If 16 bits CRC, 0 other. 
output  shift_tx_crc16, shift_tx_crc5;
input clock; 			//global chip clock
input reset;			//system reset; global; active low
input SYN_GEN_LD;		//load sync pattern into shifter
input TX_LOAD;		        //tx load data in
input halt_tx_shift;		//halt tx data shifter while stuffing 0
inout [7:0] TX_DATA;	        //transmit data in; 1 byte each time
input TX_LAST_BYTE;             // the last byte come from controller 
                                // this last byte will be delay untill last 
                                // bit of byte is transmit to serial port

output T_lastbit;             // the last byte come to  bit stuff block. this signal is 
                               // delay until last bit of byte is send to serial port 
output TDO;		//tx shifter data out; 1 bit
output TCS;
output TX_READY_LD;
wire TCS;
wire T_lastbit1; 
reg  T_lastbit2;

reg [7:0] shifter1;		// shift register I assume cost is not an issue, 
reg [7:0] shifter2;		// shift register I assume cost is not an issue, 
                                // shift when  we send CRC15 
reg[4:0] cnt_shift1;            // This is 5 bits counter to count the data shift 
                                // from 0 to 15 for CRC15
reg[4:0] cnt_shift2;            // This is 5 bits counter to count the data shift 
                                // from 0 to 15 for CRC15
wire TX_READY_LD ;              // Send to host for ready to read new data.
reg last_byte_flag;
                                // The counter will reset when it count to 8 for 
                                // normal byte and 5'd16 for CRC15

reg[3:0] CRC_cnt;
reg CRC_flag;
wire CRC_done, shift_tx_crc16, shift_tx_crc5;

wire shift1_done;                // shift1 finish to shift and waiting for load new data
wire shift2_done;                // shift2 finish to shift and waiting for load new data
wire shift1_active_ser;          // shift1 is shifting, we only can down load data to shift2 
wire shift2_active_ser;          // shift2 is shifting, we only can down load data to shift1 
wire shift1_active_par;          // shift1 is shifting, we only can down load data to shift2 
wire shift2_active_par;          // shift2 is shifting, we only can down load data to shift1 
reg active_ser_shift2_shift1_z;  // this bit = 1; => Shift2 is shifting, we need to wait until
                                // shift2_done signal active, this register will toggle to 0
                                // and we begin to shift out data from shift1. This register
                                // also control the MUX for data tx_shift_out from bit 0 of shiter1 or
                                // This is used in serial side, it will half cycle early than parallel size
                                // to avoid half cycle glitch on CS
reg active_par_shift2_shift1_z;  // this bit = 1; => Shift2 is shifting, half cycle delay compare with 
                                 // active_ser_shift2_shift1_z 
                               
                                // shift2. default this value will be 0
reg shift1_wait_shift;          // 1 : Shift1 ready down load data and waiting to shift we can not down load new data at this time
                                // 0 : Can down load to shift1 register. if both shift1_wait_shift and shift2_wait_shift = 0 =>
                                //     shift1 have higher priority.
reg shift2_wait_shift;          // 1 : Shift2 ready down load data and waiting to shift we can not down load new data at this time
                                // 0 : wait load data to shift2 regiter.
    assign shift1_active_ser = (shift1_wait_shift  & !active_ser_shift2_shift1_z);
    assign shift2_active_ser = (shift2_wait_shift  &  active_ser_shift2_shift1_z);
    assign shift1_active_par = (shift1_wait_shift  & !active_par_shift2_shift1_z);
    assign shift2_active_par = (shift2_wait_shift  &  active_par_shift2_shift1_z);
    assign TX_READY_LD           = ((!shift1_wait_shift | !shift2_wait_shift) & !halt_tx_shift);

     always@(posedge clock or posedge reset)
          begin
            if(reset)
                begin
                  shift1_wait_shift <= 0;
                  shift2_wait_shift <= 0;
                end
            else if((TX_LOAD  | SYN_GEN_LD) & !shift1_wait_shift)     // shift1_wait_shift have higher priority than shift2_wait_shift
                begin
                  shift1_wait_shift <= #1 1;
                  shift2_wait_shift <= #1 shift2_wait_shift;
                end
            else if(TX_LOAD & !shift2_wait_shift)     // shift1_wait_shift have higher priority than shift2_wait_shift
                begin
                  shift2_wait_shift <= #1 1;
                  shift1_wait_shift <= #1 shift1_wait_shift;
                end
            else if(shift1_done)
                begin
                  shift1_wait_shift <= #1 0;
                  shift2_wait_shift <= #1 shift2_wait_shift;
                end
            else if(shift2_done)
                begin
                  shift2_wait_shift <= #1 0;
                  shift1_wait_shift <= #1 shift1_wait_shift;
                end
            else
                begin
                  shift1_wait_shift <= #1 shift1_wait_shift;
                  shift2_wait_shift <= #1 shift2_wait_shift;
                end
          end


     always@(posedge clock or posedge reset)
      begin
        if(reset)
           active_ser_shift2_shift1_z <= 0;
        else if(shift2_done)
           active_ser_shift2_shift1_z <= #1 0;
        else if(shift1_done)
           active_ser_shift2_shift1_z <= #1 1;
        else active_ser_shift2_shift1_z <= #1 active_ser_shift2_shift1_z;
      end
      always@(negedge clock)
       begin
         active_par_shift2_shift1_z <= #1 active_ser_shift2_shift1_z;
      // Serial port need half cycle early to avoid the glitch on CRC
       end
   


always @(posedge clock or posedge reset)
  if (reset)
         shifter1[7:0] <= #1 8'h00;
  else if (halt_tx_shift)                          // halt 
         shifter1[7:0] <= #1 shifter1;
  else if (SYN_GEN_LD)                            // Sync alway generate from shift1
         shifter1[7:0] <= #1 8'h80;	           // opposite to 8'h80
  else if (TX_LOAD & !shift1_wait_shift)           // LOAD DATA IN  
         shifter1[7:0] <= #1 TX_DATA;
  else if (shift1_active_par)                          // Shift left data  QY
    shifter1[7:0] <= #1 {1'b0, shifter1[7:1]};		
  else
         shifter1 <= #1 shifter1;



always @(posedge clock or posedge reset)
  if (reset)
         shifter2[7:0] <= #1 8'h00;
  else if (halt_tx_shift)                          // halt 
         shifter2[7:0] <= #1 shifter2;
  else if (TX_LOAD & !shift2_wait_shift & shift1_wait_shift)          //  LOAD DATA IN 
         shifter2[7:0] <= #1 TX_DATA;
  else if (shift2_active_par)                           // Shift left data 
    shifter2[7:0] <= #1 {1'b0, shifter2[7:1]};		
  else
         shifter2 <= #1 shifter2;


assign TDO = (active_ser_shift2_shift1_z)? shifter2[0] : shifter1[0];   // Shift out to serial port

always @(negedge clock or posedge reset)     // We use Negative clock edge for count the shift
  if (reset)
      cnt_shift1 <= 4'h0;
  else if(halt_tx_shift)
      cnt_shift1 <= #1 cnt_shift1;                 // Halt the transmit. Halt will have high priority than shift_data
  else if(shift1_active_ser)
      cnt_shift1 <= #1 cnt_shift1 + 1;             // Count for data shift out 
  else if(shift1_done)
      cnt_shift1 <= #1 4'h0;                      // Shift old byte done, begin active ack signal for write new byte 
 
always @(negedge clock or posedge reset)     // We use Negative clock edge for count the shift
  if (reset)
      cnt_shift2 <= 4'h0;
  else if(halt_tx_shift)
      cnt_shift2 <= #1 cnt_shift2;                 // Halt the transmit. Halt will have high priority than shift_data
  else if(shift2_active_ser)
      cnt_shift2 <= #1 cnt_shift2 + 1;             // Count for data shift out 
  else if(shift2_done)
      cnt_shift2 <= #1 4'h0;                      // Shift old byte done, begin active ack signal for write new byte 
 
 assign TCS = (shift1_active_ser | shift2_active_ser);
 assign shift1_done = (cnt_shift1 == 5'h08);
                                                                                                    // to 16 with CRC15 we begin to reset 
                                                                                                    // shift1 system.
 assign shift2_done = (cnt_shift2 == 5'h08) ;
                                                                                                    // to 16 with CRC15 we begin to reset 
                                                                                                    // shift1 system.


 always@(posedge clock or posedge reset)
        if(reset)
          begin
             last_byte_flag <= 0;
          end
        else if (TX_LAST_BYTE)
          begin
             last_byte_flag <= #1 1;
          end
        else if (TX_LAST_BYTE)
          begin
             last_byte_flag <= #1 1;
          end
        else if (T_lastbit)              // reset T_lastbit
          begin
             last_byte_flag <= #1 0;
          end
        else 
          begin
             last_byte_flag <= #1 last_byte_flag;
          end
          
 assign T_lastbit1 = (last_byte_flag & !(shift1_wait_shift | shift2_wait_shift));

 always @(negedge clock or posedge reset)
   begin
       if (reset)
          T_lastbit2 <= 0;
       else
          T_lastbit2 <= #1 T_lastbit1;
   end
 assign T_lastbit = (T_lastbit1 | T_lastbit2) ;

 always @ (posedge clock)
     begin
        if(reset)
          CRC_flag <= #1 0;
        else if (T_lastbit)
          CRC_flag <= #1 1;
        else if(CRC_done)
          CRC_flag <= #1 0;
        else CRC_flag <= #1 CRC_flag;
     end
 always @ (posedge clock or posedge reset)
    begin
        if(reset)
          CRC_cnt <= #1 4'h0;
        else if(CRC_done)
          CRC_cnt <= #1 4'h0;
        else if (CRC_flag)
          CRC_cnt <= #1 CRC_cnt + 1;
    end
  assign CRC_done = ( (CRC_16 & (CRC_cnt == 4'hE) )  | (!CRC_16 & (CRC_cnt == 4'h3) ));

reg [4:0] pid_crc_cnt;
always @ (posedge clock or posedge reset)
  begin
    if (reset)
      pid_crc_cnt <= 0;
    else begin
      if (TCS & (~CRC_16) & (~halt_tx_shift))
        pid_crc_cnt <= pid_crc_cnt +1;
    end
  end

  assign shift_tx_crc5 = pid_crc_cnt >= 27 & pid_crc_cnt <= 31;
  assign shift_tx_crc16 = ( (T_lastbit & CRC_16)  | (CRC_flag & CRC_16) );
  
         
endmodule
