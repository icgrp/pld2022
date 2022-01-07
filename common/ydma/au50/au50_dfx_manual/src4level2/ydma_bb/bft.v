module bft(
    input clk,
    input  [49-1:0]dout_leaf_0,
    input  [49-1:0]dout_leaf_1,
    input  [49-1:0]dout_leaf_2,
    input  [49-1:0]dout_leaf_3,
    input  [49-1:0]dout_leaf_4,
    input  [49-1:0]dout_leaf_5,
    input  [49-1:0]dout_leaf_6,
    input  [49-1:0]dout_leaf_7,
    input  [49-1:0]dout_leaf_8,
    input  [49-1:0]dout_leaf_9,
    input  [49-1:0]dout_leaf_10,
    input  [49-1:0]dout_leaf_11,
    input  [49-1:0]dout_leaf_12,
    input  [49-1:0]dout_leaf_13,
    input  [49-1:0]dout_leaf_14,
    input  [49-1:0]dout_leaf_15,
    input  [49-1:0]dout_leaf_16,
    input  [49-1:0]dout_leaf_17,
    input  [49-1:0]dout_leaf_18,
    input  [49-1:0]dout_leaf_19,
    input  [49-1:0]dout_leaf_20,
    input  [49-1:0]dout_leaf_21,
    input  [49-1:0]dout_leaf_22,
    input  [49-1:0]dout_leaf_23,
    input  [49-1:0]dout_leaf_24,
    input  [49-1:0]dout_leaf_25,
    input  [49-1:0]dout_leaf_26,
    input  [49-1:0]dout_leaf_27,
    input  [49-1:0]dout_leaf_28,
    input  [49-1:0]dout_leaf_29,
    input  [49-1:0]dout_leaf_30,
    input  [49-1:0]dout_leaf_31,
    output [49-1:0]din_leaf_0,
    output [49-1:0]din_leaf_1,
    output [49-1:0]din_leaf_2,
    output [49-1:0]din_leaf_3,
    output [49-1:0]din_leaf_4,
    output [49-1:0]din_leaf_5,
    output [49-1:0]din_leaf_6,
    output [49-1:0]din_leaf_7,
    output [49-1:0]din_leaf_8,
    output [49-1:0]din_leaf_9,
    output [49-1:0]din_leaf_10,
    output [49-1:0]din_leaf_11,
    output [49-1:0]din_leaf_12,
    output [49-1:0]din_leaf_13,
    output [49-1:0]din_leaf_14,
    output [49-1:0]din_leaf_15,
    output [49-1:0]din_leaf_16,
    output [49-1:0]din_leaf_17,
    output [49-1:0]din_leaf_18,
    output [49-1:0]din_leaf_19,
    output [49-1:0]din_leaf_20,
    output [49-1:0]din_leaf_21,
    output [49-1:0]din_leaf_22,
    output [49-1:0]din_leaf_23,
    output [49-1:0]din_leaf_24,
    output [49-1:0]din_leaf_25,
    output [49-1:0]din_leaf_26,
    output [49-1:0]din_leaf_27,
    output [49-1:0]din_leaf_28,
    output [49-1:0]din_leaf_29,
    output [49-1:0]din_leaf_30,
    output [49-1:0]din_leaf_31,
    output resend_0,
    output resend_1,
    output resend_2,
    output resend_3,
    output resend_4,
    output resend_5,
    output resend_6,
    output resend_7,
    output resend_8,
    output resend_9,
    output resend_10,
    output resend_11,
    output resend_12,
    output resend_13,
    output resend_14,
    output resend_15,
    output resend_16,
    output resend_17,
    output resend_18,
    output resend_19,
    output resend_20,
    output resend_21,
    output resend_22,
    output resend_23,
    output resend_24,
    output resend_25,
    output resend_26,
    output resend_27,
    output resend_28,
    output resend_29,
    output resend_30,
    output resend_31,
    input reset);
