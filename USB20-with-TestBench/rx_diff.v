`timescale 1ns /10ps


`define SOF_PDI 8'hc6		//Packet ID symbols
`define IN_PDI 8'h4e
`define OUT_PDI 8'hbe
`define SETUP_PDI 8'h36
`define DATA0_PDI 8'h82
`define DATA1_PDI 8'h72
`define ACK_PDI 8'h9c
`define NAK_PDI 8'h6c
`define STALL_PDI 8'h14
`define PREAMBLE_PDI 8'h28

`define WAIT_FOR_PACKET 3'd0	//main state machine states
`define PID 3'd1
`define FRAME_NUMBER 3'd2
`define DEV_ADDRESS 3'd3
`define DATA_CRC16 3'd4
`define END_POINT_ADDRESS 3'd5
`define CRC5 3'd6
`define ERROR 3'd7


module rx_diff(gclk, reset_l, rxd_pos, rxd_neg, rx_diff_out, rx_diff_valid, idle_or_sync, pid,
               dev_address, end_point_address, crc5, frame_number, data_crc_eop, eop, error);

input gclk;			//global clock from the testbech
input reset_l;			//global reset from the testbench
output rx_diff_valid;		//data valid qualifier
output rx_diff_out;		//received data
output idle_or_sync;		//data qualifier
output pid;			//data qualifier
output dev_address;		//data qualifier
output end_point_address;	//data qualifier
output crc5;			//data qualifier
output frame_number;		//data qualifier
output data_crc_eop;		//data qualifier
output eop;		//data qualifier
output error;			//data qualifier

input rxd_pos;			//receive data positive out
input rxd_neg;			//receive data negative out

reg [7:0] sync_detect;		//sync word shift register
reg [7:0] pid_reg;		//packet ID shift register
wire sync_found;			//sync pattern detected, input to SM
reg packet_active;		//packet being received, disables sync detect
wire sof_pid;			//sof pid detected, input to SM
wire in_pid;			//in pid detected, input to SM
wire out_pid;			//out pid detected, input to SM
wire setup_pid;			//setup pid detected, input to SM
wire data0_pid;			//data0 pid detected, input to SM
wire data1_pid;			//data1 pid detected, input to SM
wire ack_pid;			//ack pid detected, input to SM
wire nak_pid;			//nak pid detected, input to SM
wire stall_pid;			//stall pid detected, input to SM
wire preamble_pid;		//preamble pid detected, input to SM
wire error_pid;			//error pid detected, input to SM
reg idle_or_sync;            //data qualifier
reg pid;                     //data qualifier
reg dev_address;             //data qualifier
reg end_point_address;       //data qualifier
reg crc5;                    //data qualifier
reg frame_number;            //data qualifier
reg data_crc_eop;            //data qualifier
reg eop;            //data qualifier
reg error;                   //data qualifier
reg [2:0] state;
reg [2:0] next_state;
reg [6:0] go_to_end_address;	//wait 7 bits in device address state
reg [3:0] go_to_address_crc;	//wait 4 bits in end address state
reg [10:0] go_to_frame_crc;	//wait 11 bits in frame number state
reg rx_diff_out;		//module output data
reg rx_diff_valid;		//module output data qualifier
reg rx_diff_valid_i;		//module output data qualifier
reg [7:0] shift_pid_reg;	//for PID decode
wire shift_pid_eb;		//for PID decode
reg [6:0] in_reg;               //holding input data to find a stuffed bit
wire delay_cycle;

always @(posedge gclk or negedge reset_l)
  if (!reset_l)
    in_reg <= #1 7'b1010101;
  else
    in_reg <= packet_active ? ({in_reg[5:0], rxd_pos}) : 7'b000000;
assign delay_cycle = (dev_address || end_point_address || frame_number) && ((in_reg == 7'b0000000) || (in_reg == 7'b1111111));

always @(posedge rx_diff_valid_i or posedge eop or negedge reset_l)
  if (!reset_l)
    rx_diff_valid <= #1 1'b0;
  else if (eop)
    rx_diff_valid <= #1 1'b0;
  else
    rx_diff_valid <= #1 1'b1;

/*loads the input serial data stream into an 8 bit shift register
  looking for a sync pattern (00000001 in binary or 01010100in nrzi).
  Once it finds it it generates sync_detect so the main state machine
  can transition from WAIT_FOR PACKET to the PID state.*/ 

always @(posedge gclk or negedge reset_l)
  if (!reset_l)
    sync_detect <= #1 8'b11111111;
  else if (!packet_active)
    sync_detect <= #1 {sync_detect[6:0], rxd_pos};

assign sync_found = ((sync_detect == 8'b01010100) & (!packet_active)) ? 1'b1 : 1'b0;

/*generates packet_active which disables the sync_detect logic. That way a sync
  pattern in the data of the packet will not set sync_detect. Packet_active
  is cleared at the end of the packet in the eopdetect task*/

always @(posedge gclk or negedge reset_l)
  if (!reset_l)
      packet_active <= #1 1'b0;
  else if (sync_found)
      packet_active <= #1 1'b1;
  else if (eop)
      packet_active <= #1 1'b0;

always @(posedge gclk)
  begin
    if (!rxd_pos && !rxd_neg)
      eop <= #1 1'b1;
    else
      eop <= #1 1'b0;
  end

// Decode the PID

always @(posedge gclk or negedge reset_l)
  if (!reset_l)
    shift_pid_reg <= #1 8'b00000000;
  else
  begin
    shift_pid_reg <= #1 {shift_pid_reg[6:0], sync_found};  
  end

assign  shift_pid_eb = (shift_pid_reg[0] || shift_pid_reg[1] || 
       shift_pid_reg[2] || shift_pid_reg[3] || shift_pid_reg[4] ||
       shift_pid_reg[5] || shift_pid_reg[6] );

always @(posedge gclk or negedge reset_l)
  if (!reset_l)
    pid_reg <= #1 8'b00000000;
  else if (shift_pid_eb || sync_found)
    pid_reg <= #1 {pid_reg[6:0], rxd_pos};

/*always @(posedge gclk or negedge reset_l)
  if (!reset_l) 
        begin
          sof_pid <= #1 1'b0;
          in_pid <= #1 1'b0;
          out_pid <= #1 1'b0;
          setup_pid <= #1 1'b0;
          data0_pid <= #1 1'b0;
          data1_pid <= #1 1'b0;
          ack_pid <= #1 1'b0;
          nak_pid <= #1 1'b0;
          stall_pid <= #1 1'b0;
          preamble_pid <= #1 1'b0;
          error_pid <= #1 1'b0;
        end
  //else if (!shift_pid_reg[6]) 
  else if (!shift_pid_reg[7]) //saswat
        begin
          sof_pid <= #1 1'b0;
          in_pid <= #1 1'b0;
          out_pid <= #1 1'b0;
          setup_pid <= #1 1'b0;
          data0_pid <= #1 1'b0;
          data1_pid <= #1 1'b0;
          ack_pid <= #1 1'b0;
          nak_pid <= #1 1'b0;
          stall_pid <= #1 1'b0;
          preamble_pid <= #1 1'b0;
          error_pid <= #1 1'b0;
        end 

  else
        begin
          case(pid_reg)
            8'h6c : sof_pid <= #1 1'b1;
            8'h4e : in_pid <= #1 1'b1;
            8'h50 : out_pid <= #1 1'b1;
            8'h72 : setup_pid <= #1 1'b1;
            8'h28 : data0_pid <= #1 1'b1;
            8'h36 : data1_pid <= #1 1'b1;
            8'hd8 : ack_pid <= #1 1'b1;
            8'hc6 : nak_pid <= #1 1'b1;
            8'hfa : stall_pid <= #1 1'b1;
            8'h82 : preamble_pid <= #1 1'b1;
            default : error_pid <= #1 1'b1;
          endcase
        end
*/

assign sof_pid      = (shift_pid_reg == 8'h80) && (pid_reg == 8'h6c);
assign in_pid       = (shift_pid_reg == 8'h80) && (pid_reg == 8'h4e);
assign out_pid      = (shift_pid_reg == 8'h80) && (pid_reg == 8'h50);
assign setup_pid    = (shift_pid_reg == 8'h80) && (pid_reg == 8'h72);
assign data0_pid    = (shift_pid_reg == 8'h80) && (pid_reg == 8'h28);
assign data1_pid    = (shift_pid_reg == 8'h80) && (pid_reg == 8'h36);
assign ack_pid      = (shift_pid_reg == 8'h80) && (pid_reg == 8'hd8);
assign nak_pid      = (shift_pid_reg == 8'h80) && (pid_reg == 8'hc6);
assign stall_pid    = (shift_pid_reg == 8'h80) && (pid_reg == 8'hfa);
assign preamble_pid = (shift_pid_reg == 8'h80) && (pid_reg == 8'h82);
assign error_pid    = (shift_pid_reg == 8'h80) && ((pid_reg != 8'h6c) 
                                                && (pid_reg != 8'h4e)
                                                && (pid_reg != 8'h50)
                                                && (pid_reg != 8'h72)
                                                && (pid_reg != 8'h28)
                                                && (pid_reg != 8'h36)
                                                && (pid_reg != 8'hd8)
                                                && (pid_reg != 8'hc6)
                                                && (pid_reg != 8'hfa)
                                                && (pid_reg != 8'h82));


always @(posedge gclk or negedge reset_l)
  if (!reset_l)
    go_to_frame_crc <= #1 11'b00000000000;
  else
    go_to_frame_crc <= #1 ~delay_cycle ? ({go_to_frame_crc[9:0], sof_pid}) : go_to_frame_crc;

always @(posedge gclk or negedge reset_l)
  if (!reset_l)
    go_to_end_address <= #1 7'b0000000;
  else
    go_to_end_address <= #1 ~delay_cycle ? ({go_to_end_address[5:0], (in_pid || out_pid || setup_pid)}) : go_to_end_address;

always @(posedge gclk or negedge reset_l)
  if (!reset_l)
    go_to_address_crc <= #1 4'b0000;
  else
    go_to_address_crc <= #1 ~delay_cycle ? ({go_to_address_crc[2:0], go_to_end_address[6]}) : go_to_address_crc;

always @(posedge gclk)
  rx_diff_out <= #1 rxd_pos;

always @(posedge gclk or negedge reset_l)
  if (!reset_l)
    state <= #1 `WAIT_FOR_PACKET;
  else
    state <= #1 next_state;

