`include "direction_params.vh"
module pi_switch_0 (
	input clk,
	input reset,
	input [p_sz-1:0] l_bus_i,
	input [p_sz-1:0] r_bus_i,
	input [p_sz-1:0] ul_bus_i,
	input [p_sz-1:0] ur_bus_i,
	output reg [p_sz-1:0] l_bus_o,
	output reg [p_sz-1:0] r_bus_o,
	output reg [p_sz-1:0] ul_bus_o,
	output reg [p_sz-1:0] ur_bus_o
	);
	// Override these values in top modules
	parameter num_leaves= 2;
	parameter payload_sz= 1;
	parameter addr= 1'b0;
	parameter level= 0; // only change if level == 0
	parameter p_sz= 1+$clog2(num_leaves)+payload_sz; //packet size
	
	// bus has following structure: 1 bit [valid], logN bits [dest_addr],
	// M bits [payload]
	
	wire [1:0] d_l;
	wire [1:0] d_r;
	wire [1:0] d_ul;
	wire [1:0] d_ur;
        wire [1:0] d_l_p0;
	wire [1:0] d_r_p0;
	wire [1:0] d_ul_p0;
	wire [1:0] d_ur_p0;
	wire [1:0] sel_l;
	wire [1:0] sel_r;
	wire [1:0] sel_ul;
	wire [1:0] sel_ur;

	wire [1:0] sel_l_p0;
	wire [1:0] sel_r_p0;
	wire [1:0] sel_ul_p0;
	wire [1:0] sel_ur_p0;


	reg random;
	wire rand_gen;

        wire [p_sz-1:0] l_bus_i_p0;
	wire [p_sz-1:0] r_bus_i_p0;
	wire [p_sz-1:0] ul_bus_i_p0;
	wire [p_sz-1:0] ur_bus_i_p0;

        wire [p_sz-1:0] l_bus_i_p1;
	wire [p_sz-1:0] r_bus_i_p1;
	wire [p_sz-1:0] ul_bus_i_p1;
	wire [p_sz-1:0] ur_bus_i_p1;

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_0_inst_l_bus_i_p0(
		.clk(clk),
		.din(l_bus_i),
		.dout(l_bus_i_p0));

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_0_inst_r_bus_i_p0(
		.clk(clk),
		.din(r_bus_i),
		.dout(r_bus_i_p0));

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_0_inst_ul_bus_i_p0(
		.clk(clk),
		.din(ul_bus_i),
		.dout(ul_bus_i_p0));

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_0_inst_ur_bus_i_p0(
		.clk(clk),
		.din(ur_bus_i),
		.dout(ur_bus_i_p0));



	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_0_inst_l_bus_i_p1(
		.clk(clk),
		.din(l_bus_i_p0),
		.dout(l_bus_i_p1));

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_0_inst_r_bus_i_p1(
		.clk(clk),
		.din(r_bus_i_p0),
		.dout(r_bus_i_p1));

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_0_inst_ul_bus_i_p1(
		.clk(clk),
		.din(ul_bus_i_p0),
		.dout(ul_bus_i_p1));

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_0_inst_ur_bus_i_p1(
		.clk(clk),
		.din(ur_bus_i_p0),
		.dout(ur_bus_i_p1));


	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_0_inst_d_l_p0(
		.clk(clk),
		.din(d_l),
		.dout(d_l_p0));

	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_0_inst_d_r_p0(
		.clk(clk),
		.din(d_r),
		.dout(d_r_p0));

	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_0_inst_d_ul_p0(
		.clk(clk),
		.din(d_ul),
		.dout(d_ul_p0));

	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_0_inst_d_ur_p0(
		.clk(clk),
		.din(d_ur),
		.dout(d_ur_p0));


	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_0_inst_sel_l_p0(
		.clk(clk),
		.din(sel_l),
		.dout(sel_l_p0));

	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_0_inst_sel_r_p0(
		.clk(clk),
		.din(sel_r),
		.dout(sel_r_p0));
	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_0_inst_sel_ul_p0(
		.clk(clk),
		.din(sel_ul),
		.dout(sel_ul_p0));
	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_0_inst_sel_ur_p0(
		.clk(clk),
		.din(sel_ur),
		.dout(sel_ur_p0));





	direction_determiner_0 #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level)) 
							dd_l(
							.valid_i(l_bus_i[p_sz-1]),
							.addr_i(l_bus_i[p_sz-2:payload_sz]), 
							.d(d_l));

	direction_determiner_0 #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level)) 
							dd_r(
							.valid_i(r_bus_i[p_sz-1]),
							.addr_i(r_bus_i[p_sz-2:payload_sz]), 
							.d(d_r));

	direction_determiner_0 #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level))
						   	dd_ul(
							.valid_i(ul_bus_i[p_sz-1]),
							.addr_i(ul_bus_i[p_sz-2:payload_sz]),
							.d(d_ul));

	direction_determiner_0 #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level))
						   	dd_ur(
							.valid_i(ur_bus_i[p_sz-1]),
							.addr_i(ur_bus_i[p_sz-2:payload_sz]),
							.d(d_ur));
	always @(posedge clk)
		if (reset)
			random <= 1'b0;
		else if (rand_gen)
			random <= ~random;
						
	pi_arbiter_0 #(
				.level(level))
				pi_a(
					.d_l(d_l_p0),
					.d_r(d_r_p0),
				   	.d_ul(d_ul_p0),
				   	.d_ur(d_ur_p0),
				   	.sel_l(sel_l),
				   	.sel_r(sel_r),
				   	.sel_ul(sel_ul),
				   	.sel_ur(sel_ur),
					.random(random),
					.rand_gen(rand_gen));

	always @(posedge clk)
		if (reset)
			{l_bus_o, r_bus_o, ul_bus_o, ur_bus_o} <= 0;
		else begin
			case (sel_l_p0)
				`LEFT: l_bus_o<= l_bus_i_p1;
				`RIGHT: l_bus_o<= r_bus_i_p1;
				`UPL: l_bus_o<= ul_bus_i_p1;
				`UPR: l_bus_o<= ur_bus_i_p1;
			endcase
		
			case (sel_r_p0)
				`LEFT: r_bus_o<= l_bus_i_p1;
				`RIGHT: r_bus_o<= r_bus_i_p1;
				`UPL: r_bus_o<= ul_bus_i_p1;
				`UPR: r_bus_o<= ur_bus_i_p1;
			endcase
			
			case (sel_ul_p0)
				`LEFT: ul_bus_o <= l_bus_i_p1;
				`RIGHT: ul_bus_o <= r_bus_i_p1;
				`UPL: ul_bus_o <= ul_bus_i_p1;
				`UPR: ul_bus_o <= ur_bus_i_p1;
			endcase

			case (sel_ur_p0)
				`LEFT: ur_bus_o <= l_bus_i_p1;
				`RIGHT: ur_bus_o <= r_bus_i_p1;
				`UPL: ur_bus_o <= ul_bus_i_p1;
				`UPR: ur_bus_o <= ur_bus_i_p1;
			endcase

		end
endmodule	