gen_nw32 # (        .num_leaves(32),
    .payload_sz(43),
    .p_sz(49),
    .addr(1'b0),
    .level(0)
    ) gen_nw32 (
    .clk(clk),
    .reset(reset),
    .pe_interface({
    dout_leaf_31,
    dout_leaf_30,
    dout_leaf_29,
    dout_leaf_28,
    dout_leaf_27,
    dout_leaf_26,
    dout_leaf_25,
    dout_leaf_24,
    dout_leaf_23,
    dout_leaf_22,
    dout_leaf_21,
    dout_leaf_20,
    dout_leaf_19,
    dout_leaf_18,
    dout_leaf_17,
    dout_leaf_16,
    dout_leaf_15,
    dout_leaf_14,
    dout_leaf_13,
    dout_leaf_12,
    dout_leaf_11,
    dout_leaf_10,
    dout_leaf_9,
    dout_leaf_8,
    dout_leaf_7,
    dout_leaf_6,
    dout_leaf_5,
    dout_leaf_4,
    dout_leaf_3,
    dout_leaf_2,
    dout_leaf_1,
    dout_leaf_0}),
    .interface_pe({
    din_leaf_31,
    din_leaf_30,
    din_leaf_29,
    din_leaf_28,
    din_leaf_27,
    din_leaf_26,
    din_leaf_25,
    din_leaf_24,
    din_leaf_23,
    din_leaf_22,
    din_leaf_21,
    din_leaf_20,
    din_leaf_19,
    din_leaf_18,
    din_leaf_17,
    din_leaf_16,
    din_leaf_15,
    din_leaf_14,
    din_leaf_13,
    din_leaf_12,
    din_leaf_11,
    din_leaf_10,
    din_leaf_9,
    din_leaf_8,
    din_leaf_7,
    din_leaf_6,
    din_leaf_5,
    din_leaf_4,
    din_leaf_3,
    din_leaf_2,
    din_leaf_1,
    din_leaf_0}),
    .resend({
    resend_31,
    resend_30,
    resend_29,
    resend_28,
    resend_27,
    resend_26,
    resend_25,
    resend_24,
    resend_23,
    resend_22,
    resend_21,
    resend_20,
    resend_19,
    resend_18,
    resend_17,
    resend_16,
    resend_15,
    resend_14,
    resend_13,
    resend_12,
    resend_11,
    resend_10,
    resend_9,
    resend_8,
    resend_7,
    resend_6,
    resend_5,
    resend_4,
    resend_3,
    resend_2,
    resend_1,
    resend_0}));
endmodule

module gen_nw32 # (
	parameter num_leaves= 32,
	parameter payload_sz= $clog2(num_leaves) + 4,
	parameter p_sz= 1 + $clog2(num_leaves) + payload_sz, //packet size
	parameter addr= 1'b0,
	parameter level= 0
	) (
	input clk,
	input reset,
	input [p_sz*32-1:0] pe_interface,
	output [p_sz*32-1:0] interface_pe,
	output [32-1:0] resend
);
	
	wire [4*p_sz-1:0] switch_left;
	wire [4*p_sz-1:0] switch_right;
	wire [4*p_sz-1:0] left_switch;
	wire [4*p_sz-1:0] right_switch;



	pi_cluster #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr(addr),
		.level(level),
		.p_sz(p_sz),
		.num_switches(4))
		pi_lvl0(
			.clk(clk),
			.reset(reset),


			.l_bus_i(left_switch),
			.r_bus_i(right_switch),
			.l_bus_o(switch_left),
			.r_bus_o(switch_right));

	_2121subtree #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({1'b0}),
		.p_sz(p_sz))
		subtree_left(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_left),
			.bus_o(left_switch),
			.pe_interface(pe_interface[p_sz*16-1:0]),
			.interface_pe(interface_pe[p_sz*16-1:0]),
			.resend(resend[16-1:0]));

	_2121subtree #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({1'b1}),
		.p_sz(p_sz))
		subtree_right(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_right),
			.bus_o(right_switch),
			.pe_interface(pe_interface[p_sz*32-1:p_sz*16]),
			.interface_pe(interface_pe[p_sz*32-1:p_sz*16]),
			.resend(resend[32-1:16]));
endmodule
module _2121subtree # (
	parameter num_leaves= 32,
	parameter payload_sz= $clog2(num_leaves) + 4,
	parameter p_sz= 1 + $clog2(num_leaves) + payload_sz, //packet size
	parameter addr= 1'b0,
	parameter level= 1
	) (
	input clk,
	input reset,
	input [p_sz*16-1:0] pe_interface,
	output [p_sz*16-1:0] interface_pe,
	output [16-1:0] resend,
	input [1*4*p_sz-1:0] bus_i,

	output [1*4*p_sz-1:0] bus_o
);
	
	wire [4*p_sz-1:0] switch_left;
	wire [4*p_sz-1:0] switch_right;
	wire [4*p_sz-1:0] left_switch;
	wire [4*p_sz-1:0] right_switch;



	t_cluster #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr(addr),
		.level(level),
		.p_sz(p_sz),
		.num_switches(4))
		t_lvl1(
			.clk(clk),
			.reset(reset),
			.u_bus_i(bus_i),
			.u_bus_o(bus_o),
			.l_bus_i(left_switch),
			.r_bus_i(right_switch),
			.l_bus_o(switch_left),
			.r_bus_o(switch_right));

	_212subtree #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({addr, 1'b0}),
		.p_sz(p_sz))
		subtree_left(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_left),
			.bus_o(left_switch),
			.pe_interface(pe_interface[p_sz*8-1:0]),
			.interface_pe(interface_pe[p_sz*8-1:0]),
			.resend(resend[8-1:0]));

	_212subtree #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({addr, 1'b1}),
		.p_sz(p_sz))
		subtree_right(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_right),
			.bus_o(right_switch),
			.pe_interface(pe_interface[p_sz*16-1:p_sz*8]),
			.interface_pe(interface_pe[p_sz*16-1:p_sz*8]),
			.resend(resend[16-1:8]));
