`timescale 1ns / 10ps

//note: The data 1 that ends sync pattern is counted as the first one.

module bit_stuff(
	gclk, reset_l, start_bit_stuff, stuff_din, shift_tx_crc5, 
	shift_tx_crc16, tx_crc5_out, tx_crc16_out, halt_tx_shift, stuff_dout, cs1_l, start_txd);

input gclk;               	//global clock; 12 Mhz
input reset_l;              	//system reset; global; active low
input start_bit_stuff;		//start bit stuffing
input stuff_din;		//data to be stuffed 0
input shift_tx_crc5;		//shift tx crc5 to bit stuffer
input shift_tx_crc16;		//shift tx crc16 to bit stuffer
input tx_crc5_out;		//output of CRC5 calculation
input tx_crc16_out;		//output of CRC16 calculation
input cs1_l;                     // cs1 for bit stuffing 
output halt_tx_shift;		//halt tx data shifter while stuffing 0
output stuff_dout;		//stuffed data out
output start_txd;

reg [5:0] data_shift;		//shift register to detect six consecutive 1's
reg start_txd;

//always @(posedge gclk )
always @(posedge gclk )
  if (!reset_l||!cs1_l)
    data_shift <= #1 6'h0;
  else if (!start_bit_stuff)
    data_shift <= #1 6'h0;
  else if (halt_tx_shift)			//stuff a 0
    data_shift <= #1 {data_shift[4:0], 1'b0};
  else if (shift_tx_crc5)
    data_shift <= #1 {data_shift[4:0], tx_crc5_out};	//inverted
  else if (shift_tx_crc16)
// ERNEST!!!! removed inversion of tx_crc16_out input!!!
    data_shift <= #1 {data_shift[4:0],  tx_crc16_out};
  else
      data_shift <= #1 {data_shift[4:0], stuff_din};
    //data_shift <= #1 {stuff_din, data_shift[5:1]};

always @(posedge gclk )
  if (!reset_l||!cs1_l)
       start_txd <= #1 0;
  else 
       start_txd <= #1 start_bit_stuff;  // fix?

assign halt_tx_shift = (data_shift == 6'b111111);
assign stuff_dout = data_shift[0];


endmodule
