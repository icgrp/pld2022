// ==============================================================
// RTL generated by Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2021.1 (64-bit)
// Version: 2021.1
// Copyright (C) Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// 
// ===========================================================

`timescale 1 ns / 1 ps 

module ydma_Loop_VITIS_LOOP_36_4_proc4 (
        ap_clk,
        ap_rst,
        ap_start,
        ap_done,
        ap_continue,
        ap_idle,
        ap_ready,
        p_read,
        v2_buffer_V_dout,
        v2_buffer_V_empty_n,
        v2_buffer_V_read,
        p_read1,
        m_axi_aximm2_AWVALID,
        m_axi_aximm2_AWREADY,
        m_axi_aximm2_AWADDR,
        m_axi_aximm2_AWID,
        m_axi_aximm2_AWLEN,
        m_axi_aximm2_AWSIZE,
        m_axi_aximm2_AWBURST,
        m_axi_aximm2_AWLOCK,
        m_axi_aximm2_AWCACHE,
        m_axi_aximm2_AWPROT,
        m_axi_aximm2_AWQOS,
        m_axi_aximm2_AWREGION,
        m_axi_aximm2_AWUSER,
        m_axi_aximm2_WVALID,
        m_axi_aximm2_WREADY,
        m_axi_aximm2_WDATA,
        m_axi_aximm2_WSTRB,
        m_axi_aximm2_WLAST,
        m_axi_aximm2_WID,
        m_axi_aximm2_WUSER,
        m_axi_aximm2_ARVALID,
        m_axi_aximm2_ARREADY,
        m_axi_aximm2_ARADDR,
        m_axi_aximm2_ARID,
        m_axi_aximm2_ARLEN,
        m_axi_aximm2_ARSIZE,
        m_axi_aximm2_ARBURST,
        m_axi_aximm2_ARLOCK,
        m_axi_aximm2_ARCACHE,
        m_axi_aximm2_ARPROT,
        m_axi_aximm2_ARQOS,
        m_axi_aximm2_ARREGION,
        m_axi_aximm2_ARUSER,
        m_axi_aximm2_RVALID,
        m_axi_aximm2_RREADY,
        m_axi_aximm2_RDATA,
        m_axi_aximm2_RLAST,
        m_axi_aximm2_RID,
        m_axi_aximm2_RUSER,
        m_axi_aximm2_RRESP,
        m_axi_aximm2_BVALID,
        m_axi_aximm2_BREADY,
        m_axi_aximm2_BRESP,
        m_axi_aximm2_BID,
        m_axi_aximm2_BUSER,
        ap_ext_blocking_n,
        ap_str_blocking_n,
        ap_int_blocking_n
);

parameter    ap_ST_fsm_state1 = 70'd1;
parameter    ap_ST_fsm_pp0_stage0 = 70'd2;
parameter    ap_ST_fsm_state5 = 70'd4;
parameter    ap_ST_fsm_state6 = 70'd8;
parameter    ap_ST_fsm_state7 = 70'd16;
parameter    ap_ST_fsm_state8 = 70'd32;
parameter    ap_ST_fsm_state9 = 70'd64;
parameter    ap_ST_fsm_state10 = 70'd128;
parameter    ap_ST_fsm_state11 = 70'd256;
parameter    ap_ST_fsm_state12 = 70'd512;
parameter    ap_ST_fsm_state13 = 70'd1024;
parameter    ap_ST_fsm_state14 = 70'd2048;
parameter    ap_ST_fsm_state15 = 70'd4096;
parameter    ap_ST_fsm_state16 = 70'd8192;
parameter    ap_ST_fsm_state17 = 70'd16384;
parameter    ap_ST_fsm_state18 = 70'd32768;
parameter    ap_ST_fsm_state19 = 70'd65536;
parameter    ap_ST_fsm_state20 = 70'd131072;
parameter    ap_ST_fsm_state21 = 70'd262144;
parameter    ap_ST_fsm_state22 = 70'd524288;
parameter    ap_ST_fsm_state23 = 70'd1048576;
parameter    ap_ST_fsm_state24 = 70'd2097152;
parameter    ap_ST_fsm_state25 = 70'd4194304;
parameter    ap_ST_fsm_state26 = 70'd8388608;
parameter    ap_ST_fsm_state27 = 70'd16777216;
parameter    ap_ST_fsm_state28 = 70'd33554432;
parameter    ap_ST_fsm_state29 = 70'd67108864;
parameter    ap_ST_fsm_state30 = 70'd134217728;
parameter    ap_ST_fsm_state31 = 70'd268435456;
parameter    ap_ST_fsm_state32 = 70'd536870912;
parameter    ap_ST_fsm_state33 = 70'd1073741824;
parameter    ap_ST_fsm_state34 = 70'd2147483648;
parameter    ap_ST_fsm_state35 = 70'd4294967296;
parameter    ap_ST_fsm_state36 = 70'd8589934592;
parameter    ap_ST_fsm_state37 = 70'd17179869184;
parameter    ap_ST_fsm_state38 = 70'd34359738368;
parameter    ap_ST_fsm_state39 = 70'd68719476736;
parameter    ap_ST_fsm_state40 = 70'd137438953472;
parameter    ap_ST_fsm_state41 = 70'd274877906944;
parameter    ap_ST_fsm_state42 = 70'd549755813888;
parameter    ap_ST_fsm_state43 = 70'd1099511627776;
parameter    ap_ST_fsm_state44 = 70'd2199023255552;
parameter    ap_ST_fsm_state45 = 70'd4398046511104;
parameter    ap_ST_fsm_state46 = 70'd8796093022208;
parameter    ap_ST_fsm_state47 = 70'd17592186044416;
parameter    ap_ST_fsm_state48 = 70'd35184372088832;
parameter    ap_ST_fsm_state49 = 70'd70368744177664;
parameter    ap_ST_fsm_state50 = 70'd140737488355328;
parameter    ap_ST_fsm_state51 = 70'd281474976710656;
parameter    ap_ST_fsm_state52 = 70'd562949953421312;
parameter    ap_ST_fsm_state53 = 70'd1125899906842624;
parameter    ap_ST_fsm_state54 = 70'd2251799813685248;
parameter    ap_ST_fsm_state55 = 70'd4503599627370496;
parameter    ap_ST_fsm_state56 = 70'd9007199254740992;
parameter    ap_ST_fsm_state57 = 70'd18014398509481984;
parameter    ap_ST_fsm_state58 = 70'd36028797018963968;
parameter    ap_ST_fsm_state59 = 70'd72057594037927936;
parameter    ap_ST_fsm_state60 = 70'd144115188075855872;
parameter    ap_ST_fsm_state61 = 70'd288230376151711744;
parameter    ap_ST_fsm_state62 = 70'd576460752303423488;
parameter    ap_ST_fsm_state63 = 70'd1152921504606846976;
parameter    ap_ST_fsm_state64 = 70'd2305843009213693952;
parameter    ap_ST_fsm_state65 = 70'd4611686018427387904;
parameter    ap_ST_fsm_state66 = 70'd9223372036854775808;
parameter    ap_ST_fsm_state67 = 70'd18446744073709551616;
parameter    ap_ST_fsm_state68 = 70'd36893488147419103232;
parameter    ap_ST_fsm_state69 = 70'd73786976294838206464;
parameter    ap_ST_fsm_state70 = 70'd147573952589676412928;
parameter    ap_ST_fsm_state71 = 70'd295147905179352825856;
parameter    ap_ST_fsm_state72 = 70'd590295810358705651712;

input   ap_clk;
input   ap_rst;
input   ap_start;
output   ap_done;
input   ap_continue;
output   ap_idle;
output   ap_ready;
input  [31:0] p_read;
input  [511:0] v2_buffer_V_dout;
input   v2_buffer_V_empty_n;
output   v2_buffer_V_read;
input  [63:0] p_read1;
output   m_axi_aximm2_AWVALID;
input   m_axi_aximm2_AWREADY;
output  [63:0] m_axi_aximm2_AWADDR;
output  [0:0] m_axi_aximm2_AWID;
output  [31:0] m_axi_aximm2_AWLEN;
output  [2:0] m_axi_aximm2_AWSIZE;
output  [1:0] m_axi_aximm2_AWBURST;
output  [1:0] m_axi_aximm2_AWLOCK;
output  [3:0] m_axi_aximm2_AWCACHE;
output  [2:0] m_axi_aximm2_AWPROT;
output  [3:0] m_axi_aximm2_AWQOS;
output  [3:0] m_axi_aximm2_AWREGION;
output  [0:0] m_axi_aximm2_AWUSER;
output   m_axi_aximm2_WVALID;
input   m_axi_aximm2_WREADY;
output  [511:0] m_axi_aximm2_WDATA;
output  [63:0] m_axi_aximm2_WSTRB;
output   m_axi_aximm2_WLAST;
output  [0:0] m_axi_aximm2_WID;
output  [0:0] m_axi_aximm2_WUSER;
output   m_axi_aximm2_ARVALID;
input   m_axi_aximm2_ARREADY;
output  [63:0] m_axi_aximm2_ARADDR;
output  [0:0] m_axi_aximm2_ARID;
output  [31:0] m_axi_aximm2_ARLEN;
output  [2:0] m_axi_aximm2_ARSIZE;
output  [1:0] m_axi_aximm2_ARBURST;
output  [1:0] m_axi_aximm2_ARLOCK;
output  [3:0] m_axi_aximm2_ARCACHE;
output  [2:0] m_axi_aximm2_ARPROT;
output  [3:0] m_axi_aximm2_ARQOS;
output  [3:0] m_axi_aximm2_ARREGION;
output  [0:0] m_axi_aximm2_ARUSER;
input   m_axi_aximm2_RVALID;
output   m_axi_aximm2_RREADY;
input  [511:0] m_axi_aximm2_RDATA;
input   m_axi_aximm2_RLAST;
input  [0:0] m_axi_aximm2_RID;
input  [0:0] m_axi_aximm2_RUSER;
input  [1:0] m_axi_aximm2_RRESP;
input   m_axi_aximm2_BVALID;
output   m_axi_aximm2_BREADY;
input  [1:0] m_axi_aximm2_BRESP;
input  [0:0] m_axi_aximm2_BID;
input  [0:0] m_axi_aximm2_BUSER;
output   ap_ext_blocking_n;
output   ap_str_blocking_n;
output   ap_int_blocking_n;

reg ap_done;
reg ap_idle;
reg ap_ready;
reg v2_buffer_V_read;
reg m_axi_aximm2_AWVALID;
reg m_axi_aximm2_WVALID;
reg m_axi_aximm2_BREADY;

reg    ap_done_reg;
(* fsm_encoding = "none" *) reg   [69:0] ap_CS_fsm;
wire    ap_CS_fsm_state1;
reg    v2_buffer_V_blk_n;
wire    ap_CS_fsm_pp0_stage0;
reg    ap_enable_reg_pp0_iter1;
wire    ap_block_pp0_stage0;
reg    aximm2_blk_n_AW;
reg    aximm2_blk_n_B;
wire    ap_CS_fsm_state72;
reg    aximm2_blk_n_W;
reg    ap_enable_reg_pp0_iter2;
reg   [511:0] v2_buffer_V_read_reg_170;
wire    ap_block_state2_pp0_stage0_iter0;
reg    ap_block_state3_pp0_stage0_iter1;
wire    ap_block_state4_pp0_stage0_iter2;
reg    ap_block_pp0_stage0_11001;
reg    ap_enable_reg_pp0_iter0;
reg    ap_block_state1;
reg    ap_block_pp0_stage0_subdone;
wire   [0:0] icmp_ln36_fu_133_p2;
reg    ap_condition_pp0_exit_iter0_state2;
wire  signed [63:0] sext_ln321_fu_110_p1;
reg    ap_block_pp0_stage0_01001;
reg   [30:0] i_fu_62;
wire   [30:0] add_ln36_fu_138_p2;
wire   [57:0] trunc_ln321_1_fu_100_p4;
wire   [31:0] i_3_cast_fu_129_p1;
reg   [69:0] ap_NS_fsm;
reg    ap_ST_fsm_state1_blk;
wire    ap_ST_fsm_state5_blk;
wire    ap_ST_fsm_state6_blk;
wire    ap_ST_fsm_state7_blk;
wire    ap_ST_fsm_state8_blk;
wire    ap_ST_fsm_state9_blk;
wire    ap_ST_fsm_state10_blk;
wire    ap_ST_fsm_state11_blk;
wire    ap_ST_fsm_state12_blk;
wire    ap_ST_fsm_state13_blk;
wire    ap_ST_fsm_state14_blk;
wire    ap_ST_fsm_state15_blk;
wire    ap_ST_fsm_state16_blk;
wire    ap_ST_fsm_state17_blk;
wire    ap_ST_fsm_state18_blk;
wire    ap_ST_fsm_state19_blk;
wire    ap_ST_fsm_state20_blk;
wire    ap_ST_fsm_state21_blk;
wire    ap_ST_fsm_state22_blk;
wire    ap_ST_fsm_state23_blk;
wire    ap_ST_fsm_state24_blk;
wire    ap_ST_fsm_state25_blk;
wire    ap_ST_fsm_state26_blk;
wire    ap_ST_fsm_state27_blk;
wire    ap_ST_fsm_state28_blk;
wire    ap_ST_fsm_state29_blk;
wire    ap_ST_fsm_state30_blk;
wire    ap_ST_fsm_state31_blk;
wire    ap_ST_fsm_state32_blk;
wire    ap_ST_fsm_state33_blk;
wire    ap_ST_fsm_state34_blk;
wire    ap_ST_fsm_state35_blk;
wire    ap_ST_fsm_state36_blk;
wire    ap_ST_fsm_state37_blk;
wire    ap_ST_fsm_state38_blk;
wire    ap_ST_fsm_state39_blk;
wire    ap_ST_fsm_state40_blk;
wire    ap_ST_fsm_state41_blk;
wire    ap_ST_fsm_state42_blk;
wire    ap_ST_fsm_state43_blk;
wire    ap_ST_fsm_state44_blk;
wire    ap_ST_fsm_state45_blk;
wire    ap_ST_fsm_state46_blk;
wire    ap_ST_fsm_state47_blk;
wire    ap_ST_fsm_state48_blk;
wire    ap_ST_fsm_state49_blk;
wire    ap_ST_fsm_state50_blk;
wire    ap_ST_fsm_state51_blk;
wire    ap_ST_fsm_state52_blk;
wire    ap_ST_fsm_state53_blk;
wire    ap_ST_fsm_state54_blk;
wire    ap_ST_fsm_state55_blk;
wire    ap_ST_fsm_state56_blk;
wire    ap_ST_fsm_state57_blk;
wire    ap_ST_fsm_state58_blk;
wire    ap_ST_fsm_state59_blk;
wire    ap_ST_fsm_state60_blk;
wire    ap_ST_fsm_state61_blk;
wire    ap_ST_fsm_state62_blk;
wire    ap_ST_fsm_state63_blk;
wire    ap_ST_fsm_state64_blk;
wire    ap_ST_fsm_state65_blk;
wire    ap_ST_fsm_state66_blk;
wire    ap_ST_fsm_state67_blk;
wire    ap_ST_fsm_state68_blk;
wire    ap_ST_fsm_state69_blk;
wire    ap_ST_fsm_state70_blk;
wire    ap_ST_fsm_state71_blk;
reg    ap_ST_fsm_state72_blk;
wire    ap_ext_blocking_cur_n;
wire    ap_int_blocking_cur_n;
reg    ap_idle_pp0;
wire    ap_enable_pp0;
wire    ap_ce_reg;

// power-on initialization
initial begin
#0 ap_done_reg = 1'b0;
#0 ap_CS_fsm = 70'd1;
#0 ap_enable_reg_pp0_iter1 = 1'b0;
#0 ap_enable_reg_pp0_iter2 = 1'b0;
#0 ap_enable_reg_pp0_iter0 = 1'b0;
end

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
        if ((ap_continue == 1'b1)) begin
            ap_done_reg <= 1'b0;
        end else if (((1'b1 == ap_CS_fsm_state72) & (m_axi_aximm2_BVALID == 1'b1))) begin
            ap_done_reg <= 1'b1;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter0 <= 1'b0;
    end else begin
        if (((1'b1 == ap_condition_pp0_exit_iter0_state2) & (1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0_subdone))) begin
            ap_enable_reg_pp0_iter0 <= 1'b0;
        end else if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0) | (m_axi_aximm2_AWREADY == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
            ap_enable_reg_pp0_iter0 <= 1'b1;
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter1 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            if ((1'b1 == ap_condition_pp0_exit_iter0_state2)) begin
                ap_enable_reg_pp0_iter1 <= (1'b1 ^ ap_condition_pp0_exit_iter0_state2);
            end else if ((1'b1 == 1'b1)) begin
                ap_enable_reg_pp0_iter1 <= ap_enable_reg_pp0_iter0;
            end
        end
    end
end

always @ (posedge ap_clk) begin
    if (ap_rst == 1'b1) begin
        ap_enable_reg_pp0_iter2 <= 1'b0;
    end else begin
        if ((1'b0 == ap_block_pp0_stage0_subdone)) begin
            ap_enable_reg_pp0_iter2 <= ap_enable_reg_pp0_iter1;
        end else if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0) | (m_axi_aximm2_AWREADY == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
            ap_enable_reg_pp0_iter2 <= 1'b0;
        end
    end
end

always @ (posedge ap_clk) begin
    if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0) | (m_axi_aximm2_AWREADY == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
        i_fu_62 <= 31'd0;
    end else if (((icmp_ln36_fu_133_p2 == 1'd1) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        i_fu_62 <= add_ln36_fu_138_p2;
    end
end

always @ (posedge ap_clk) begin
    if (((1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        v2_buffer_V_read_reg_170 <= v2_buffer_V_dout;
    end
end

assign ap_ST_fsm_state10_blk = 1'b0;

assign ap_ST_fsm_state11_blk = 1'b0;

assign ap_ST_fsm_state12_blk = 1'b0;

assign ap_ST_fsm_state13_blk = 1'b0;

assign ap_ST_fsm_state14_blk = 1'b0;

assign ap_ST_fsm_state15_blk = 1'b0;

assign ap_ST_fsm_state16_blk = 1'b0;

assign ap_ST_fsm_state17_blk = 1'b0;

assign ap_ST_fsm_state18_blk = 1'b0;

assign ap_ST_fsm_state19_blk = 1'b0;

always @ (*) begin
    if (((ap_done_reg == 1'b1) | (ap_start == 1'b0) | (m_axi_aximm2_AWREADY == 1'b0))) begin
        ap_ST_fsm_state1_blk = 1'b1;
    end else begin
        ap_ST_fsm_state1_blk = 1'b0;
    end
end

assign ap_ST_fsm_state20_blk = 1'b0;

assign ap_ST_fsm_state21_blk = 1'b0;

assign ap_ST_fsm_state22_blk = 1'b0;

assign ap_ST_fsm_state23_blk = 1'b0;

assign ap_ST_fsm_state24_blk = 1'b0;

assign ap_ST_fsm_state25_blk = 1'b0;

assign ap_ST_fsm_state26_blk = 1'b0;

assign ap_ST_fsm_state27_blk = 1'b0;

assign ap_ST_fsm_state28_blk = 1'b0;

assign ap_ST_fsm_state29_blk = 1'b0;

assign ap_ST_fsm_state30_blk = 1'b0;

assign ap_ST_fsm_state31_blk = 1'b0;

assign ap_ST_fsm_state32_blk = 1'b0;

assign ap_ST_fsm_state33_blk = 1'b0;

assign ap_ST_fsm_state34_blk = 1'b0;

assign ap_ST_fsm_state35_blk = 1'b0;

assign ap_ST_fsm_state36_blk = 1'b0;

assign ap_ST_fsm_state37_blk = 1'b0;

assign ap_ST_fsm_state38_blk = 1'b0;

assign ap_ST_fsm_state39_blk = 1'b0;

assign ap_ST_fsm_state40_blk = 1'b0;

assign ap_ST_fsm_state41_blk = 1'b0;

assign ap_ST_fsm_state42_blk = 1'b0;

assign ap_ST_fsm_state43_blk = 1'b0;

assign ap_ST_fsm_state44_blk = 1'b0;

assign ap_ST_fsm_state45_blk = 1'b0;

assign ap_ST_fsm_state46_blk = 1'b0;

assign ap_ST_fsm_state47_blk = 1'b0;

assign ap_ST_fsm_state48_blk = 1'b0;

assign ap_ST_fsm_state49_blk = 1'b0;

assign ap_ST_fsm_state50_blk = 1'b0;

assign ap_ST_fsm_state51_blk = 1'b0;

assign ap_ST_fsm_state52_blk = 1'b0;

assign ap_ST_fsm_state53_blk = 1'b0;

assign ap_ST_fsm_state54_blk = 1'b0;

assign ap_ST_fsm_state55_blk = 1'b0;

assign ap_ST_fsm_state56_blk = 1'b0;

assign ap_ST_fsm_state57_blk = 1'b0;

assign ap_ST_fsm_state58_blk = 1'b0;

assign ap_ST_fsm_state59_blk = 1'b0;

assign ap_ST_fsm_state5_blk = 1'b0;

assign ap_ST_fsm_state60_blk = 1'b0;

assign ap_ST_fsm_state61_blk = 1'b0;

assign ap_ST_fsm_state62_blk = 1'b0;

assign ap_ST_fsm_state63_blk = 1'b0;

assign ap_ST_fsm_state64_blk = 1'b0;

assign ap_ST_fsm_state65_blk = 1'b0;

assign ap_ST_fsm_state66_blk = 1'b0;

assign ap_ST_fsm_state67_blk = 1'b0;

assign ap_ST_fsm_state68_blk = 1'b0;

assign ap_ST_fsm_state69_blk = 1'b0;

assign ap_ST_fsm_state6_blk = 1'b0;

assign ap_ST_fsm_state70_blk = 1'b0;

assign ap_ST_fsm_state71_blk = 1'b0;

always @ (*) begin
    if ((m_axi_aximm2_BVALID == 1'b0)) begin
        ap_ST_fsm_state72_blk = 1'b1;
    end else begin
        ap_ST_fsm_state72_blk = 1'b0;
    end
end

assign ap_ST_fsm_state7_blk = 1'b0;

assign ap_ST_fsm_state8_blk = 1'b0;

assign ap_ST_fsm_state9_blk = 1'b0;

always @ (*) begin
    if ((icmp_ln36_fu_133_p2 == 1'd0)) begin
        ap_condition_pp0_exit_iter0_state2 = 1'b1;
    end else begin
        ap_condition_pp0_exit_iter0_state2 = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state72) & (m_axi_aximm2_BVALID == 1'b1))) begin
        ap_done = 1'b1;
    end else begin
        ap_done = ap_done_reg;
    end
end

always @ (*) begin
    if (((ap_start == 1'b0) & (1'b1 == ap_CS_fsm_state1))) begin
        ap_idle = 1'b1;
    end else begin
        ap_idle = 1'b0;
    end
end

always @ (*) begin
    if (((ap_enable_reg_pp0_iter0 == 1'b0) & (ap_enable_reg_pp0_iter2 == 1'b0) & (ap_enable_reg_pp0_iter1 == 1'b0))) begin
        ap_idle_pp0 = 1'b1;
    end else begin
        ap_idle_pp0 = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state72) & (m_axi_aximm2_BVALID == 1'b1))) begin
        ap_ready = 1'b1;
    end else begin
        ap_ready = 1'b0;
    end
end

always @ (*) begin
    if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
        aximm2_blk_n_AW = m_axi_aximm2_AWREADY;
    end else begin
        aximm2_blk_n_AW = 1'b1;
    end
end

always @ (*) begin
    if ((1'b1 == ap_CS_fsm_state72)) begin
        aximm2_blk_n_B = m_axi_aximm2_BVALID;
    end else begin
        aximm2_blk_n_B = 1'b1;
    end
end

always @ (*) begin
    if (((ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0))) begin
        aximm2_blk_n_W = m_axi_aximm2_WREADY;
    end else begin
        aximm2_blk_n_W = 1'b1;
    end
end

always @ (*) begin
    if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0) | (m_axi_aximm2_AWREADY == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
        m_axi_aximm2_AWVALID = 1'b1;
    end else begin
        m_axi_aximm2_AWVALID = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_state72) & (m_axi_aximm2_BVALID == 1'b1))) begin
        m_axi_aximm2_BREADY = 1'b1;
    end else begin
        m_axi_aximm2_BREADY = 1'b0;
    end
end

always @ (*) begin
    if (((ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0_11001))) begin
        m_axi_aximm2_WVALID = 1'b1;
    end else begin
        m_axi_aximm2_WVALID = 1'b0;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0) & (ap_enable_reg_pp0_iter1 == 1'b1))) begin
        v2_buffer_V_blk_n = v2_buffer_V_empty_n;
    end else begin
        v2_buffer_V_blk_n = 1'b1;
    end
end

always @ (*) begin
    if (((1'b1 == ap_CS_fsm_pp0_stage0) & (1'b0 == ap_block_pp0_stage0_11001) & (ap_enable_reg_pp0_iter1 == 1'b1))) begin
        v2_buffer_V_read = 1'b1;
    end else begin
        v2_buffer_V_read = 1'b0;
    end
end

always @ (*) begin
    case (ap_CS_fsm)
        ap_ST_fsm_state1 : begin
            if ((~((ap_done_reg == 1'b1) | (ap_start == 1'b0) | (m_axi_aximm2_AWREADY == 1'b0)) & (1'b1 == ap_CS_fsm_state1))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state1;
            end
        end
        ap_ST_fsm_pp0_stage0 : begin
            if ((~((icmp_ln36_fu_133_p2 == 1'd0) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)) & ~((ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)))) begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end else if ((((icmp_ln36_fu_133_p2 == 1'd0) & (ap_enable_reg_pp0_iter0 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)) | ((ap_enable_reg_pp0_iter2 == 1'b1) & (1'b0 == ap_block_pp0_stage0_subdone) & (ap_enable_reg_pp0_iter1 == 1'b0)))) begin
                ap_NS_fsm = ap_ST_fsm_state5;
            end else begin
                ap_NS_fsm = ap_ST_fsm_pp0_stage0;
            end
        end
        ap_ST_fsm_state5 : begin
            ap_NS_fsm = ap_ST_fsm_state6;
        end
        ap_ST_fsm_state6 : begin
            ap_NS_fsm = ap_ST_fsm_state7;
        end
        ap_ST_fsm_state7 : begin
            ap_NS_fsm = ap_ST_fsm_state8;
        end
        ap_ST_fsm_state8 : begin
            ap_NS_fsm = ap_ST_fsm_state9;
        end
        ap_ST_fsm_state9 : begin
            ap_NS_fsm = ap_ST_fsm_state10;
        end
        ap_ST_fsm_state10 : begin
            ap_NS_fsm = ap_ST_fsm_state11;
        end
        ap_ST_fsm_state11 : begin
            ap_NS_fsm = ap_ST_fsm_state12;
        end
        ap_ST_fsm_state12 : begin
            ap_NS_fsm = ap_ST_fsm_state13;
        end
        ap_ST_fsm_state13 : begin
            ap_NS_fsm = ap_ST_fsm_state14;
        end
        ap_ST_fsm_state14 : begin
            ap_NS_fsm = ap_ST_fsm_state15;
        end
        ap_ST_fsm_state15 : begin
            ap_NS_fsm = ap_ST_fsm_state16;
        end
        ap_ST_fsm_state16 : begin
            ap_NS_fsm = ap_ST_fsm_state17;
        end
        ap_ST_fsm_state17 : begin
            ap_NS_fsm = ap_ST_fsm_state18;
        end
        ap_ST_fsm_state18 : begin
            ap_NS_fsm = ap_ST_fsm_state19;
        end
        ap_ST_fsm_state19 : begin
            ap_NS_fsm = ap_ST_fsm_state20;
        end
        ap_ST_fsm_state20 : begin
            ap_NS_fsm = ap_ST_fsm_state21;
        end
        ap_ST_fsm_state21 : begin
            ap_NS_fsm = ap_ST_fsm_state22;
        end
        ap_ST_fsm_state22 : begin
            ap_NS_fsm = ap_ST_fsm_state23;
        end
        ap_ST_fsm_state23 : begin
            ap_NS_fsm = ap_ST_fsm_state24;
        end
        ap_ST_fsm_state24 : begin
            ap_NS_fsm = ap_ST_fsm_state25;
        end
        ap_ST_fsm_state25 : begin
            ap_NS_fsm = ap_ST_fsm_state26;
        end
        ap_ST_fsm_state26 : begin
            ap_NS_fsm = ap_ST_fsm_state27;
        end
        ap_ST_fsm_state27 : begin
            ap_NS_fsm = ap_ST_fsm_state28;
        end
        ap_ST_fsm_state28 : begin
            ap_NS_fsm = ap_ST_fsm_state29;
        end
        ap_ST_fsm_state29 : begin
            ap_NS_fsm = ap_ST_fsm_state30;
        end
        ap_ST_fsm_state30 : begin
            ap_NS_fsm = ap_ST_fsm_state31;
        end
        ap_ST_fsm_state31 : begin
            ap_NS_fsm = ap_ST_fsm_state32;
        end
        ap_ST_fsm_state32 : begin
            ap_NS_fsm = ap_ST_fsm_state33;
        end
        ap_ST_fsm_state33 : begin
            ap_NS_fsm = ap_ST_fsm_state34;
        end
        ap_ST_fsm_state34 : begin
            ap_NS_fsm = ap_ST_fsm_state35;
        end
        ap_ST_fsm_state35 : begin
            ap_NS_fsm = ap_ST_fsm_state36;
        end
        ap_ST_fsm_state36 : begin
            ap_NS_fsm = ap_ST_fsm_state37;
        end
        ap_ST_fsm_state37 : begin
            ap_NS_fsm = ap_ST_fsm_state38;
        end
        ap_ST_fsm_state38 : begin
            ap_NS_fsm = ap_ST_fsm_state39;
        end
        ap_ST_fsm_state39 : begin
            ap_NS_fsm = ap_ST_fsm_state40;
        end
        ap_ST_fsm_state40 : begin
            ap_NS_fsm = ap_ST_fsm_state41;
        end
        ap_ST_fsm_state41 : begin
            ap_NS_fsm = ap_ST_fsm_state42;
        end
        ap_ST_fsm_state42 : begin
            ap_NS_fsm = ap_ST_fsm_state43;
        end
        ap_ST_fsm_state43 : begin
            ap_NS_fsm = ap_ST_fsm_state44;
        end
        ap_ST_fsm_state44 : begin
            ap_NS_fsm = ap_ST_fsm_state45;
        end
        ap_ST_fsm_state45 : begin
            ap_NS_fsm = ap_ST_fsm_state46;
        end
        ap_ST_fsm_state46 : begin
            ap_NS_fsm = ap_ST_fsm_state47;
        end
        ap_ST_fsm_state47 : begin
            ap_NS_fsm = ap_ST_fsm_state48;
        end
        ap_ST_fsm_state48 : begin
            ap_NS_fsm = ap_ST_fsm_state49;
        end
        ap_ST_fsm_state49 : begin
            ap_NS_fsm = ap_ST_fsm_state50;
        end
        ap_ST_fsm_state50 : begin
            ap_NS_fsm = ap_ST_fsm_state51;
        end
        ap_ST_fsm_state51 : begin
            ap_NS_fsm = ap_ST_fsm_state52;
        end
        ap_ST_fsm_state52 : begin
            ap_NS_fsm = ap_ST_fsm_state53;
        end
        ap_ST_fsm_state53 : begin
            ap_NS_fsm = ap_ST_fsm_state54;
        end
        ap_ST_fsm_state54 : begin
            ap_NS_fsm = ap_ST_fsm_state55;
        end
        ap_ST_fsm_state55 : begin
            ap_NS_fsm = ap_ST_fsm_state56;
        end
        ap_ST_fsm_state56 : begin
            ap_NS_fsm = ap_ST_fsm_state57;
        end
        ap_ST_fsm_state57 : begin
            ap_NS_fsm = ap_ST_fsm_state58;
        end
        ap_ST_fsm_state58 : begin
            ap_NS_fsm = ap_ST_fsm_state59;
        end
        ap_ST_fsm_state59 : begin
            ap_NS_fsm = ap_ST_fsm_state60;
        end
        ap_ST_fsm_state60 : begin
            ap_NS_fsm = ap_ST_fsm_state61;
        end
        ap_ST_fsm_state61 : begin
            ap_NS_fsm = ap_ST_fsm_state62;
        end
        ap_ST_fsm_state62 : begin
            ap_NS_fsm = ap_ST_fsm_state63;
        end
        ap_ST_fsm_state63 : begin
            ap_NS_fsm = ap_ST_fsm_state64;
        end
        ap_ST_fsm_state64 : begin
            ap_NS_fsm = ap_ST_fsm_state65;
        end
        ap_ST_fsm_state65 : begin
            ap_NS_fsm = ap_ST_fsm_state66;
        end
        ap_ST_fsm_state66 : begin
            ap_NS_fsm = ap_ST_fsm_state67;
        end
        ap_ST_fsm_state67 : begin
            ap_NS_fsm = ap_ST_fsm_state68;
        end
        ap_ST_fsm_state68 : begin
            ap_NS_fsm = ap_ST_fsm_state69;
        end
        ap_ST_fsm_state69 : begin
            ap_NS_fsm = ap_ST_fsm_state70;
        end
        ap_ST_fsm_state70 : begin
            ap_NS_fsm = ap_ST_fsm_state71;
        end
        ap_ST_fsm_state71 : begin
            ap_NS_fsm = ap_ST_fsm_state72;
        end
        ap_ST_fsm_state72 : begin
            if (((1'b1 == ap_CS_fsm_state72) & (m_axi_aximm2_BVALID == 1'b1))) begin
                ap_NS_fsm = ap_ST_fsm_state1;
            end else begin
                ap_NS_fsm = ap_ST_fsm_state72;
            end
        end
        default : begin
            ap_NS_fsm = 'bx;
        end
    endcase
end

assign add_ln36_fu_138_p2 = (i_fu_62 + 31'd1);

assign ap_CS_fsm_pp0_stage0 = ap_CS_fsm[32'd1];

assign ap_CS_fsm_state1 = ap_CS_fsm[32'd0];

assign ap_CS_fsm_state72 = ap_CS_fsm[32'd69];

assign ap_block_pp0_stage0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_pp0_stage0_01001 = ((v2_buffer_V_empty_n == 1'b0) & (ap_enable_reg_pp0_iter1 == 1'b1));
end

always @ (*) begin
    ap_block_pp0_stage0_11001 = (((v2_buffer_V_empty_n == 1'b0) & (ap_enable_reg_pp0_iter1 == 1'b1)) | ((ap_enable_reg_pp0_iter2 == 1'b1) & (m_axi_aximm2_WREADY == 1'b0)));
end

always @ (*) begin
    ap_block_pp0_stage0_subdone = (((v2_buffer_V_empty_n == 1'b0) & (ap_enable_reg_pp0_iter1 == 1'b1)) | ((ap_enable_reg_pp0_iter2 == 1'b1) & (m_axi_aximm2_WREADY == 1'b0)));
end

always @ (*) begin
    ap_block_state1 = ((ap_done_reg == 1'b1) | (ap_start == 1'b0));
end

assign ap_block_state2_pp0_stage0_iter0 = ~(1'b1 == 1'b1);

always @ (*) begin
    ap_block_state3_pp0_stage0_iter1 = (v2_buffer_V_empty_n == 1'b0);
end

assign ap_block_state4_pp0_stage0_iter2 = ~(1'b1 == 1'b1);

assign ap_enable_pp0 = (ap_idle_pp0 ^ 1'b1);

assign ap_ext_blocking_cur_n = (aximm2_blk_n_W & aximm2_blk_n_B & aximm2_blk_n_AW);

assign ap_ext_blocking_n = (ap_ext_blocking_cur_n & 1'b1);

assign ap_int_blocking_cur_n = v2_buffer_V_blk_n;

assign ap_int_blocking_n = (ap_int_blocking_cur_n & 1'b1);

assign ap_str_blocking_n = (1'b1 & 1'b1);

assign i_3_cast_fu_129_p1 = i_fu_62;

assign icmp_ln36_fu_133_p2 = (($signed(i_3_cast_fu_129_p1) < $signed(p_read)) ? 1'b1 : 1'b0);

assign m_axi_aximm2_ARADDR = 64'd0;

assign m_axi_aximm2_ARBURST = 2'd0;

assign m_axi_aximm2_ARCACHE = 4'd0;

assign m_axi_aximm2_ARID = 1'd0;

assign m_axi_aximm2_ARLEN = 32'd0;

assign m_axi_aximm2_ARLOCK = 2'd0;

assign m_axi_aximm2_ARPROT = 3'd0;

assign m_axi_aximm2_ARQOS = 4'd0;

assign m_axi_aximm2_ARREGION = 4'd0;

assign m_axi_aximm2_ARSIZE = 3'd0;

assign m_axi_aximm2_ARUSER = 1'd0;

assign m_axi_aximm2_ARVALID = 1'b0;

assign m_axi_aximm2_AWADDR = sext_ln321_fu_110_p1;

assign m_axi_aximm2_AWBURST = 2'd0;

assign m_axi_aximm2_AWCACHE = 4'd0;

assign m_axi_aximm2_AWID = 1'd0;

assign m_axi_aximm2_AWLEN = p_read;

assign m_axi_aximm2_AWLOCK = 2'd0;

assign m_axi_aximm2_AWPROT = 3'd0;

assign m_axi_aximm2_AWQOS = 4'd0;

assign m_axi_aximm2_AWREGION = 4'd0;

assign m_axi_aximm2_AWSIZE = 3'd0;

assign m_axi_aximm2_AWUSER = 1'd0;

assign m_axi_aximm2_RREADY = 1'b0;

assign m_axi_aximm2_WDATA = v2_buffer_V_read_reg_170;

assign m_axi_aximm2_WID = 1'd0;

assign m_axi_aximm2_WLAST = 1'b0;

assign m_axi_aximm2_WSTRB = 64'd18446744073709551615;

assign m_axi_aximm2_WUSER = 1'd0;

assign sext_ln321_fu_110_p1 = $signed(trunc_ln321_1_fu_100_p4);

assign trunc_ln321_1_fu_100_p4 = {{p_read1[63:6]}};

endmodule //ydma_Loop_VITIS_LOOP_36_4_proc4
