//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
//Date        : Fri May 29 11:10:46 2020
//Host        : ylxiao-OptiPlex-7050 running 64-bit Ubuntu 18.04.4 LTS
//Command     : generate_target floorplan_static_wrapper.bd
//Design      : floorplan_static_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module test();

  reg [31:0]Input_1_V_V;
  reg [31:0]Input_1_V_V_1;
  wire Input_1_V_V_ap_ack;
  wire Input_1_V_V_ap_ack_1;
  reg Input_1_V_V_ap_vld;
  reg Input_1_V_V_ap_vld_1;
  reg [31:0]Input_2_V_V;
  wire Input_2_V_V_ap_ack;
  reg Input_2_V_V_ap_vld;
  reg [31:0]Input_3_V_V;
  wire Input_3_V_V_ap_ack;
  reg Input_3_V_V_ap_vld;
  reg [31:0]Input_4_V_V;
  wire Input_4_V_V_ap_ack;
  reg Input_4_V_V_ap_vld;
  reg [31:0]Input_5_V_V;
  wire Input_5_V_V_ap_ack;
  reg Input_5_V_V_ap_vld;
  reg [31:0]Input_6_V_V;
  wire Input_6_V_V_ap_ack;
  reg Input_6_V_V_ap_vld;
  wire [31:0]Output_1_V_V;
  wire [31:0]Output_1_V_V_1;
  reg Output_1_V_V_ap_ack;
  reg Output_1_V_V_ap_ack_1;
  wire Output_1_V_V_ap_vld;
  wire Output_1_V_V_ap_vld_1;
  wire [31:0]Output_2_V_V;
  reg Output_2_V_V_ap_ack;
  wire Output_2_V_V_ap_vld;
  wire [31:0]Output_3_V_V;
  reg Output_3_V_V_ap_ack;
  wire Output_3_V_V_ap_vld;
  wire [31:0]Output_4_V_V;
  reg Output_4_V_V_ap_ack;
  wire Output_4_V_V_ap_vld;
  wire [31:0]Output_5_V_V;
  reg Output_5_V_V_ap_ack;
  wire Output_5_V_V_ap_vld;
  wire [31:0]Output_6_V_V;
  reg Output_6_V_V_ap_ack;
  wire Output_6_V_V_ap_vld;
  reg clk0;
  reg clk1;
  reg [48:0]leaf_0_in;
  wire [48:0]leaf_0_out;
  wire resend_0;
  reg reset_n;


  floorplan_static_wrapper i1
       (.Input_1_V_V(Input_1_V_V),
        .Input_1_V_V_1(Input_1_V_V_1),
        .Input_1_V_V_ap_ack(Input_1_V_V_ap_ack),
        .Input_1_V_V_ap_ack_1(Input_1_V_V_ap_ack_1),
        .Input_1_V_V_ap_vld(Input_1_V_V_ap_vld),
        .Input_1_V_V_ap_vld_1(Input_1_V_V_ap_vld_1),
        .Input_2_V_V(Input_2_V_V),
        .Input_2_V_V_ap_ack(Input_2_V_V_ap_ack),
        .Input_2_V_V_ap_vld(Input_2_V_V_ap_vld),
        .Input_3_V_V(Input_3_V_V),
        .Input_3_V_V_ap_ack(Input_3_V_V_ap_ack),
        .Input_3_V_V_ap_vld(Input_3_V_V_ap_vld),
        .Input_4_V_V(Input_4_V_V),
        .Input_4_V_V_ap_ack(Input_4_V_V_ap_ack),
        .Input_4_V_V_ap_vld(Input_4_V_V_ap_vld),
        .Input_5_V_V(Input_5_V_V),
        .Input_5_V_V_ap_ack(Input_5_V_V_ap_ack),
        .Input_5_V_V_ap_vld(Input_5_V_V_ap_vld),
        .Input_6_V_V(Input_6_V_V),
        .Input_6_V_V_ap_ack(Input_6_V_V_ap_ack),
        .Input_6_V_V_ap_vld(Input_6_V_V_ap_vld),
        .Output_1_V_V(Output_1_V_V),
        .Output_1_V_V_1(Output_1_V_V_1),
        .Output_1_V_V_ap_ack(Output_1_V_V_ap_ack),
        .Output_1_V_V_ap_ack_1(Output_1_V_V_ap_ack_1),
        .Output_1_V_V_ap_vld(Output_1_V_V_ap_vld),
        .Output_1_V_V_ap_vld_1(Output_1_V_V_ap_vld_1),
        .Output_2_V_V(Output_2_V_V),
        .Output_2_V_V_ap_ack(Output_2_V_V_ap_ack),
        .Output_2_V_V_ap_vld(Output_2_V_V_ap_vld),
        .Output_3_V_V(Output_3_V_V),
        .Output_3_V_V_ap_ack(Output_3_V_V_ap_ack),
        .Output_3_V_V_ap_vld(Output_3_V_V_ap_vld),
        .Output_4_V_V(Output_4_V_V),
        .Output_4_V_V_ap_ack(Output_4_V_V_ap_ack),
        .Output_4_V_V_ap_vld(Output_4_V_V_ap_vld),
        .Output_5_V_V(Output_5_V_V),
        .Output_5_V_V_ap_ack(Output_5_V_V_ap_ack),
        .Output_5_V_V_ap_vld(Output_5_V_V_ap_vld),
        .Output_6_V_V(Output_6_V_V),
        .Output_6_V_V_ap_ack(Output_6_V_V_ap_ack),
        .Output_6_V_V_ap_vld(Output_6_V_V_ap_vld),
        .clk0(clk0),
        .clk1(clk1),
        .leaf_0_in(leaf_0_in),
        .leaf_0_out(leaf_0_out),
        .resend_0(resend_0),
        .reset_n(reset_n));
















endmodule

