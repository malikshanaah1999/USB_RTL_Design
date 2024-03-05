`timescale 1ns / 10ps


module tx_diff(gclk, reset_l, txd_pos, txd_neg, tx_data_valid, nrzi_data);

input gclk;			//global clock from the testbech
input reset_l;			//global reset from the testbench
input nrzi_data;		//transmit data after nrzi encoder
input tx_data_valid;		//data valid qualifier

output txd_pos;			//transmit data positive out
output txd_neg;			//transmit data negative out

reg tx_data_valid_d;
reg tx_data_valid_2d;

wire send_eop;

always @(posedge gclk or negedge reset_l)
begin
  if(!reset_l)
  begin
    tx_data_valid_d <= #1 1'b0;
    tx_data_valid_2d <= #1 1'b0;
  end
  else
  begin
    tx_data_valid_d <= #1 tx_data_valid;
    tx_data_valid_2d <= #1 tx_data_valid_d;
  end
end

assign send_eop = !tx_data_valid && tx_data_valid_d;

assign txd_pos = !send_eop && nrzi_data;
assign txd_neg = !send_eop && !nrzi_data;


endmodule
