`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ylxiao
// 
// Create Date: 03/09/2020 01:43:45 PM
// Design Name: 
// Module Name: fifo_stream
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   This is a manual designed stream fifo
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_stream_in #(
    parameter PAYLOAD_BITS = 32,
    parameter NUM_BRAM_ADDR_BITS = 9,
    localparam FIFO_DEPTH = (2**NUM_BRAM_ADDR_BITS)
    )(
    input clk,
    input reset,
    input [PAYLOAD_BITS-1:0] din,
    input val_in,
    output ready_upward,
    output [PAYLOAD_BITS-1:0] rdata,
    output rempty,
    input rinc
    );


wire full;
wire wr_en;

wire [PAYLOAD_BITS-1:0] fifo_in;


assign ready_upward = ~full;
assign wr_en = val_in;
assign fifo_in = din;


SynFIFO SynFIFO_inst (
	.clk(clk),
	.rst_n(!reset),
	.rdata(rdata), 
	.wfull(full), 
	.rempty(rempty), 
	.wdata(fifo_in),
	.winc(wr_en), 
	.rinc(rinc)
	);
	



endmodule
