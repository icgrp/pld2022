// ==============================================================
// RTL generated by Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2021.1 (64-bit)
// Version: 2021.1
// Copyright (C) Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// 
// ===========================================================

`timescale 1 ns / 1 ps 

module data32to512_data32to512_Pipeline_VITIS_LOOP_175_1 (
        ap_clk,
        ap_rst,
        ap_start,
        ap_done,
        ap_idle,
        ap_ready,
        Input_1_V_TVALID,
        Input_1_V_TDATA,
        Input_1_V_TREADY,
        out_tmp_V_1_out,
        out_tmp_V_1_out_ap_vld
);

parameter    ap_ST_fsm_state1 = 1'd1;

input   ap_clk;
input   ap_rst;
input   ap_start;
output   ap_done;
output   ap_idle;
output   ap_ready;
input   Input_1_V_TVALID;
input  [31:0] Input_1_V_TDATA;
output   Input_1_V_TREADY;
output  [511:0] out_tmp_V_1_out;
output   out_tmp_V_1_out_ap_vld;

reg ap_idle;
reg Input_1_V_TREADY;
reg out_tmp_V_1_out_ap_vld;

(* fsm_encoding = "none" *) reg   [0:0] ap_CS_fsm;
wire    ap_CS_fsm_state1;
wire   [0:0] icmp_ln175_fu_77_p2;
reg    ap_block_state1_pp0_stage0_iter0;
reg    ap_condition_exit_pp0_iter0_stage0;
wire    ap_loop_exit_ready;
reg    ap_ready_int;
reg    Input_1_V_TDATA_blk_n;
reg   [511:0] p_Val2_s_fu_48;
wire   [511:0] p_Result_s_fu_236_p2;
reg   [4:0] i_fu_52;
wire    ap_loop_init;
reg   [4:0] ap_sig_allocacmp_i_1;
wire   [4:0] i_2_fu_83_p2;
wire   [3:0] trunc_ln177_fu_92_p1;
wire   [8:0] shl_ln_fu_96_p3;
wire   [8:0] or_ln177_fu_104_p2;
wire   [9:0] zext_ln414_fu_120_p1;
wire   [0:0] icmp_ln414_fu_114_p2;
wire   [9:0] zext_ln414_1_fu_124_p1;
wire   [9:0] xor_ln414_fu_128_p2;
wire   [9:0] select_ln414_fu_134_p3;
wire   [9:0] select_ln414_2_fu_150_p3;
wire   [9:0] select_ln414_1_fu_142_p3;
wire   [9:0] xor_ln414_1_fu_158_p2;
wire   [511:0] zext_ln225_fu_110_p1;
wire   [511:0] zext_ln414_2_fu_164_p1;
wire   [511:0] shl_ln414_fu_176_p2;
reg   [511:0] tmp_fu_182_p4;
wire   [511:0] zext_ln414_3_fu_168_p1;
wire   [511:0] zext_ln414_4_fu_172_p1;
wire   [511:0] shl_ln414_1_fu_200_p2;
wire   [511:0] lshr_ln414_fu_206_p2;
wire   [511:0] and_ln414_fu_212_p2;
wire   [511:0] xor_ln414_2_fu_218_p2;
wire   [511:0] select_ln414_3_fu_192_p3;
wire   [511:0] and_ln414_1_fu_224_p2;
wire   [511:0] and_ln414_2_fu_230_p2;
reg    ap_done_reg;
wire    ap_continue_int;
reg    ap_done_int;
reg   [0:0] ap_NS_fsm;
reg    ap_ST_fsm_state1_blk;
wire    ap_start_int;
reg    ap_condition_199;
wire    ap_ce_reg;

// power-on initialization
initial begin
#0 ap_CS_fsm = 1'd1;
#0 ap_done_reg = 1'b0;
end

data32to512_flow_control_loop_pipe_sequential_init flow_control_loop_pipe_sequential_init_U(
    .ap_clk(ap_clk),
    .ap_rst(ap_rst),
    .ap_start(ap_start),
    .ap_ready(ap_ready),
    .ap_done(ap_done),
    .ap_start_int(ap_start_int),
    .ap_loop_init(ap_loop_init),
    .ap_ready_int(ap_ready_int),
    .ap_loop_exit_ready(ap_condition_exit_pp0_iter0_stage0),
    .ap_loop_exit_done(ap_done_int),
    .ap_continue_int(ap_continue_int),
    .ap_done_int(ap_done_int)
);

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_CS_fsm <= ap_ST_fsm_state1;
    end else begin
        ap_CS_fsm <= ap_NS_fsm;
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_done_reg <= 1'b0;
    end else begin
        if ((ap_continue_int == 1'b1)) begin
            ap_done_reg <= 1'b0;
        end else if ((~((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0))) & (ap_loop_exit_ready == 1'b1) & (1'b1 == ap_CS_fsm_state1))) begin
            ap_done_reg <= 1'b1;
        end
    end
end

always @ (posedge ap_clk) begin
    if ((1'b1 == ap_condition_199)) begin
        if ((icmp_ln175_fu_77_p2 == 1'd0)) begin
            i_fu_52 <= i_2_fu_83_p2;
        end else if ((ap_loop_init == 1'b1)) begin
            i_fu_52 <= 5'd0;
        end
    end
end

always @ (posedge ap_clk) begin
    if ((~((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0))) & (icmp_ln175_fu_77_p2 == 1'd0) & (1'b1 == ap_CS_fsm_state1))) begin
        p_Val2_s_fu_48 <= p_Result_s_fu_236_p2;
    end
end

always @ (*) begin
    if (((icmp_ln175_fu_77_p2 == 1'd0) & (1'b1 == ap_CS_fsm_state1) & (ap_start_int == 1'b1))) begin
        Input_1_V_TDATA_blk_n = Input_1_V_TVALID;
    end else begin
        Input_1_V_TDATA_blk_n = 1'b1;
    end
end

always @ (*) begin
    if ((~((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0))) & (icmp_ln175_fu_77_p2 == 1'd0) & (1'b1 == ap_CS_fsm_state1))) begin
        Input_1_V_TREADY = 1'b1;
    end else begin
        Input_1_V_TREADY = 1'b0;
    end
end

always @ (*) begin
    if (((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0)))) begin
        ap_ST_fsm_state1_blk = 1'b1;
    end else begin
        ap_ST_fsm_state1_blk = 1'b0;
    end
end

always @ (*) begin
    if ((~((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0))) & (icmp_ln175_fu_77_p2 == 1'd1) & (1'b1 == ap_CS_fsm_state1))) begin
        ap_condition_exit_pp0_iter0_stage0 = 1'b1;
    end else begin
        ap_condition_exit_pp0_iter0_stage0 = 1'b0;
    end
end

always @ (*) begin
    if ((~((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0))) & (ap_loop_exit_ready == 1'b1) & (1'b1 == ap_CS_fsm_state1))) begin
        ap_done_int = 1'b1;
    end else begin
        ap_done_int = ap_done_reg;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state1) & (ap_start_int == 1'b0))) begin
        ap_idle = 1'b1;
    end else begin
        ap_idle = 1'b0;
    end
end

always @ (*) begin
    if ((~((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0))) & (1'b1 == ap_CS_fsm_state1))) begin
        ap_ready_int = 1'b1;
    end else begin
        ap_ready_int = 1'b0;
    end
end

always @ (*) begin
    if (((ap_loop_init == 1'b1) & (1'b1 == ap_CS_fsm_state1))) begin
        ap_sig_allocacmp_i_1 = 5'd0;
    end else begin
        ap_sig_allocacmp_i_1 = i_fu_52;
    end
end

always @ (*) begin
    if ((~((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0))) & (icmp_ln175_fu_77_p2 == 1'd1) & (1'b1 == ap_CS_fsm_state1))) begin
        out_tmp_V_1_out_ap_vld = 1'b1;
    end else begin
        out_tmp_V_1_out_ap_vld = 1'b0;
    end
end

always @ (*) begin
    case (ap_CS_fsm)
        ap_ST_fsm_state1 : begin
            ap_NS_fsm = ap_ST_fsm_state1;
        end
        default : begin
            ap_NS_fsm = 'bx;
        end
    endcase
end

assign and_ln414_1_fu_224_p2 = (xor_ln414_2_fu_218_p2 & p_Val2_s_fu_48);

assign and_ln414_2_fu_230_p2 = (select_ln414_3_fu_192_p3 & and_ln414_fu_212_p2);

assign and_ln414_fu_212_p2 = (shl_ln414_1_fu_200_p2 & lshr_ln414_fu_206_p2);

assign ap_CS_fsm_state1 = ap_CS_fsm[32'd0];

always @ (*) begin
    ap_block_state1_pp0_stage0_iter0 = ((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0)));
end

always @ (*) begin
    ap_condition_199 = (~((ap_start_int == 1'b0) | ((1'b0 == Input_1_V_TVALID) & (icmp_ln175_fu_77_p2 == 1'd0))) & (1'b1 == ap_CS_fsm_state1));
end

assign ap_loop_exit_ready = ap_condition_exit_pp0_iter0_stage0;

assign i_2_fu_83_p2 = (ap_sig_allocacmp_i_1 + 5'd1);

assign icmp_ln175_fu_77_p2 = ((ap_sig_allocacmp_i_1 == 5'd16) ? 1'b1 : 1'b0);

assign icmp_ln414_fu_114_p2 = ((shl_ln_fu_96_p3 > or_ln177_fu_104_p2) ? 1'b1 : 1'b0);

assign lshr_ln414_fu_206_p2 = 512'd13407807929942597099574024998205846127479365820592393377723561443721764030073546976801874298166903427690031858186486050853753882811946569946433649006084095 >> zext_ln414_4_fu_172_p1;

assign or_ln177_fu_104_p2 = (shl_ln_fu_96_p3 | 9'd31);

assign out_tmp_V_1_out = p_Val2_s_fu_48;

assign p_Result_s_fu_236_p2 = (and_ln414_2_fu_230_p2 | and_ln414_1_fu_224_p2);

assign select_ln414_1_fu_142_p3 = ((icmp_ln414_fu_114_p2[0:0] == 1'b1) ? zext_ln414_1_fu_124_p1 : zext_ln414_fu_120_p1);

assign select_ln414_2_fu_150_p3 = ((icmp_ln414_fu_114_p2[0:0] == 1'b1) ? xor_ln414_fu_128_p2 : zext_ln414_fu_120_p1);

assign select_ln414_3_fu_192_p3 = ((icmp_ln414_fu_114_p2[0:0] == 1'b1) ? tmp_fu_182_p4 : shl_ln414_fu_176_p2);

assign select_ln414_fu_134_p3 = ((icmp_ln414_fu_114_p2[0:0] == 1'b1) ? zext_ln414_fu_120_p1 : zext_ln414_1_fu_124_p1);

assign shl_ln414_1_fu_200_p2 = 512'd13407807929942597099574024998205846127479365820592393377723561443721764030073546976801874298166903427690031858186486050853753882811946569946433649006084095 << zext_ln414_3_fu_168_p1;

assign shl_ln414_fu_176_p2 = zext_ln225_fu_110_p1 << zext_ln414_2_fu_164_p1;

assign shl_ln_fu_96_p3 = {{trunc_ln177_fu_92_p1}, {5'd0}};

integer ap_tvar_int_0;

always @ (shl_ln414_fu_176_p2) begin
    for (ap_tvar_int_0 = 512 - 1; ap_tvar_int_0 >= 0; ap_tvar_int_0 = ap_tvar_int_0 - 1) begin
        if (ap_tvar_int_0 > 511 - 0) begin
            tmp_fu_182_p4[ap_tvar_int_0] = 1'b0;
        end else begin
            tmp_fu_182_p4[ap_tvar_int_0] = shl_ln414_fu_176_p2[511 - ap_tvar_int_0];
        end
    end
end

assign trunc_ln177_fu_92_p1 = ap_sig_allocacmp_i_1[3:0];

assign xor_ln414_1_fu_158_p2 = (select_ln414_fu_134_p3 ^ 10'd511);

assign xor_ln414_2_fu_218_p2 = (512'd13407807929942597099574024998205846127479365820592393377723561443721764030073546976801874298166903427690031858186486050853753882811946569946433649006084095 ^ and_ln414_fu_212_p2);

assign xor_ln414_fu_128_p2 = (zext_ln414_fu_120_p1 ^ 10'd511);

assign zext_ln225_fu_110_p1 = Input_1_V_TDATA;

assign zext_ln414_1_fu_124_p1 = or_ln177_fu_104_p2;

assign zext_ln414_2_fu_164_p1 = select_ln414_2_fu_150_p3;

assign zext_ln414_3_fu_168_p1 = select_ln414_1_fu_142_p3;

assign zext_ln414_4_fu_172_p1 = xor_ln414_1_fu_158_p2;

assign zext_ln414_fu_120_p1 = shl_ln_fu_96_p3;

endmodule //data32to512_data32to512_Pipeline_VITIS_LOOP_175_1
