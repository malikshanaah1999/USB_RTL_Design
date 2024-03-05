`timescale 1ns / 10ps

 
module  crc_rx(clk_c,reset,rcs,cwe_z,chck_enbl,data_in,select16,
		error, rx16_int);

input   clk_c;                  // clock
input   reset;                  // active high reset
input   rcs;                	// active data chipselect (inv of halt tx)
input   cwe_z;                  // enable check data
input   chck_enbl;              // enable error check
input   data_in;                // 1 bit of data input
input	select16;		// high when crc16 is selected
				// low when crc5 selected
output  error;                  // high when error detected.
output	[15:0] rx16_int;


wire	error_5bit;
wire	error_16bit;

wire    [15:0] rx16_int;

assign	error	=	(select16) ? error_16bit : error_5bit;

// **************************************
// *** INSTANTIATION OF SUB MODULES   ***
// **************************************
crc_5 rx5(
        .clk_c(clk_c),
        .reset(reset),
        .halt_tx(~rcs),
        .cwe_z(cwe_z),
        .chck_enbl(chck_enbl),
        .data_in(data_in),
        .data_out(data_out_5bit),
        .error(error_5bit));

crc_16 rx16(
        .clk_c(clk_c),
        .reset(reset),
        .halt_tx(~rcs),
        .cwe_z(cwe_z),
        .chck_enbl(chck_enbl),
        .data_in(data_in),
        .data_out(data_out_16bit),
	.int_data(rx16_int),
        .error(error_16bit));

endmodule