always @(state)
begin
  case(state)
    `WAIT_FOR_PACKET : begin
                         idle_or_sync <= #1 1'b1;
                         pid <= #1 1'b0;
                         dev_address <= #1 1'b0;
                         end_point_address <= #1 1'b0;
                         crc5 <= #1 1'b0;
                         frame_number <= #1 1'b0;
                         data_crc_eop <= #1 1'b0;
                         error <= #1 1'b0;
                         rx_diff_valid_i <= #1 1'b0;
                       end
    `PID : begin
                         idle_or_sync <= #1 1'b0;
                         pid <= #1 1'b1;
                         dev_address <= #1 1'b0;
                         end_point_address <= #1 1'b0;
                         crc5 <= #1 1'b0;
                         frame_number <= #1 1'b0;
                         data_crc_eop <= #1 1'b0;
                         error <= #1 1'b0;
                         rx_diff_valid_i <= #1 1'b1;
                       end
    `FRAME_NUMBER : begin
                         idle_or_sync <= #1 1'b0;
                         pid <= #1 1'b0;
                         dev_address <= #1 1'b0;
                         end_point_address <= #1 1'b0;
                         crc5 <= #1 1'b0;
                         frame_number <= #1 1'b1;
                         data_crc_eop <= #1 1'b0;
                         error <= #1 1'b0;
                         rx_diff_valid_i <= #1 1'b1;
                       end
    `DEV_ADDRESS : begin
                         idle_or_sync <= #1 1'b0;
                         pid <= #1 1'b0;
                         dev_address <= #1 1'b1;
                         end_point_address <= #1 1'b0;
                         crc5 <= #1 1'b0;
                         frame_number <= #1 1'b0;
                         data_crc_eop <= #1 1'b0;
                         error <= #1 1'b0;
                         rx_diff_valid_i <= #1 1'b1;
                       end
    `DATA_CRC16 : begin
                         idle_or_sync <= #1 1'b0;
                         pid <= #1 1'b0;
                         dev_address <= #1 1'b0;
                         end_point_address <= #1 1'b0;
                         crc5 <= #1 1'b0;
                         frame_number <= #1 1'b0;
                         data_crc_eop <= #1 1'b1;
                         error <= #1 1'b0;
                         rx_diff_valid_i <= #1 1'b1;
                       end
    `END_POINT_ADDRESS : begin
                         idle_or_sync <= #1 1'b0;
                         pid <= #1 1'b0;
                         dev_address <= #1 1'b0;
                         end_point_address <= #1 1'b1;
                         crc5 <= #1 1'b0;
                         frame_number <= #1 1'b0;
                         data_crc_eop <= #1 1'b0;
                         error <= #1 1'b0;
                         rx_diff_valid_i <= #1 1'b1;
                       end
    `CRC5 : begin
                         idle_or_sync <= #1 1'b0;
                         pid <= #1 1'b0;
                         dev_address <= #1 1'b0;
                         end_point_address <= #1 1'b0;
                         crc5 <= #1 1'b1;
                         frame_number <= #1 1'b0;
                         data_crc_eop <= #1 1'b0;
                         error <= #1 1'b0;
                         rx_diff_valid_i <= #1 1'b1;
                       end
    `ERROR : begin
                         idle_or_sync <= #1 1'b0;
                         pid <= #1 1'b0;
                         dev_address <= #1 1'b0;
                         end_point_address <= #1 1'b0;
                         crc5 <= #1 1'b0;
                         frame_number <= #1 1'b0;
                         data_crc_eop <= #1 1'b0;
                         error <= #1 1'b1;
                         rx_diff_valid_i <= #1 1'b1;
                       end

  endcase
