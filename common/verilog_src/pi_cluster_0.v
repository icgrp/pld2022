`define PI_SWITCH
module pi_cluster_0 (
	input clk,
	input reset,
	input [num_switches*p_sz-1:0] l_bus_i,
	input [num_switches*p_sz-1:0] r_bus_i,
	input [2*num_switches*p_sz-1:0] u_bus_i,
	output [num_switches*p_sz-1:0] l_bus_o,
	output [num_switches*p_sz-1:0] r_bus_o,
	output [2*num_switches*p_sz-1:0] u_bus_o
	);
	// Override these values in top modules
	parameter num_leaves= 2;
	parameter payload_sz= 1;
	parameter addr= 1'b0;
	parameter level= 1; // only change if level == 0
	parameter p_sz= 1+$clog2(num_leaves)+payload_sz; //packet size
	parameter num_switches= 1;

	wire [num_switches*p_sz-1:0] ul_bus_i;
	wire [num_switches*p_sz-1:0] ur_bus_i;
	wire [num_switches*p_sz-1:0] ul_bus_o;
	wire [num_switches*p_sz-1:0] ur_bus_o;
	
	assign {ul_bus_i, ur_bus_i} = u_bus_i;
	assign u_bus_o= {ul_bus_o, ur_bus_o};
	genvar i;
	generate
	for (i= 0; i < num_switches; i= i + 1) begin
		pi_switch_0 #(
			.num_leaves(num_leaves),
			.payload_sz(payload_sz),
			.addr(addr),
			.level(level),
			.p_sz(p_sz))
			ps (
				.clk(clk),
				.reset(reset),
				.l_bus_i(l_bus_i[i*p_sz+:p_sz]),
				.r_bus_i(r_bus_i[i*p_sz+:p_sz]),
				.ul_bus_i(ul_bus_i[i*p_sz+:p_sz]),
				.ur_bus_i(ur_bus_i[i*p_sz+:p_sz]),
				.l_bus_o(l_bus_o[i*p_sz+:p_sz]),
				.r_bus_o(r_bus_o[i*p_sz+:p_sz]),
				.ul_bus_o(ul_bus_o[i*p_sz+:p_sz]),
				.ur_bus_o(ur_bus_o[i*p_sz+:p_sz]));
	end
	endgenerate
endmodule	