endmodule
module _212subtree # (
	parameter num_leaves= 32,
	parameter payload_sz= $clog2(num_leaves) + 4,
	parameter p_sz= 1 + $clog2(num_leaves) + payload_sz, //packet size
	parameter addr= 2'b00,
	parameter level= 2
	) (
	input clk,
	input reset,
	input [p_sz*8-1:0] pe_interface,
	output [p_sz*8-1:0] interface_pe,
	output [8-1:0] resend,
	input [2*2*p_sz-1:0] bus_i,

	output [2*2*p_sz-1:0] bus_o
);
	
	wire [2*p_sz-1:0] switch_left;
	wire [2*p_sz-1:0] switch_right;
	wire [2*p_sz-1:0] left_switch;
	wire [2*p_sz-1:0] right_switch;



	pi_cluster #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr(addr),
		.level(level),
		.p_sz(p_sz),
		.num_switches(2))
		pi_lvl2(
			.clk(clk),
			.reset(reset),
			.u_bus_i(bus_i),
			.u_bus_o(bus_o),
			.l_bus_i(left_switch),
			.r_bus_i(right_switch),
			.l_bus_o(switch_left),
			.r_bus_o(switch_right));

	_21subtree #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({addr, 1'b0}),
		.p_sz(p_sz))
		subtree_left(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_left),
			.bus_o(left_switch),
			.pe_interface(pe_interface[p_sz*4-1:0]),
			.interface_pe(interface_pe[p_sz*4-1:0]),
			.resend(resend[4-1:0]));

	_21subtree #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({addr, 1'b1}),
		.p_sz(p_sz))
		subtree_right(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_right),
			.bus_o(right_switch),
			.pe_interface(pe_interface[p_sz*8-1:p_sz*4]),
			.interface_pe(interface_pe[p_sz*8-1:p_sz*4]),
			.resend(resend[8-1:4]));
endmodule
module _21subtree # (
	parameter num_leaves= 32,
	parameter payload_sz= $clog2(num_leaves) + 4,
	parameter p_sz= 1 + $clog2(num_leaves) + payload_sz, //packet size
	parameter addr= 3'b000,
	parameter level= 3
	) (
	input clk,
	input reset,
	input [p_sz*4-1:0] pe_interface,
	output [p_sz*4-1:0] interface_pe,
	output [4-1:0] resend,
	input [1*2*p_sz-1:0] bus_i,

	output [1*2*p_sz-1:0] bus_o
);
	
	wire [2*p_sz-1:0] switch_left;
	wire [2*p_sz-1:0] switch_right;
	wire [2*p_sz-1:0] left_switch;
	wire [2*p_sz-1:0] right_switch;



	t_cluster #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr(addr),
		.level(level),
		.p_sz(p_sz),
		.num_switches(2))
		t_lvl3(
			.clk(clk),
			.reset(reset),
			.u_bus_i(bus_i),
			.u_bus_o(bus_o),
			.l_bus_i(left_switch),
			.r_bus_i(right_switch),
			.l_bus_o(switch_left),
			.r_bus_o(switch_right));

	_2subtree #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({addr, 1'b0}),
		.p_sz(p_sz))
		subtree_left(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_left),
			.bus_o(left_switch),
			.pe_interface(pe_interface[p_sz*2-1:0]),
			.interface_pe(interface_pe[p_sz*2-1:0]),
			.resend(resend[2-1:0]));

	_2subtree #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({addr, 1'b1}),
		.p_sz(p_sz))
		subtree_right(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_right),
			.bus_o(right_switch),
			.pe_interface(pe_interface[p_sz*4-1:p_sz*2]),
			.interface_pe(interface_pe[p_sz*4-1:p_sz*2]),
			.resend(resend[4-1:2]));
