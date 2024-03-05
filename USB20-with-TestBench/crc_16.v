`timescale 1ns / 10ps

 
module	crc_16(clk_c,reset,halt_tx,cwe_z,chck_enbl,data_in,data_out,error,int_data);

input	clk_c;			// clock 
input	reset;			// active high reset
input	halt_tx;		// active high clk disable signal
input	cwe_z;			// enable check data
input	chck_enbl;		// enable error check
input	data_in;		// 1 bit of data input
output	data_out;		// 1 bit of data output	
output	error;			// high when error detected.
output	[15:0] int_data;		

reg	[15:0] data_q;		// actual register flipflop (Q-side)
wire	[15:0] data_d;		// actual register flipflop (D-side)

reg	error_q;
wire	error_d;

wire	shift_in;		// crc feedback shift line
wire	d0_shift;
wire	d2_shift;
wire	d15_shift;

parameter
TIME		=	1;

assign	data_out = (~data_q[15] & ~cwe_z) | (data_in & cwe_z);	
					// connect output to register bit	

// ##### Error detection, only when chck_enbl is high...
assign	error_d = (chck_enbl & ((data_q != 16'b1000000000001101))) |
			error_q;
assign	error = error_q;		// connect FF to output

assign	int_data = data_q;
// ***********************************************
// **** Connect CRC block interconnects
// ***********************************************

assign	shift_in = (data_in ^ data_q[15]) & cwe_z;
assign	d0_shift  = cwe_z ? shift_in : 1'b1;
assign	d2_shift  = cwe_z ? (data_q[1]  ^ shift_in) : data_q[1];
assign	d15_shift = cwe_z ? (data_q[14] ^ shift_in) : data_q[14];

assign	data_d[0]  = (~halt_tx) ?  d0_shift    : data_q[0];
assign	data_d[1]  = (~halt_tx) ?  data_q[0]   : data_q[1];
assign	data_d[2]  = (~halt_tx) ?  d2_shift    : data_q[2];
assign	data_d[3]  = (~halt_tx) ?  data_q[2]   : data_q[3];
assign	data_d[4]  = (~halt_tx) ?  data_q[3]   : data_q[4];
assign	data_d[5]  = (~halt_tx) ?  data_q[4]   : data_q[5];
assign	data_d[6]  = (~halt_tx) ?  data_q[5]   : data_q[6];
assign	data_d[7]  = (~halt_tx) ?  data_q[6]   : data_q[7];
assign	data_d[8]  = (~halt_tx) ?  data_q[7]   : data_q[8];
assign	data_d[9]  = (~halt_tx) ?  data_q[8]   : data_q[9];
assign	data_d[10] = (~halt_tx) ?  data_q[9]   : data_q[10];
assign	data_d[11] = (~halt_tx) ?  data_q[10]  : data_q[11];
assign	data_d[12] = (~halt_tx) ?  data_q[11]  : data_q[12];
assign	data_d[13] = (~halt_tx) ?  data_q[12]  : data_q[13];
assign	data_d[14] = (~halt_tx) ?  data_q[13]   : data_q[14];
assign	data_d[15] = (~halt_tx) ?  d15_shift   : data_q[15];

// ******************* following for test purposes, to check
// ******************* crc timing/logic in debug
//assign	data_d[0]  =  shift_in;
//assign	data_d[1]  =  data_q[0];
//assign	data_d[2]  =  data_q[1];
//assign	data_d[3]  =  data_q[2];
//assign	data_d[4]  =  data_q[3];
//assign	data_d[5]  =  data_q[4];
//assign	data_d[6]  =  data_q[5];
//assign	data_d[7]  =  data_q[6];
//assign	data_d[8]  =  data_q[7];
//assign	data_d[9]  =  data_q[8];
//assign	data_d[10] =  data_q[9];
//assign	data_d[11] =  data_q[10];
//assign	data_d[12] =  data_q[11];
//assign	data_d[13] =  data_q[12];
//assign	data_d[14] =  data_q[13];
//assign	data_d[15] =  data_q[14];

// **************************************************
// **** clock D-sides of flipflops into Q-sides *****
// **************************************************

always @(posedge clk_c)
begin
	if (reset)
	begin
//		data_q <= #TIME 16'hffff;		// asynchronous reset
		data_q <= 16'hffff;
		error_q <= 1'b0;
	end
	else
	begin
		//		data_q  <= #TIME data_d;
		data_q  <= data_d;
		//		error_q <= #TIME error_d;
		error_q <= error_d;
	end	
end

endmodule
