
`timescale 1ns / 10ps


module tb_top();
 
//generate gclk

reg gclk;               	//global clock; 12 Mhz
reg reset_l;              	//system reset; global; active low
/*reg start_bit_stuff;		//start bit stuffing
reg stuff_din;			//data to be stuffed 0
reg shift_tx_crc5;		//shift tx crc5 to bit stuffer
reg shift_tx_crc16;		//shift tx crc16 to bit stuffer
reg tx_crc5_out;		//output of CRC5 calculation
reg tx_crc16_out;*/		//output of CRC16 calculation
reg cs1_l;    
reg SYN_GEN_LD;
reg TX_LOAD;
reg CRC_16;
wire [7:0] TX_DATA;
//reg [7:0] TX_DATA;
reg [7:0] TX_DATA1;
reg TX_LAST_BYTE;
//cs1 for bit stuffing 
/*reg pid;
reg dev_address;
reg end_point_address;
reg crc5;
reg frame_number;
reg data_crc_eop;
reg eop;
reg error;
reg start_rxd;
wire halt_tx_shift;		//halt tx data shifter while stuffing 0
wire stuff_dout;		//stuffed data out
wire start_txd;
reg cs2_l;*/			
wire            halt_rx_shift;		//halt rx data shifter while stuffing 0
wire            unstuff_dout;		//unstuffed data out
wire [8:0]      qualify_out;
wire            rx_data_out;
wire            rx_data_valid;
//assign tx_data_out = rx_data_out;
//assign tx_data_valid = rx_data_valid;
wire            start_txd1;
reg             RX_LOAD;
wire            RX_READY_LD;
wire    [7:0]   DATA;
wire            RX_LAST_BYTE;

assign          TX_DATA = TX_DATA1;

usb_top usb_top_inst0  
                (
                 .gclk          (gclk),
                 .reset_l       (reset_l),
                 .cs1_l         (cs1_l),
                 .SYN_GEN_LD    (SYN_GEN_LD),
                 .CRC_16        (CRC_16),
                 .TX_LOAD       (TX_LOAD),
                 .TX_DATA       (TX_DATA),
                 .TX_LAST_BYTE  (TX_LAST_BYTE),
                 .RX_LOAD       (1'b1),

                 //o/p
                 .TX_READY_LD   (TX_READY_LD),
                 .T_lastbit     (T_lastbit),
                 .qualify_out   (qualify_out),
                 .error_crc_rx  (error_crc_rx),
                 .DATA          (DATA),
                 .RX_READY_LD   (RX_READY_LD),
                 .RX_LAST_BYTE  (RX_LAST_BYTE)
                );


                
integer i;

initial
begin
        reset_l = 1'b0;
	cs1_l   = 1'b0;
	//cs2_l   = 1'b0;
        /*start_bit_stuff = 1'b0;
        stuff_din = 1'b0;
	shift_tx_crc5 = 1'b0;
	shift_tx_crc16 = 1'b0;
	tx_crc5_out = 1'b0;
	tx_crc16_out = 1'b0;*/
        #20 reset_l = 1'b1;
	//cs2_l =1'b1;
	cs1_l   = 1'b1;
	SYN_GEN_LD = 1'b0;
	TX_LOAD = 1'b0;
	TX_DATA1 = 8'h00;
	TX_LAST_BYTE =1'b0;
        
        CRC_16 = 1'b1;
        for (i=0;i <= 100;i = i + 1)
        begin
	        repeat (8) @ (posedge gclk);
	        TX_DATA1 = 8'h80;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'hC3;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'h3F;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'hB4;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'h80;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'hC3;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'h3F;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'hB4;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
	        repeat (6) @ (posedge gclk);
	        TX_LAST_BYTE =1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LAST_BYTE =1'b0;
	        //TX_DATA1 = 8'h00;
	        //repeat (80) @ (posedge gclk);
	        //SYN_GEN_LD = 1'b1;
	        //repeat (1) @ (posedge gclk);
        end

    	#50;	
	$finish;

end

 /*       
        //CRC 5 
        CRC_16 = 1'b0;
        for (i=0;i <= 100;i = i + 1)
        begin
                //CRC_16 = i%2;
        
	        repeat (8) @ (posedge gclk);
	        TX_DATA1 = 8'h80;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'hC3;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'h3F;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'hB4;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'h80;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'hC3;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'h3F;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
        
	        repeat (7) @ (posedge gclk);
	        TX_DATA1 = 8'hB4;
	        TX_LOAD = 1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LOAD = 1'b0;
	        repeat (6) @ (posedge gclk);
	        TX_LAST_BYTE =1'b1;
	        repeat (1) @ (posedge gclk);
	        TX_LAST_BYTE =1'b0;
        end


    	#50;	
	$finish;
end
*/

initial
	begin
		gclk = 1'b0;
	end
	always #10 gclk = ~gclk;
//generate reset_l and cs1_l (active low) and start_bit_stuff (active high)



initial
begin
        $recordfile ("Phaseiii.trn"); 
        $recordvars; 
end




endmodule
