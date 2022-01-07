module subtree_212_wrapper #(
	parameter num_leaves = 32,
	parameter payload_sz = 43,
	parameter p_sz = 49,
	parameter addr = 2'b00,
	parameter level = 2
	)(

	input [p_sz-1:0] leaf_0_in, 
	input [p_sz-1:0] leaf_1_in, 
	input [p_sz-1:0] leaf_2_in, 
	input [p_sz-1:0] leaf_3_in, 
	input [p_sz-1:0] leaf_4_in, 
	input [p_sz-1:0] leaf_5_in, 
	input [p_sz-1:0] leaf_6_in, 
	input [p_sz-1:0] leaf_7_in, 
	output [p_sz-1:0] leaf_0_out, 
	output [p_sz-1:0] leaf_1_out, 
	output [p_sz-1:0] leaf_2_out, 
	output [p_sz-1:0] leaf_3_out, 
	output [p_sz-1:0] leaf_4_out, 
	output [p_sz-1:0] leaf_5_out, 
	output [p_sz-1:0] leaf_6_out, 
	output [p_sz-1:0] leaf_7_out,


	output resend_0, 
	output resend_1, 
	output resend_2, 
	output resend_3, 
	output resend_4, 
	output resend_5, 
	output resend_6, 
	output resend_7, 
	
	input [2*2*p_sz-1:0] bus_i,
	output [2*2*p_sz-1:0] bus_o,
	
	input clk,
	input reset);



 subtree_212 # (
	.num_leaves(num_leaves),
	.payload_sz(payload_sz),
	.p_sz(p_sz),
	.addr(addr),
	.level(level)
	) u0 (
	.clk(clk),
	.reset(reset),
	.pe_interface({leaf_7_in,leaf_6_in,leaf_5_in,leaf_4_in,leaf_3_in,leaf_2_in,leaf_1_in,leaf_0_in}),
	.interface_pe({leaf_7_out,leaf_6_out,leaf_5_out,leaf_4_out,leaf_3_out,leaf_2_out,leaf_1_out,leaf_0_out}),
	.resend({resend_7,resend_6,resend_5,resend_4,resend_3,resend_2,resend_1,resend_0} ),
	.bus_i(bus_i),
	.bus_o(bus_o)
);


endmodule
