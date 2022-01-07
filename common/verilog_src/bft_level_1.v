module bft_level_1(
  input clk,
  input [195:0] din,
  input [48:0] leaf_0_in,
  input [48:0] leaf_1_in,
  input [48:0] leaf_2_in,
  input [48:0] leaf_3_in,
  input [48:0] leaf_4_in,
  input [48:0] leaf_5_in,
  input [48:0] leaf_6_in,
  input [48:0] leaf_7_in,
  input reset,

  output [195:0] bus_o,
  output [48:0] leaf_0_out,
  output [48:0] leaf_1_out,
  output [48:0] leaf_2_out,
  output [48:0] leaf_3_out,
  output [48:0] leaf_4_out,
  output [48:0] leaf_5_out,
  output [48:0] leaf_6_out,
  output [48:0] leaf_7_out,
  output resend_0,
  output resend_1,
  output resend_2,
  output resend_3,
  output resend_4,
  output resend_5,
  output resend_6,
  output resend_7);



endmodule
