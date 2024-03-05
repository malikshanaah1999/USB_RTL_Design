`timescale 1ns / 10ps

 
module  crc_tx(clk_c,reset,halt_tx,cwe_z,data_in,data_out_5bit,
			data_out_16bit);

input   clk_c;                  // clock
input   reset;                  // active high reset
input   halt_tx;                // active high clk disable signal
input   cwe_z;                  // enable check data
input   data_in;                // 1 bit of data input
output  data_out_5bit;          // 1 bit of data output
output  data_out_16bit;         // 1 bit of data output

wire error_5bit;
wire error_16bit;
wire	[15:0] tx16_int;

// **************************************
// *** INSTANTIATION OF SUB MODULES   ***
// **************************************
crc_5 tx5(
        .clk_c(clk_c),
        .reset(reset),
        .halt_tx(halt_tx),
        .cwe_z(cwe_z),
        .chck_enbl(1'b0),
        .data_in(data_in),
        .data_out(data_out_5bit),
        .error(error_5bit));

crc_16 tx16(
        .clk_c(clk_c),
        .reset(reset),
        .halt_tx(halt_tx),
        .cwe_z(cwe_z),
        .chck_enbl(1'b0),
        .data_in(data_in),
        .data_out(data_out_16bit),
        .int_data(tx16_int),	
        .error(error_16bit));

endmodule

