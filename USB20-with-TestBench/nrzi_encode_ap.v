`timescale 1ns / 10ps


module nrzi_encode_ap(
	gclk, reset_l, start_txd, tx_data_in, tx_data_out, tx_data_valid);

input gclk;               	//global clock; 12 Mhz
input reset_l;              	//system reset; global; active low
input start_txd;		//enable txd pins
input tx_data_in;		//transmit data before encoder

output tx_data_out;		//nrzi out
output tx_data_valid;		// data valid signal to diff driver

reg tx_data_out;		//nrzi out
reg tx_data_valid;		// data valid signal to diff driver


always @(posedge gclk or negedge reset_l)
begin
  if (!reset_l)
    tx_data_valid <= #1 1'b0;
  else
    tx_data_valid <= #1 start_txd;
end
always @(posedge gclk or negedge reset_l)
begin
  if (!reset_l)
    tx_data_out <= #1 1'b1;		//default is 1; idle state
  else if (!start_txd)			//txd idle = 1
    tx_data_out <= #1 1'b1;
  else if (start_txd && !tx_data_in)	//switch level when tx_data_in = 0
    tx_data_out <= #1 !tx_data_out;
  else
    tx_data_out <= #1 tx_data_out;
end

endmodule