endmodule
module _2subtree # (
	parameter num_leaves= 32,
	parameter payload_sz= $clog2(num_leaves) + 4,
	parameter p_sz= 1 + $clog2(num_leaves) + payload_sz, //packet size
	parameter addr= 4'b0000,
	parameter level= 4
	) (
	input clk,
	input reset,
	input [p_sz*2-1:0] pe_interface,
	output [p_sz*2-1:0] interface_pe,
	output [2-1:0] resend,
	input [2*1*p_sz-1:0] bus_i,

	output [2*1*p_sz-1:0] bus_o
);
	
	wire [1*p_sz-1:0] switch_left;
	wire [1*p_sz-1:0] switch_right;
	wire [1*p_sz-1:0] left_switch;
	wire [1*p_sz-1:0] right_switch;



	pi_cluster #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr(addr),
		.level(level),
		.p_sz(p_sz),
		.num_switches(1))
		pi_lvl4(
			.clk(clk),
			.reset(reset),
			.u_bus_i(bus_i),
			.u_bus_o(bus_o),
			.l_bus_i(left_switch),
			.r_bus_i(right_switch),
			.l_bus_o(switch_left),
			.r_bus_o(switch_right));

	interface #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({addr, 1'b0}),
		.p_sz(p_sz))
		subtree_left(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_left),
			.bus_o(left_switch),
			.pe_interface(pe_interface[p_sz*1-1:0]),
			.interface_pe(interface_pe[p_sz*1-1:0]),
			.resend(resend[1-1:0]));

	interface #(
		.num_leaves(num_leaves),
		.payload_sz(payload_sz),
		.addr({addr, 1'b1}),
		.p_sz(p_sz))
		subtree_right(
			.clk(clk),
			.reset(reset),
			.bus_i(switch_right),
			.bus_o(right_switch),
			.pe_interface(pe_interface[p_sz*2-1:p_sz*1]),
			.interface_pe(interface_pe[p_sz*2-1:p_sz*1]),
			.resend(resend[2-1:1]));
endmodule
`ifndef DIRECTION_PARAMS_H
`define DIRECTION_PARAMS_H
`define VOID 2'b00
`define LEFT 2'b01
`define RIGHT 2'b10
`define UP 2'b11
// Used for pi switch
`define UPL 2'b11
`define UPR 2'b00 // replaces VOID in t_switch
`endif

module direction_determiner (
	input valid_i,
	input [$clog2(num_leaves)-1:0] addr_i,
	output reg [1:0] d
	);

	// override these values in top modules
	parameter num_leaves= 0;
	parameter addr= 0;
	parameter level= 0;  //level = $bits(addr) 

	generate
		if (level == 0) begin
			always @*
				if (valid_i) begin
					if (addr_i[$clog2(num_leaves)-1])
						d= `RIGHT;
					else
						d= `LEFT;
				end
				else
					d= `VOID;
			end
		else begin
			wire [level-1:0]  addr_xnor_addr_i= 
				~(addr ^ addr_i[$clog2(num_leaves)-1:$clog2(num_leaves) - level]);

			always @*
				if (valid_i == 1'b0)
					d= `VOID;
				else if (&addr_xnor_addr_i == 1'b1) begin
					if (addr_i[$clog2(num_leaves)-1 - level] == 1'b0)
						d= `LEFT;
					else
						d= `RIGHT;
				end
				else if (&addr_xnor_addr_i == 1'b0)
					d= `UP;
				else
					d= `VOID;
		end
	endgenerate
endmodule
module interface #(
    parameter num_leaves= 2,
    parameter payload_sz= 1,
    parameter addr= 1'b0,
    parameter p_sz= 1 + $clog2(num_leaves) + payload_sz //packet size
    ) (
    input clk, 
    input reset, 
    input [p_sz-1:0] bus_i,
    output reg [p_sz-1:0] bus_o, 
    input [p_sz-1:0] pe_interface,
    output reg [p_sz-1:0] interface_pe,
    output resend
    );



    wire accept_packet;
    wire send_packet;
    assign accept_packet= bus_i[p_sz-1] && (bus_i[p_sz-2:payload_sz] == addr);
    assign send_packet= !(bus_i[p_sz-1] && addr != bus_i[p_sz-2:payload_sz]);
    assign resend = !send_packet;
    
    always @(posedge clk) begin
    //    cache_o <= pe_interface;
        if (reset)
            {interface_pe, bus_o} <= 0;
        else begin
            if (accept_packet) interface_pe <= bus_i;
            else interface_pe <= 0;
            
            if (send_packet) begin            
                bus_o <=  pe_interface;   
            end else begin
                bus_o <= bus_i;
            end
       end
   end
    
endmodule
/*
module pipe_ff (
	input clk, 
	input reset, 
	input [data_width-1:0] din,
	output reg [data_width-1:0] dout 
	);

	parameter data_width= 2;


	always @(posedge clk) begin
		if (reset)
			dout <= 0;
		else
			dout <=din;
	end
	
endmodule

*/

`define PI_SWITCH

module pi_arbiter(
	input [1:0] d_l,
	input [1:0] d_r,
	input [1:0] d_ul,
	input [1:0] d_ur,
	input random,
	output reg rand_gen,
	output reg [1:0] sel_l,
	output reg [1:0] sel_r,
	output [1:0] sel_ul,
	output [1:0] sel_ur
	);
	
	parameter level= 1;
	/*
	*	d_l, d_r, d_u designate where the specific packet from a 
	*	certain direction would like to (ideally) go.
	*	d_{l,r,u{l,r}}=00, non-valid packet. 
	*   d_{l,r,u{l,r}}=01, packet should go left.
	*	d_{l,r,u{l,r}}=10, packet should go right.
   	*	d_{l,r,u{l,r}}=11, packet should go up.
	*/

	reg [1:0] sel_u1;
	reg [1:0] sel_u2;

	assign sel_ul= random ? sel_u1 : sel_u2;
	assign sel_ur= random ? sel_u2 : sel_u1;

		
	// temp var just used to determine how to route non-valid packets
	reg [3:0] is_void; 

	always @* begin
		is_void= 4'b1111; // local var, order is L, R, U1, U2;
	
		rand_gen= 0;
		sel_l  = `VOID;
		sel_r  = `VOID;
		sel_u1 = `VOID;
		sel_u2 = `VOID;





		// First Priority: Turnback Packets
		if (d_l == `LEFT)
			{sel_l, is_void[3]}= {`LEFT, 1'b0};
		if (d_r == `RIGHT)
			{sel_r, is_void[2]}= {`RIGHT, 1'b0};
		if (d_ul == `UP)
			{sel_u1, is_void[1]}= {`UPL, 1'b0};
		if (d_ur == `UP)
			{sel_u2, is_void[0]}= {`UPR, 1'b0};

		// Second Priority: Downlinks
		// Left Downlink
		if (d_ul == `LEFT || d_ur == `LEFT) begin
			if (is_void[3]) begin
				is_void[3]= 1'b0;
				if (d_ul == `LEFT && d_ur != `LEFT)
					sel_l= `UPL;
				else if (d_ul != `LEFT && d_ur == `LEFT)
					sel_l= `UPR;
				else if (d_ul == `LEFT && d_ur == `LEFT) begin
					is_void[1]= 1'b0;
					{sel_l, sel_u1}= {`UPL, `UPR};
				end
			end
			else begin
				if (d_ul == `LEFT) begin
					is_void[1]= 1'b0;
					sel_u1= `UPL;
				end
				if (d_ur == `LEFT) begin
					is_void[0]= 1'b0;
					sel_u2= `UPR;
				end
			end
		end

		// Right Downlink
		if (d_ul == `RIGHT || d_ur == `RIGHT) begin
			if (is_void[2]) begin
				is_void[2]= 1'b0;
				if (d_ul == `RIGHT && d_ur != `RIGHT)
					sel_r= `UPL;
				else if (d_ul != `RIGHT && d_ur == `RIGHT)
					sel_r= `UPR;
				else if (d_ul == `RIGHT && d_ur == `RIGHT) begin
					is_void[1]= 1'b0;
					{sel_r, sel_u1}= {`UPL, `UPR};
				end
			end
			else begin
				if (d_ul == `RIGHT) begin
					is_void[1]= 1'b0;
					sel_u1= `UPL;
				end
				if (d_ur == `RIGHT) begin
					is_void[0]= 1'b0;
					sel_u2= `UPR;
				end
			end
		end


		// Third Priority: Side Link
		// Left to Right (Left has priority over Right)
		if (d_l == `RIGHT) begin
			if (is_void[2]) begin
				is_void[2]= 1'b0;
				sel_r= `LEFT;
			end
			else if (is_void[3]) begin
				is_void[3]= 1'b0;
				sel_l= `LEFT;
			end
			else if (is_void[1]) begin
				is_void[1]= 1'b0;
				sel_u1= `LEFT;
			end
			else if (is_void[0]) begin
				is_void[0]= 1'b0;
				sel_u2= `LEFT;
			end
		end

		// Right to Left
		if (d_r == `LEFT) begin
			if (is_void[3]) begin
				is_void[3]= 1'b0;
				sel_l= `RIGHT;
			end
			else if (is_void[2]) begin
				is_void[2]= 1'b0;
				sel_r= `RIGHT;
			end
			else if (is_void[1]) begin
				is_void[1]= 1'b0;
				sel_u1= `RIGHT;
			end
			else if (is_void[0]) begin
				is_void[0]= 1'b0;
				sel_u2= `RIGHT;
			end
		end
		// Fourth Priority: Uplinks
		// Left to Up
		if (d_l == `UP) begin
			if (is_void[1]) begin
				is_void[1]= 1'b0;
				sel_u1= `LEFT;
			end
			else if (is_void[0]) begin
				is_void[0]= 1'b0;
				sel_u2= `LEFT;
			end
			else if (is_void[3]) begin
				is_void[3]= 1'b0;
				sel_l= `LEFT;
			end
			else if (is_void[2]) begin
				is_void[2]= 1'b0;
				sel_r= `LEFT;
			end
		end
		// Right to UP
		if (d_r == `UP) begin
			if (is_void[1]) begin
				is_void[1]= 1'b0;
				sel_u1= `RIGHT;
			end
			else if (is_void[0]) begin
				is_void[0]= 1'b0;
				sel_u2= `RIGHT;
			end
			else if (is_void[2]) begin
				is_void[2]= 1'b0;
				sel_r= `RIGHT;
			end
			else if (is_void[3]) begin
				is_void[3]= 1'b0;
				sel_l= `RIGHT;
			end
		end

		// Before taking care of void case, determine whether or not a new
		// random/toggle bit should be generated
		if (is_void[1] == 1'b0 || is_void[0] == 1'b0)
			rand_gen= 1;

		// Final Priority: Void 
		if (d_l == `VOID) begin
			if (is_void[3]) begin
				is_void[3]= 1'b0;
				sel_l= `LEFT;
			end
			if (is_void[2]) begin
				is_void[2]= 1'b0;
				sel_r= `LEFT;
			end
			if (is_void[1]) begin
				is_void[1]= 1'b0;
				sel_u1= `LEFT;
			end
			if (is_void[0]) begin
				is_void[0]= 1'b0;
				sel_u2= `LEFT;
			end
		end
		if (d_r == `VOID) begin
			if (is_void[3]) begin
				is_void[3]= 1'b0;
				sel_l= `RIGHT;
			end
			if (is_void[2]) begin
				is_void[2]= 1'b0;
				sel_r= `RIGHT;
			end
			if (is_void[1]) begin
				is_void[1]= 1'b0;
				sel_u1= `RIGHT;
			end
			if (is_void[0]) begin
				is_void[0]= 1'b0;
				sel_u2= `RIGHT;
			end
		end
		if (d_ul == `VOID) begin
			if (is_void[3]) begin
				is_void[3]= 1'b0;
				sel_l= `UPL;
			end
			if (is_void[2]) begin
				is_void[2]= 1'b0;
				sel_r= `UPL;
			end
			if (is_void[1]) begin
				is_void[1]= 1'b0;
				sel_u1= `UPL;
			end
			if (is_void[0]) begin
				is_void[0]= 1'b0;
				sel_u2= `UPL;
			end
		end
		if (d_ur == `VOID) begin
			if (is_void[3]) begin
				is_void[3]= 1'b0;
				sel_l= `UPR;
			end
			if (is_void[2]) begin
				is_void[2]= 1'b0;
				sel_r= `UPR;
			end
			if (is_void[1]) begin
				is_void[1]= 1'b0;
				sel_u1= `UPR;
			end
			if (is_void[0]) begin
				is_void[0]= 1'b0;
				sel_u2= `UPR;
			end
		end
	end

endmodule


module pi_cluster (
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
		pi_switch #(
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


module pi_switch (
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
	wire [1:0] sel_l;
	wire [1:0] sel_r;
	wire [1:0] sel_ul;
	wire [1:0] sel_ur;
	reg random;
	wire rand_gen;

	direction_determiner #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level)) 
							dd_l(
							.valid_i(l_bus_i[p_sz-1]),
							.addr_i(l_bus_i[p_sz-2:payload_sz]), 
							.d(d_l));

	direction_determiner #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level)) 
							dd_r(
							.valid_i(r_bus_i[p_sz-1]),
							.addr_i(r_bus_i[p_sz-2:payload_sz]), 
							.d(d_r));

	direction_determiner #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level))
						   	dd_ul(
							.valid_i(ul_bus_i[p_sz-1]),
							.addr_i(ul_bus_i[p_sz-2:payload_sz]),
							.d(d_ul));

	direction_determiner #(.num_leaves(num_leaves), 
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
						
	pi_arbiter #(
				.level(level))
				pi_a(
					.d_l(d_l),
					.d_r(d_r),
				   	.d_ul(d_ul),
				   	.d_ur(d_ur),
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
			case (sel_l)
				`LEFT: l_bus_o<= l_bus_i;
				`RIGHT: l_bus_o<= r_bus_i;
				`UPL: l_bus_o<= ul_bus_i;
				`UPR: l_bus_o<= ur_bus_i;
			endcase
		
			case (sel_r)
				`LEFT: r_bus_o<= l_bus_i;
				`RIGHT: r_bus_o<= r_bus_i;
				`UPL: r_bus_o<= ul_bus_i;
				`UPR: r_bus_o<= ur_bus_i;
			endcase
			
			case (sel_ul)
				`LEFT: ul_bus_o <= l_bus_i;
				`RIGHT: ul_bus_o <= r_bus_i;
				`UPL: ul_bus_o <= ul_bus_i;
				`UPR: ul_bus_o <= ur_bus_i;
			endcase

			case (sel_ur)
				`LEFT: ur_bus_o <= l_bus_i;
				`RIGHT: ur_bus_o <= r_bus_i;
				`UPL: ur_bus_o <= ul_bus_i;
				`UPR: ur_bus_o <= ur_bus_i;
			endcase

		end
endmodule	



module t_arbiter(
	input [1:0] d_l,
	input [1:0] d_r,
	input [1:0] d_u,
	output reg [1:0] sel_l,
	output reg [1:0] sel_r,
	output reg [1:0] sel_u
	);
	
	parameter level= 1;
	/*
	*	d_l, d_r, d_u designate where the specific packet from a certain
	*	direction would like to (ideally go).
	*	d_{l,r,u}=00, non-valid packet. 
	*   d_{l,r,u}=01, packet should go left.
	*	d_{l,r,u}=10, packet should go right.
   	*	d_{l,r,u}=11, packet should go up.
	*/

	generate
		if (level == 0)
			always @* begin
				sel_l= `VOID;
				sel_r= `VOID;
				sel_u= `VOID;
				if (d_l == `LEFT)
					sel_l= `LEFT;
				if (d_r == `RIGHT)
					sel_r= `RIGHT;
				if (sel_l == `VOID && d_r == `LEFT)
					sel_l= `RIGHT;
                                if (sel_l == `LEFT && d_r == `LEFT)
					sel_r= `RIGHT;
				if (sel_r == `VOID && d_l == `RIGHT)
					sel_r= `LEFT;
				if (sel_r == `RIGHT && d_l == `RIGHT)
					sel_l= `LEFT;
			end
		else 
			/* 
			* select lines are for the MUX's that actually route the packets to the
			`UP* neighboring nodes. 
			*/
			always @* begin
				sel_l= `VOID;
				sel_r= `VOID;
				sel_u= `VOID;
				// First Priority: Turnback (When a packet has already been deflected
				// and needs to turn back within one level)
				if (d_l == `LEFT)
					sel_l= `LEFT;
				if (d_r == `RIGHT)
					sel_r= `RIGHT;
				if (d_u == `UP)
					sel_u= `UP;
				// Second Priority: Downlinks (When a packet wants to go from Up to
				// Left or Right-- must check if bus is already used by Turnbacked
				// packets)
				else if (d_u == `LEFT)
					if (d_l != `LEFT)
						sel_l= `UP;
					// If left bus is already used by turnback packet, deflect up
					// packet back up
					else
						sel_u= `UP;
				else if (d_u == `RIGHT)
					if (d_r != `RIGHT)
						sel_r= `UP;
					// If right bus is already used by turnback packet, deflect up
					// packet back up
					else
						sel_u= `UP;
				// Third Priority: `UP/Side Link
				// Left to Right
				if (d_l == `RIGHT)
					// if right bus is not already used by either a turnback packet or
					// a downlink packet, send left packet there
					if (sel_r == `VOID)
						sel_r= `LEFT;
					// otherwise, deflect left packet 
						// If downlink is already using left bus, deflect packet up
					else if (d_u == `LEFT)
						sel_u= `LEFT;
						// Last remaining option is deflection in direction of arrival
						// (must be correct, via deduction)
					else
						sel_l= `LEFT;
				// Left to Up
				else if (d_l == `UP)
					// if up bus is not occupied by turnback packet, send uplink up
					if (sel_u == `VOID)
						sel_u= `LEFT;
					// otherwise, deflect left packet
					// deflect back in direction of arrival if possible
					else if (sel_l == `VOID)
						sel_l= `LEFT;
					// otherwise, deflect to the right
					else
						sel_r= `LEFT;
				// Right to Left
				if (d_r == `LEFT)
					// if left bus is not occupied by turnback packet or downlink
					// paket, send right packet there
					if (sel_l == `VOID)
						sel_l= `RIGHT;
					// otherwise, deflect packet
					else if (sel_r == `VOID)
						sel_r= `RIGHT;
					else
						sel_u= `RIGHT;
				// Right to Up
				else if (d_r == `UP)
					// if up bus is not occupied by turnback packet or other uplink
					// packet, send right uplink packet up
					if (sel_u == `VOID)
						sel_u= `RIGHT;
					// else deflect right packet
					else if (sel_r == `VOID)
						sel_r= `RIGHT;
					// last possible option is to send packet to the left
					else
						sel_l= `RIGHT;
				`ifdef OPTIMIZED
				// Makes exception to when left and right packets swap, up packet gets
				// deflected up
				if (d_l == `RIGHT && d_r == `LEFT && d_u != `VOID) begin
					sel_l= `RIGHT;
					sel_r= `LEFT;
					sel_u= `UP;
				end
				`endif
			end
	endgenerate
endmodule


module t_cluster (
	input clk,
	input reset,
	input [num_switches*p_sz-1:0] l_bus_i,
	input [num_switches*p_sz-1:0] r_bus_i,
	input [num_switches*p_sz-1:0] u_bus_i,
	output [num_switches*p_sz-1:0] l_bus_o,
	output [num_switches*p_sz-1:0] r_bus_o,
	output [num_switches*p_sz-1:0] u_bus_o
	);
	// Override these values in top modules
	parameter num_leaves= 2;
	parameter payload_sz= 1;
	parameter addr= 1'b0;
	//parameter level= $bits(addr); // only change if level == 0
        parameter level= 15;
	parameter p_sz= 1+$clog2(num_leaves)+payload_sz; //packet size
	parameter num_switches= 1;

	genvar i;
	generate
	for (i= 0; i < num_switches; i= i + 1) begin
		t_switch #(
			.num_leaves(num_leaves),
			.payload_sz(payload_sz),
			.addr(addr),
			.level(level),
			.p_sz(p_sz))
			ts (
				.clk(clk),
				.reset(reset),
				.l_bus_i(l_bus_i[i*p_sz+:p_sz]),
				.r_bus_i(r_bus_i[i*p_sz+:p_sz]),
				.u_bus_i(u_bus_i[i*p_sz+:p_sz]),
				.l_bus_o(l_bus_o[i*p_sz+:p_sz]),
				.r_bus_o(r_bus_o[i*p_sz+:p_sz]),
				.u_bus_o(u_bus_o[i*p_sz+:p_sz]));
	end
	endgenerate
endmodule	


module t_switch (
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
	wire [1:0] sel_l;
	wire [1:0] sel_r;
	wire [1:0] sel_u;

	direction_determiner #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level)) 
							dd_l(
							.valid_i(l_bus_i[p_sz-1]),
							.addr_i(l_bus_i[p_sz-2:payload_sz]), 
							.d(d_l));

	direction_determiner #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level)) 
							dd_r(
							.valid_i(r_bus_i[p_sz-1]),
							.addr_i(r_bus_i[p_sz-2:payload_sz]), 
							.d(d_r));

	direction_determiner #(.num_leaves(num_leaves), 
							.addr(addr),
							.level(level))
						   	dd_u(
							.valid_i(u_bus_i[p_sz-1]),
							.addr_i(u_bus_i[p_sz-2:payload_sz]),
							.d(d_u));

						
	t_arbiter #(.level(level))
	t_a(d_l, d_r, d_u, sel_l, sel_r, sel_u);

	always @(posedge clk)
		if (reset)
			{l_bus_o, r_bus_o, u_bus_o} <= 0;
		else begin
			case (sel_l)
				`VOID: l_bus_o<= 0;
				`LEFT: l_bus_o<= l_bus_i;
				`RIGHT: l_bus_o<= r_bus_i;
				`UP: l_bus_o<= u_bus_i;
			endcase
		
			case (sel_r)
				`VOID: r_bus_o<= 0;
				`LEFT: r_bus_o<= l_bus_i;
				`RIGHT: r_bus_o<= r_bus_i;
				`UP: r_bus_o<= u_bus_i;
			endcase
			
			case (sel_u)
				`VOID: u_bus_o <= 0;
				`LEFT: u_bus_o <= l_bus_i;
				`RIGHT: u_bus_o <= r_bus_i;
				`UP: u_bus_o <= u_bus_i;
			endcase
		end
endmodule	



