`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/23/2018 02:46:07 PM
// Design Name:
// Module Name: leaf_empty
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

module InterfaceWrapper6(
    input wire clk_bft,
    input wire clk_user,
    input wire [48 : 0] din_leaf_bft2interface,
    output wire [48 : 0] dout_leaf_interface2bft,
    input wire resend,
    input wire reset_bft,
    
    input [31:0]  Input_1_V_V,
    input         Input_1_V_V_ap_vld,
    output        Input_1_V_V_ap_ack,
    output [31:0] Output_1_V_V,
    output        Output_1_V_V_ap_vld,
    input         Output_1_V_V_ap_ack,
    
    input [31:0]  Input_2_V_V,
    input         Input_2_V_V_ap_vld,
    output        Input_2_V_V_ap_ack,
    output [31:0] Output_2_V_V,
    output        Output_2_V_V_ap_vld,
    input         Output_2_V_V_ap_ack,

    input [31:0]  Input_3_V_V,
    input         Input_3_V_V_ap_vld,
    output        Input_3_V_V_ap_ack,
    output [31:0] Output_3_V_V,
    output        Output_3_V_V_ap_vld,
    input         Output_3_V_V_ap_ack,
    
    input [31:0]  Input_4_V_V,
    input         Input_4_V_V_ap_vld,
    output        Input_4_V_V_ap_ack,
    output [31:0] Output_4_V_V,
    output        Output_4_V_V_ap_vld,
    input         Output_4_V_V_ap_ack,

    input [31:0]  Input_5_V_V,
    input         Input_5_V_V_ap_vld,
    output        Input_5_V_V_ap_ack,
    output [31:0] Output_5_V_V,
    output        Output_5_V_V_ap_vld,
    input         Output_5_V_V_ap_ack,

    input [31:0]  Input_6_V_V,
    input         Input_6_V_V_ap_vld,
    output        Input_6_V_V_ap_ack,
    output [31:0] Output_6_V_V,
    output        Output_6_V_V_ap_vld,
    input         Output_6_V_V_ap_ack,
    
    input wire reset
    );
    
    leaf_interface #(
        .PACKET_BITS(49),
        .PAYLOAD_BITS(32), 
        .NUM_LEAF_BITS(5),
        .NUM_PORT_BITS(4),
        .NUM_ADDR_BITS(7),
        .NUM_IN_PORTS(6), 
        .NUM_OUT_PORTS(6),
        .NUM_BRAM_ADDR_BITS(7),
        .FREESPACE_UPDATE_SIZE(64)
    )leaf_interface_inst(
        .clk_bft(clk_bft),
        .clk_user(clk_user),
        .reset(reset),
        .reset_bft(reset_bft),
        .din_leaf_bft2interface(din_leaf_bft2interface),
        .dout_leaf_interface2bft(dout_leaf_interface2bft),
        .resend(resend),
        .dout_leaf_interface2user({Output_6_V_V, Output_5_V_V, Output_4_V_V, Output_3_V_V, Output_2_V_V, Output_1_V_V}),
        .vld_interface2user({Output_6_V_V_ap_vld, Output_5_V_V_ap_vld, Output_4_V_V_ap_vld, Output_3_V_V_ap_vld, Output_2_V_V_ap_vld, Output_1_V_V_ap_vld}),
        .ack_user2interface({Output_6_V_V_ap_ack, Output_5_V_V_ap_ack, Output_4_V_V_ap_ack, Output_3_V_V_ap_ack, Output_2_V_V_ap_ack, Output_1_V_V_ap_ack}),
        .ack_interface2user({Input_6_V_V_ap_ack, Input_5_V_V_ap_ack, Input_4_V_V_ap_ack, Input_3_V_V_ap_ack, Input_2_V_V_ap_ack, Input_1_V_V_ap_ack}),
        .vld_user2interface({Input_6_V_V_ap_vld, Input_5_V_V_ap_vld, Input_4_V_V_ap_vld, Input_3_V_V_ap_vld, Input_2_V_V_ap_vld, Input_1_V_V_ap_vld}),
        .din_leaf_user2interface({Input_6_V_V, Input_5_V_V, Input_4_V_V, Input_3_V_V, Input_2_V_V, Input_1_V_V})
    );
    
    
endmodule
