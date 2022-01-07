`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2018 11:49:24 PM
// Design Name: 
// Module Name: Output_Port
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Output_Port#(
    parameter PACKET_BITS = 97,
    parameter NUM_LEAF_BITS = 6,
    parameter NUM_PORT_BITS = 4,
    parameter NUM_ADDR_BITS = 7,
    parameter PAYLOAD_BITS = 64, 
    parameter NUM_BRAM_ADDR_BITS = 7,
    parameter FREESPACE_UPDATE_SIZE = 64,
    localparam FIFO_DEPTH = (2**NUM_BRAM_ADDR_BITS)
    )(
    input clk,
    input reset,
    input [NUM_LEAF_BITS-1:0] dst_leaf,
    input [NUM_PORT_BITS-1:0] dst_port,
    input [NUM_ADDR_BITS-1:0] fifo_addr,
    input [NUM_ADDR_BITS-1:0] freespace,
    input update_freespace_en,
    input update_fifo_addr_en,
    input add_freespace_en,
    output [PACKET_BITS-1:0] internal_out,
    output empty,
    input rd_en_sel,

    
    output ack_b_out2user,
    input [PAYLOAD_BITS-1:0] din_leaf_user2interface,
    input vld_user2b_out

    );
    reg valid;

    
    
    
    wire [PAYLOAD_BITS-1:0] din;
    wire [PAYLOAD_BITS-1:0] dout;  
    wire wr_en;
    wire rd_en;
    reg [NUM_ADDR_BITS-1:0] FreeCnt;
    reg [NUM_ADDR_BITS-1:0] fifo_addr_reg;

    wire full;
    
    generate
        if(PACKET_BITS-1-NUM_LEAF_BITS-NUM_PORT_BITS-NUM_ADDR_BITS-PAYLOAD_BITS-1>=0) begin
            wire [PACKET_BITS-1-NUM_LEAF_BITS-NUM_PORT_BITS-NUM_ADDR_BITS-PAYLOAD_BITS-1:0] reserved_bits;
            assign reserved_bits = 0;
            assign internal_out = valid ? {1'b1, dst_leaf, dst_port, reserved_bits, fifo_addr_reg, dout} : 0;
        end else begin
            assign internal_out = valid ? {1'b1, dst_leaf, dst_port, fifo_addr_reg, dout} : 0;
        end
    endgenerate
        
    
    // assign ack_b_out2user = wr_en;
    assign ack_b_out2user = ~full;
    // write bram_out, it manipulates write port of b_out_9
                   
    always@(posedge clk) begin
         if(reset) begin
             FreeCnt = 2**NUM_ADDR_BITS-1;
         end else begin
             if(update_freespace_en)
                 FreeCnt <= freespace;
             else if(rd_en && add_freespace_en)
             //else if(add_freespace_en)
                 FreeCnt <= FreeCnt + FREESPACE_UPDATE_SIZE - 1;
             else if(!rd_en && add_freespace_en)
                 FreeCnt <= FreeCnt + FREESPACE_UPDATE_SIZE;
             else if(rd_en && (!add_freespace_en) && (FreeCnt > 0))
                 FreeCnt <= FreeCnt - 1;
             else
                 FreeCnt <= FreeCnt;
         end
     end


    always@(posedge clk) begin
        if(reset) begin
            fifo_addr_reg = 0;
        end else begin
            if(update_fifo_addr_en)
                fifo_addr_reg <= fifo_addr;
            else if(valid)
                fifo_addr_reg <= fifo_addr_reg + 1;
            else
                fifo_addr_reg <= fifo_addr_reg;
        end
    end
    
                
    assign rd_en = ((FreeCnt > 0) && (!empty)) ? rd_en_sel : 1'b0;
    
    always@(posedge clk) begin
        if(reset) begin
            valid = 0;
        end else begin
            valid <= rd_en;
        end
    end    
    
    
    write_b_out #(
        .PAYLOAD_BITS(PAYLOAD_BITS)
        )wbo(
        .vld_user2b_out(vld_user2b_out), 
        .din_leaf_user2interface(din_leaf_user2interface), 
        .full(full),
        .wr_en(wr_en), 
        .din(din));
              
/*
xpm_fifo_async # (

  .FIFO_MEMORY_TYPE          ("block"),           //string; "auto", "block", or "distributed";
  .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
  .RELATED_CLOCKS            (0),                //positive integer; 0 or 1
  .FIFO_WRITE_DEPTH          (FIFO_DEPTH),             //positive integer
  .WRITE_DATA_WIDTH          (PAYLOAD_BITS),               //positive integer
  .WR_DATA_COUNT_WIDTH       (NUM_BRAM_ADDR_BITS),               //positive integer
  .PROG_FULL_THRESH          (10),               //positive integer
  .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
  .READ_MODE                 ("std"),            //string; "std" or "fwft";
  .FIFO_READ_LATENCY         (1),                //positive integer;
  .READ_DATA_WIDTH           (PAYLOAD_BITS),               //positive integer
  .RD_DATA_COUNT_WIDTH       (NUM_BRAM_ADDR_BITS),               //positive integer
  .PROG_EMPTY_THRESH         (10),               //positive integer
  .DOUT_RESET_VALUE          ("0"),              //string
  .CDC_SYNC_STAGES           (2),                //positive integer
  .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

) xpm_fifo_async_inst (

  .rst              (reset),
  .wr_clk           (clk_user),
  .wr_en            (wr_en),
  .din              (din),
  .full             (full),
  .overflow         (overflow),
  .wr_rst_busy      (wr_rst_busy),
  .rd_clk           (clk_bft),
  .rd_en            (rd_en),
  .dout             (dout),
  .empty            (empty),
  .underflow        (underflow),
  .rd_rst_busy      (rd_rst_busy),
  .prog_full        (prog_full),
  .wr_data_count    (wr_data_count),
  .prog_empty       (prog_empty),
  .rd_data_count    (rd_data_count),
  .sleep            (1'b0),
  .injectsbiterr    (1'b0),
  .injectdbiterr    (1'b0),
  .sbiterr          (),
  .dbiterr          ()

);
*/

SynFIFO SynFIFO_inst (
	.clk(clk),
	.rst_n(!reset),
	.rdata(dout), 
	.wfull(full), 
	.rempty(empty), 
	.wdata(din),
	.winc(wr_en), 
	.rinc(rd_en)
	);
	
	
endmodule