end

always @(state or reset_l or sync_found or eop or preamble_pid 
        or data0_pid or data1_pid or in_pid or out_pid or setup_pid
        or sof_pid or error_pid or go_to_end_address[6] or go_to_address_crc[3]
        or go_to_frame_crc[10])
begin
  if(!reset_l)
    next_state <= #1 `WAIT_FOR_PACKET;
  else
    case (state)
      `WAIT_FOR_PACKET : if(sync_found == 1'b1)
                           next_state <= #1 `PID;
                         else
                           next_state <= #1 `WAIT_FOR_PACKET;
      `PID : if (eop)
                           next_state <= #1 `WAIT_FOR_PACKET;
                         else if (preamble_pid && !eop)
                           next_state <= #1 `PID;
                         else if (data0_pid || data1_pid)
                           next_state <= #1 `DATA_CRC16;
                         else if (in_pid || out_pid || setup_pid)
                           next_state <= #1 `DEV_ADDRESS;
                         else if (sof_pid)
                           next_state <= #1 `FRAME_NUMBER;
                         else if (error_pid)
                           next_state <= #1 `ERROR;
                         else
                           next_state <= #1 `PID;
      `DEV_ADDRESS : if (eop) 
                           next_state <= #1 `WAIT_FOR_PACKET;
                         else if (go_to_end_address[6])
                           next_state <= #1 `END_POINT_ADDRESS;
                         else
                           next_state <= #1 `DEV_ADDRESS;
      `END_POINT_ADDRESS : if (eop) 
                           next_state <= #1 `WAIT_FOR_PACKET;
                         else if (go_to_address_crc[3])
                           next_state <= #1 `CRC5;
                         else
                           next_state <= #1 `END_POINT_ADDRESS;
      `FRAME_NUMBER : if (eop) 
                           next_state <= #1 `WAIT_FOR_PACKET;
                         else if (go_to_frame_crc[10])
                           next_state <= #1 `CRC5;
                         else
                           next_state <= #1 `FRAME_NUMBER;
      `DATA_CRC16 : if (eop)
                           next_state <= #1 `WAIT_FOR_PACKET;
                         else
                           next_state <= #1 `DATA_CRC16;
      `CRC5 : if (eop)
                           next_state <= #1 `WAIT_FOR_PACKET;
                         else
                           next_state <= #1 `CRC5;
      `ERROR : if (eop)
                           next_state <= #1 `WAIT_FOR_PACKET;
                         else
                           next_state <= #1 `ERROR;
      default : next_state <= #1 `WAIT_FOR_PACKET;
    endcase
end



endmodule
