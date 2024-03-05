`timescale 1ns / 10ps


module RX(
	clock, reset, RCS, RDI, halt_rx, 
        RX_LOAD, DATA, RX_READY_LD, RX_LAST_BYTE); 
input clock;
input reset;
input halt_rx;                 // Come in from unstuff block, when need to take of 0 from data
input RCS;                     // Come from UNSTUFF block when RX data is valid
input RDI;                     // Come from UNSTUFF block, this is 1 bit serial data
                               // Data is drive at posedge and latch in rx_shifter at negedge
input RX_LOAD;                 // Come from Controler block, When controler read data from 
                               // S2P block.
inout[7:0] DATA;                    // 7 bits bidirection data connect to CONTROLLER
output RX_READY_LD;            // Output to controller, let controler know the new byte of
output RX_LAST_BYTE;
                               // receive data is available for read

wire clock, reset, halt_rx, RCS, RDI, RX_LOAD; 
reg RX_READY_LD;
reg RX_LAST_BYTE;
wire[7:0] DATA;  

reg[7:0] rx_shifter;               // Shift in data from unstuff block at negedge 
reg[3:0] counter;               // 4 bits counter to count the number to load to shift register
reg[7:0] data_out;              // 7 bits register to copy data from rx_shifter to this data_out 
                                // register when rx_shifter is got last bit of a byte. A control
                                // signal RX_READY_LD will be driven to CONTROLLER to let 
                                // controller to read new data.

wire qual_zero;
   always@(posedge clock or posedge reset)
       begin
            if(reset)
               rx_shifter <= #1 8'h00;     // Reset rx_shifter
            else if(halt_rx)
               rx_shifter <= #1 rx_shifter;   // wait for unstuff 0
            else if(RCS)
                 rx_shifter[7:0] <= #1 {RDI, rx_shifter[7:1]}; //  Data in from bit 7 and
                                                               //  shiftleft bit [7:1] to 
                                                               //  bit [6:0]  QUY
            //     rx_shifter[7:0] <= #1 {rx_shifter[6:0], RDI}; // Shift right from bit 7 with 
                                                              // assume MSB bit come first
            else
                 rx_shifter <= #1 rx_shifter;   // wait for valid data

       end
   always@(negedge clock or posedge reset)
       begin
            if(reset)
               counter <= #1 4'hF;           // Reset counter
            else if(halt_rx)
                counter <= #1 counter;
            else if(!RCS)
               counter <= #1 4'hF;           // Reset counter
            else if(qual_zero)
               counter <= #1 4'h0;           // Reset counter
            else if(RCS)
               counter <= #1 counter + 1;    // Increase counter
            else
               counter <= #1 counter;        // hold counter
      end

   //assign qual_zero = (counter == 4'h7);          // Shifter get last byte, need to reset counter
   assign qual_zero = (counter == 4'h7);          // Saswat

   always @(negedge clock or posedge reset)
       begin
             if( reset)
                begin
                    data_out    <= 8'h00;
                    RX_READY_LD <= 0;             // S2P reset
                end
             else if( qual_zero)
                begin
                    data_out    <= rx_shifter;
                    RX_READY_LD <= 1;             // S2P block ready for CONTROLLER TO READ
                end
             else if (RX_LOAD)
                begin
                    data_out    <= data_out;
                    RX_READY_LD <= 0;             // S2P block is not ready for CONTROLLER TO READ
                end
       end
      assign DATA = RX_LOAD? data_out : 8'hZZ;


  always@(posedge clock or posedge reset or negedge RCS)
      begin
             if (reset)
               RX_LAST_BYTE <=  0;
             else if (!RCS)
               RX_LAST_BYTE <=  1;
             else
               RX_LAST_BYTE <=  0;
              
      end
endmodule
