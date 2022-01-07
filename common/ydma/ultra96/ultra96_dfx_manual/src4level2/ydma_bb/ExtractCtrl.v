`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2018 02:21:46 PM
// Design Name: 
// Module Name: ExtractCtrl
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

`define INPUT_PORT_MAX_NUM 8
`define OUTPUT_PORT_MIN_NUM 9
module Extract_Control # (
    parameter PACKET_BITS = 97,
    parameter NUM_LEAF_BITS = 6,
    parameter NUM_PORT_BITS = 4
    )(
    input clk,
    input reset,
    
    //bft_side
    output [PACKET_BITS-1:0] dout_leaf_interface2bft,
    input [PACKET_BITS-1:0] din_leaf_bft2interface,
    input resend,
    
    //stream flow control side
    output reg [PACKET_BITS-1:0] stream_out,
    output resend_out,
    input [PACKET_BITS-1:0] stream_in,
    
    //Config Control side
    output reg [PACKET_BITS-1:0] configure_out
    );
    
    
    wire vldBit;
    wire [NUM_LEAF_BITS-1:0] leaf;
    wire [NUM_PORT_BITS-1:0] port;
    
    assign vldBit = din_leaf_bft2interface[PACKET_BITS-1]; // 1 bit
    assign leaf = din_leaf_bft2interface[PACKET_BITS-2:PACKET_BITS-1-NUM_LEAF_BITS];
    assign port = din_leaf_bft2interface[PACKET_BITS-1-NUM_LEAF_BITS-1:PACKET_BITS-1-NUM_LEAF_BITS-NUM_PORT_BITS];

    assign resend_out = resend;
    assign dout_leaf_interface2bft = stream_in;
    
    //outputs for config control module
    always@(posedge clk) begin
        if(reset)
            configure_out <= 0;
        else if(vldBit && ((port == 0) || (port == 1) || (port >= `OUTPUT_PORT_MIN_NUM)))
            configure_out <= din_leaf_bft2interface;
        else 
            configure_out <= 0; 
    end

    //outputs for stream flow control
    always@(posedge clk) begin
        if(reset)
            stream_out <= 0;
        else if(vldBit && ((port > 1) && (port <= `INPUT_PORT_MAX_NUM)))
            stream_out <= din_leaf_bft2interface;
        else 
            stream_out <= 0; 
    end    
    
    
endmodule
