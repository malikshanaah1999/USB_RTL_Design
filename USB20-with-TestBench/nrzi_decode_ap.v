`timescale 1ns/10ps


module nrzi_decode_ap(
	rx_data_out, gclk, reset_l, start_rxd, rx_data_in, rx_data_valid,
        idle_or_sync_n, pid_n, dev_address_n, end_point_address_n, crc5_n,
        frame_number_n, data_crc_eop_n, eop_n, error_n,
        idle_or_sync, pid, dev_address, end_point_address, crc5,
        frame_number, data_crc_eop, eop, error);

input gclk;               	//global clock; 12 Mhz
input reset_l;              	//system reset; global; active low
input start_rxd;		//received data is valid
input rx_data_in;		//received data
input idle_or_sync;            //data qualifier
input pid;                     //data qualifier
input dev_address;             //data qualifier
input end_point_address;       //data qualifier
input crc5;                    //data qualifier
input frame_number;            //data qualifier
input data_crc_eop;            //data qualifier
input eop;            //data qualifier
input error;                   //data qualifier


output rx_data_out;		//receive data after decoder
output rx_data_valid;		//receive data is valid
output idle_or_sync_n;            //data qualifier
output pid_n;                     //data qualifier
output dev_address_n;             //data qualifier
output end_point_address_n;       //data qualifier
output crc5_n;                    //data qualifier
output frame_number_n;            //data qualifier
output data_crc_eop_n;            //data qualifier
output eop_n;            //data qualifier
output error_n;                   //data qualifier


reg rx_data_out;		//binary out
reg rx_data_valid;		//data valid signal to bit stuffer
reg last_data;			//previous data to be compared with current
reg idle_or_sync_n;            //data qualifier
reg pid_n;                     //data qualifier
reg dev_address_n;             //data qualifier
reg end_point_address_n;       //data qualifier
reg crc5_n;                    //data qualifier
reg frame_number_n;            //data qualifier
reg data_crc_eop_n;            //data qualifier
reg eop_n;            //data qualifier
reg error_n;                   //data qualifier



always @(posedge gclk or negedge reset_l)
begin
  if (!reset_l)
  begin
    rx_data_valid <= #1 1'b0;
    last_data <= #1 1'b1;
    idle_or_sync_n <= #1 1'b0;
    pid_n <= #1 1'b0;
    dev_address_n <= #1 1'b0;
    end_point_address_n <= #1 1'b0;
    crc5_n <= #1 1'b0; // fix?
    frame_number_n <= #1 1'b0;
    data_crc_eop_n <= #1 1'b0;
    eop_n <= #1 1'b0;
    error_n <= #1 1'b0;
  end
  else
  begin
    rx_data_valid <= #1 start_rxd;
    last_data <= #1 rx_data_in;
    idle_or_sync_n <= #1 idle_or_sync;
    pid_n <= #1 pid;
    dev_address_n <= #1 dev_address;
    end_point_address_n <= #1 end_point_address;
    crc5_n <= #1 crc5;
    frame_number_n <= #1 frame_number;
    data_crc_eop_n <= #1 data_crc_eop;
    eop_n <= #1 eop;
    error_n <= #1 error;
  end
end
always @(posedge gclk or negedge reset_l)
begin
  if (!reset_l)
    rx_data_out <= #1 1'b1;	//default is 1; idle state
  else if (!start_rxd)		//rxd idle = 1
    rx_data_out <= #1 1'b1;
  else if (last_data==rx_data_in)	//decode to 1 if no input change
    rx_data_out <= #1 1'b1;
  else
    rx_data_out <= #1 1'b0;
end

endmodule
