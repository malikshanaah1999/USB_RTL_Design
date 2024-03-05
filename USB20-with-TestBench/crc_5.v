`timescale 1ns / 10ps


 
module	crc_5(clk_c,reset,halt_tx,cwe_z,chck_enbl,data_in,data_out,error);

input	clk_c;			// clock 
input	reset;			// active high reset
input	halt_tx;		// active high clk disable signal
input	cwe_z;			// enable check data
input	chck_enbl;		// enable error check
input	data_in;		// 1 bit of data input
output	data_out;		// 1 bit of data output	
output	error;			// high when error detected.

reg	[4:0] data_q;		// actual register flipflop (Q-side)
wire	[4:0] data_d;		// actual register flipflop (D-side)

reg	error_q;
wire	error_d;

wire	shift_in;		// crc feedback shift line
wire	d0_shift;
wire	d2_shift;
//wire	d4_shift;
reg     chck_enbl_d;
parameter
TIME		=	1;

assign	data_out = (~data_q[4] & ~cwe_z) | (data_in & cwe_z);	
					// connect output to register bit	

// ##### Error detection, only when chck_enbl is high...
assign	error_d = (chck_enbl & ((data_q != 5'b01100)));			// do not hold error
//assign	error_d = (chck_enbl & ((data_q != 5'b01100))) | error_q;			// hold error

assign	error = error_d;		// connect FF to output
//assign	error = error_q;		// connect FF to output

// ***********************************************
// **** Connect CRC block interconnects
// ***********************************************

assign	shift_in = (data_in ^ data_q[4]) & cwe_z;
assign d0_shift = cwe_z ? shift_in : 1'b1;
assign d2_shift = cwe_z ? (data_q[1] ^ shift_in) : data_q[1];
//assign d4_shift = cwe_z ? (data_q[3] ^ shift_in) : data_q[3];

assign	data_d[0] = (~halt_tx) ?  d0_shift    : data_q[0];
assign	data_d[1] = (~halt_tx) ?  data_q[0]   : data_q[1];
assign	data_d[2] = (~halt_tx) ?  d2_shift    : data_q[2];
assign	data_d[3] = (~halt_tx) ?  data_q[2]   : data_q[3];
//assign	data_d[4] = (~halt_tx) ?  d4_shift    : data_q[4];
assign	data_d[4] = (~halt_tx) ?  data_q[3]    : data_q[4];

// **************************************************
// **** clock D-sides of flipflops into Q-sides *****
// **************************************************

always @(posedge clk_c)
begin
	if (reset)
	begin
		data_q <=  5'h1F;		// asynchronous reset
		error_q <= 1'b0;
		chck_enbl_d <= 1'b0;
	end
	else
	begin
		data_q  <=  data_d;
		error_q <=  error_d;
		chck_enbl_d <=  chck_enbl;
	end	
end

endmodule





