`timescale 1ns / 10ps

 

module bit_unstuff(gclk, reset_l, unstuff_din, halt_rx_shift, 
        	unstuff_dout, cs2_l,cs2_out_l,idle_or_sync,pid,dev_address,end_point_address,crc5,frame_number,data_crc_eop ,error,eop,qualify_out); 

input gclk;               	//global clock; 12 Mhz
input reset_l;              	//system reset; global; active low
input unstuff_din;		//data to be stuffed 0
input  cs2_l;
input  idle_or_sync,pid,dev_address,end_point_address,crc5,frame_number,data_crc_eop ,error,eop;  
output cs2_out_l;
output halt_rx_shift;		//halt rx data shifter while stuffing 0
output unstuff_dout;		//unstuffed data out
output[8:0]  qualify_out;

wire[8:0]qualify ={idle_or_sync,pid,dev_address,end_point_address,crc5,frame_number,data_crc_eop ,error,eop};
wire halt_rx_shift;
reg [6:0] data_shift;		//shift register to detect six consecutive 1's
reg cs2_out_l;
reg [8:0] qualify_out;
// reg qualify_out;

always@(posedge gclk)
   begin
   cs2_out_l <=  #1 cs2_l; 
   // QY qualify_out[8:0] <= #1 qualify;
   qualify_out[8:0] <= qualify[8:0];
   end

always @(posedge gclk)
  if (!reset_l||!cs2_l)
     begin
       data_shift <=  7'h00;
    end
//  else if (unstuff_din == 7'b111_1110)		//unstuff a 0
//     begin
//       data_shift <=  {data_shift[6:1], unstuff_din };
//     end
  else
     data_shift <=  {data_shift[5:0], unstuff_din};

assign unstuff_dout =  data_shift[0];
 assign halt_rx_shift =  (data_shift == 7'b111_1110);


endmodule
