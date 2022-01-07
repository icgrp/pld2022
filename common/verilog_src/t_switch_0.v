`include "direction_params.vh"
module t_switch_0 (
	input clk,
	input reset,
	input [p_sz-1:0] l_bus_i,
	input [p_sz-1:0] r_bus_i,
	input [p_sz-1:0] u_bus_i,
	output reg [p_sz-1:0] l_bus_o,
	output reg [p_sz-1:0] r_bus_o,
	output reg [p_sz-1:0] u_bus_o
	);
	// Override these values in top modules
	parameter num_leaves= 2;
	parameter payload_sz= 1;
	parameter addr= 1'b0;
	parameter level= 15; // only change if level == 0
	parameter p_sz= 1+$clog2(num_leaves)+payload_sz; //packet size
	
	// bus has following structure: 1 bit [valid], logN bits [dest_addr],
	// M bits [payload]
	
	wire [1:0] d_l;
	wire [1:0] d_r;
	wire [1:0] d_u;
        wire [1:0] d_l_p0;
	wire [1:0] d_r_p0;
	wire [1:0] d_u_p0;
	wire [1:0] sel_l;
	wire [1:0] sel_r;
	wire [1:0] sel_u;
	wire [1:0] sel_l_p0;
	wire [1:0] sel_r_p0;
	wire [1:0] sel_u_p0;


        wire [p_sz-1:0] l_bus_i_p0;
	wire [p_sz-1:0] r_bus_i_p0;
	wire [p_sz-1:0] u_bus_i_p0;

        wire [p_sz-1:0] l_bus_i_p1;
	wire [p_sz-1:0] r_bus_i_p1;
	wire [p_sz-1:0] u_bus_i_p1;

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_inst_l_bus_i_p0(
		.clk(clk),
		.din(l_bus_i),
		.dout(l_bus_i_p0));
	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_inst_r_bus_i_p0(
		.clk(clk),
		.din(r_bus_i),
		.dout(r_bus_i_p0));
	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_inst_u_bus_i_p0(
		.clk(clk),
		.din(u_bus_i),
		.dout(u_bus_i_p0));
//

	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_inst_l_bus_i_p1(
		.clk(clk),
		.din(l_bus_i_p0),
		.dout(l_bus_i_p1));
	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_inst_r_bus_i_p1(
		.clk(clk),
		.din(r_bus_i_p0),
		.dout(r_bus_i_p1));
	pipe_ff_0 #(
		.data_width(p_sz)
		)pipe_ff_inst_u_bus_i_p1(
		.clk(clk),
		.din(u_bus_i_p0),
		.dout(u_bus_i_p1));
//

	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_inst_d_l_p0(
		.clk(clk),
		.din(d_l),
		.dout(d_l_p0));

	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_inst_d_r_p0(
		.clk(clk),
		.din(d_r),
		.dout(d_r_p0));

	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_inst_d_u_p0(
		.clk(clk),
		.din(d_u),
		.dout(d_u_p0));

//


	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_inst_sel_l_p0(
		.clk(clk),
		.din(sel_l),
		.dout(sel_l_p0));

	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_inst_sel_r_p0(
		.clk(clk),
		.din(sel_r),
		.dout(sel_r_p0));
	pipe_ff_0 #(
		.data_width(2)
		)pipe_ff_inst_sel_u_p0(
		.clk(clk),
		.din(sel_u),
		.dout(sel_u_p0));



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
						   	dd_u(
							.valid_i(u_bus_i[p_sz-1]),
							.addr_i(u_bus_i[p_sz-2:payload_sz]),
							.d(d_u));

						
	t_arbiter_0 #(.level(level))
	t_a(d_l_p0, d_r_p0, d_u_p0, sel_l, sel_r, sel_u);

	always @(posedge clk)
		if (reset)
			{l_bus_o, r_bus_o, u_bus_o} <= 0;
		else begin
			case (sel_l_p0)
				`VOID: l_bus_o<= 0;
				`LEFT: l_bus_o<= l_bus_i_p1;
				`RIGHT: l_bus_o<= r_bus_i_p1;
				`UP: l_bus_o<= u_bus_i_p1;
			endcase
		
			case (sel_r_p0)
				`VOID: r_bus_o<= 0;
				`LEFT: r_bus_o<= l_bus_i_p1;
				`RIGHT: r_bus_o<= r_bus_i_p1;
				`UP: r_bus_o<= u_bus_i_p1;
			endcase
			
			case (sel_u_p0)
				`VOID: u_bus_o <= 0;
				`LEFT: u_bus_o <= l_bus_i_p1;
				`RIGHT: u_bus_o <= r_bus_i_p1;
				`UP: u_bus_o <= u_bus_i_p1;
			endcase
		end
endmodule	
