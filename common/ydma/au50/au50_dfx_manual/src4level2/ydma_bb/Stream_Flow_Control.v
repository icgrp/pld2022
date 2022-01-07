`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2018 05:35:43 PM
// Design Name: 
// Module Name: Stream_Flow_Control
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
module Stream_Flow_Control#(
    parameter PACKET_BITS = 97,
    parameter NUM_LEAF_BITS = 6,
    parameter NUM_PORT_BITS = 4,
    parameter NUM_ADDR_BITS = 7,
    parameter PAYLOAD_BITS = 64, 
    parameter NUM_IN_PORTS = 7, 
    parameter NUM_OUT_PORTS = 7,
    parameter NUM_BRAM_ADDR_BITS = 7,
    parameter FREESPACE_UPDATE_SIZE = 64,
    localparam OUT_PORTS_REG_BITS=NUM_LEAF_BITS+NUM_PORT_BITS+NUM_ADDR_BITS+NUM_ADDR_BITS+3,
    localparam IN_PORTS_REG_BITS=NUM_LEAF_BITS+NUM_PORT_BITS,
    localparam REG_CONTROL_BITS=OUT_PORTS_REG_BITS*NUM_OUT_PORTS+IN_PORTS_REG_BITS*NUM_IN_PORTS    
    )(
    input resend,
    input clk,
    input reset,
    
    input [PACKET_BITS-1:0] stream_in,
    output [PACKET_BITS-1:0] stream_out,
    input [REG_CONTROL_BITS-1:0] control_reg,
    
    //data to USER
    output [PAYLOAD_BITS*NUM_IN_PORTS-1:0] dout_leaf_interface2user,
    output [NUM_IN_PORTS-1:0] vld_interface2user,
    input [NUM_IN_PORTS-1:0] ack_user2interface,
    
    //data from USER
    output [NUM_OUT_PORTS-1:0] ack_interface2user,
    input [NUM_OUT_PORTS-1:0] vld_user2interface,
    input [PAYLOAD_BITS*NUM_OUT_PORTS-1:0] din_leaf_user2interface
    
    );
    
    wire [NUM_IN_PORTS-1:0] freespace_update;
    wire [NUM_OUT_PORTS-1:0] empty;
    wire [PACKET_BITS*NUM_IN_PORTS-1:0] packet_from_input_ports;
    wire [PACKET_BITS*NUM_OUT_PORTS-1:0] packet_from_output_ports;
    wire [NUM_OUT_PORTS-1:0] rd_en_sel;
    
    
    converge_ctrl#(
        .PACKET_BITS(PACKET_BITS),
        .NUM_PORT_BITS(NUM_PORT_BITS),
        .NUM_IN_PORTS(NUM_IN_PORTS),
        .NUM_OUT_PORTS(NUM_OUT_PORTS)
    )ConCtrl(
        .clk(clk),
        .reset(reset),
        .outport_sel(rd_en_sel),
        .stream_out(stream_out),
        .freespace_update(freespace_update),
        .packet_from_input_ports(packet_from_input_ports),
        .packet_from_output_ports(packet_from_output_ports),
        .empty(empty),
        .resend(resend)
    );
    

    Input_Port_Cluster # (
        .PACKET_BITS(PACKET_BITS),
        .NUM_LEAF_BITS(NUM_LEAF_BITS),
        .NUM_PORT_BITS(NUM_PORT_BITS),
        .NUM_ADDR_BITS(NUM_ADDR_BITS),
        .PAYLOAD_BITS(PAYLOAD_BITS),
        .NUM_IN_PORTS(NUM_IN_PORTS),
        .NUM_OUT_PORTS(NUM_OUT_PORTS),
        .NUM_BRAM_ADDR_BITS(NUM_BRAM_ADDR_BITS),
        .FREESPACE_UPDATE_SIZE(FREESPACE_UPDATE_SIZE)
    )ipc(
        .clk(clk),
        .reset(reset),
        .freespace_update(freespace_update),
        .packet_from_input_ports(packet_from_input_ports),
        .stream_in(stream_in),
        .in_control_reg(control_reg[IN_PORTS_REG_BITS*NUM_IN_PORTS-1:0]),
        .dout2user(dout_leaf_interface2user),
        .vld2user(vld_interface2user),
        .ack_user2b_in(ack_user2interface)
    );
    

    Output_Port_Cluster #(
        .PACKET_BITS(PACKET_BITS),
        .NUM_LEAF_BITS(NUM_LEAF_BITS),
        .NUM_PORT_BITS(NUM_PORT_BITS),
        .NUM_ADDR_BITS(NUM_ADDR_BITS),
        .PAYLOAD_BITS(PAYLOAD_BITS),
        .NUM_IN_PORTS(NUM_IN_PORTS),
        .NUM_OUT_PORTS(NUM_OUT_PORTS),
        .NUM_BRAM_ADDR_BITS(NUM_BRAM_ADDR_BITS),
        .FREESPACE_UPDATE_SIZE(FREESPACE_UPDATE_SIZE)
    )opc(
        .clk(clk),
        .reset(reset),
        .out_control_reg(control_reg[REG_CONTROL_BITS-1:IN_PORTS_REG_BITS*NUM_IN_PORTS]),
        .internal_out(packet_from_output_ports),
        .empty(empty),
        .rd_en_sel(rd_en_sel),
        .ack_b_out2user(ack_interface2user),
        .din_leaf_user2interface(din_leaf_user2interface),
        .vld_user2b_out(vld_user2interface)
    );

              



endmodule
