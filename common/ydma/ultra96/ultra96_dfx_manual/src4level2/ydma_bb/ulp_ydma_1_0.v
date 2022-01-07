// (c) Copyright 1995-2021 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:hls:ydma:1.0
// IP Revision: 2108022250

(* X_CORE_INFO = "ydma,Vivado 2021.1" *)
(* CHECK_LICENSE_TYPE = "ulp_ydma_1_0,ydma,{}" *)
(* CORE_GENERATION_INFO = "ulp_ydma_1_0,ydma,{x_ipProduct=Vivado 2021.1,x_ipVendor=xilinx.com,x_ipLibrary=hls,x_ipName=ydma,x_ipVersion=1.0,x_ipCoreRevision=2108022250,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_S_AXI_CONTROL_ADDR_WIDTH=7,C_S_AXI_CONTROL_DATA_WIDTH=32,C_M_AXI_AXIMM1_ID_WIDTH=1,C_M_AXI_AXIMM1_ADDR_WIDTH=64,C_M_AXI_AXIMM1_DATA_WIDTH=64,C_M_AXI_AXIMM1_AWUSER_WIDTH=1,C_M_AXI_AXIMM1_ARUSER_WIDTH=1,C_M_AXI_AXIMM1_WUSER_WIDTH=1,C_M_AXI_AXIMM1_RUSER_WIDTH=1,C_M_AXI_AXIMM1_BUSER_WIDTH=1,C_M_AXI_AXIMM1_USER_VALUE=\
0x00000000,C_M_AXI_AXIMM1_PROT_VALUE=000,C_M_AXI_AXIMM1_CACHE_VALUE=0011,C_M_AXI_AXIMM2_ID_WIDTH=1,C_M_AXI_AXIMM2_ADDR_WIDTH=64,C_M_AXI_AXIMM2_DATA_WIDTH=512,C_M_AXI_AXIMM2_AWUSER_WIDTH=1,C_M_AXI_AXIMM2_ARUSER_WIDTH=1,C_M_AXI_AXIMM2_WUSER_WIDTH=1,C_M_AXI_AXIMM2_RUSER_WIDTH=1,C_M_AXI_AXIMM2_BUSER_WIDTH=1,C_M_AXI_AXIMM2_USER_VALUE=0x00000000,C_M_AXI_AXIMM2_PROT_VALUE=000,C_M_AXI_AXIMM2_CACHE_VALUE=0011}" *)
(* IP_DEFINITION_SOURCE = "HLS" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module ulp_ydma_1_0 (
  stall_start_ext,
  stall_done_ext,
  stall_start_str,
  stall_done_str,
  stall_start_int,
  stall_done_int,
  s_axi_control_AWADDR,
  s_axi_control_AWVALID,
  s_axi_control_AWREADY,
  s_axi_control_WDATA,
  s_axi_control_WSTRB,
  s_axi_control_WVALID,
  s_axi_control_WREADY,
  s_axi_control_BRESP,
  s_axi_control_BVALID,
  s_axi_control_BREADY,
  s_axi_control_ARADDR,
  s_axi_control_ARVALID,
  s_axi_control_ARREADY,
  s_axi_control_RDATA,
  s_axi_control_RRESP,
  s_axi_control_RVALID,
  s_axi_control_RREADY,
  ap_clk,
  ap_rst_n,
  event_done,
  interrupt,
  event_start,
  m_axi_aximm1_AWADDR,
  m_axi_aximm1_AWLEN,
  m_axi_aximm1_AWSIZE,
  m_axi_aximm1_AWBURST,
  m_axi_aximm1_AWLOCK,
  m_axi_aximm1_AWREGION,
  m_axi_aximm1_AWCACHE,
  m_axi_aximm1_AWPROT,
  m_axi_aximm1_AWQOS,
  m_axi_aximm1_AWVALID,
  m_axi_aximm1_AWREADY,
  m_axi_aximm1_WDATA,
  m_axi_aximm1_WSTRB,
  m_axi_aximm1_WLAST,
  m_axi_aximm1_WVALID,
  m_axi_aximm1_WREADY,
  m_axi_aximm1_BRESP,
  m_axi_aximm1_BVALID,
  m_axi_aximm1_BREADY,
  m_axi_aximm1_ARADDR,
  m_axi_aximm1_ARLEN,
  m_axi_aximm1_ARSIZE,
  m_axi_aximm1_ARBURST,
  m_axi_aximm1_ARLOCK,
  m_axi_aximm1_ARREGION,
  m_axi_aximm1_ARCACHE,
  m_axi_aximm1_ARPROT,
  m_axi_aximm1_ARQOS,
  m_axi_aximm1_ARVALID,
  m_axi_aximm1_ARREADY,
  m_axi_aximm1_RDATA,
  m_axi_aximm1_RRESP,
  m_axi_aximm1_RLAST,
  m_axi_aximm1_RVALID,
  m_axi_aximm1_RREADY,
  m_axi_aximm2_AWADDR,
  m_axi_aximm2_AWLEN,
  m_axi_aximm2_AWSIZE,
  m_axi_aximm2_AWBURST,
  m_axi_aximm2_AWLOCK,
  m_axi_aximm2_AWREGION,
  m_axi_aximm2_AWCACHE,
  m_axi_aximm2_AWPROT,
  m_axi_aximm2_AWQOS,
  m_axi_aximm2_AWVALID,
  m_axi_aximm2_AWREADY,
  m_axi_aximm2_WDATA,
  m_axi_aximm2_WSTRB,
  m_axi_aximm2_WLAST,
  m_axi_aximm2_WVALID,
  m_axi_aximm2_WREADY,
  m_axi_aximm2_BRESP,
  m_axi_aximm2_BVALID,
  m_axi_aximm2_BREADY,
  m_axi_aximm2_ARADDR,
  m_axi_aximm2_ARLEN,
  m_axi_aximm2_ARSIZE,
  m_axi_aximm2_ARBURST,
  m_axi_aximm2_ARLOCK,
  m_axi_aximm2_ARREGION,
  m_axi_aximm2_ARCACHE,
  m_axi_aximm2_ARPROT,
  m_axi_aximm2_ARQOS,
  m_axi_aximm2_ARVALID,
  m_axi_aximm2_ARREADY,
  m_axi_aximm2_RDATA,
  m_axi_aximm2_RRESP,
  m_axi_aximm2_RLAST,
  m_axi_aximm2_RVALID,
  m_axi_aximm2_RREADY
);

output wire stall_start_ext;
output wire stall_done_ext;
output wire stall_start_str;
output wire stall_done_str;
output wire stall_start_int;
output wire stall_done_int;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control AWADDR" *)
input wire [6 : 0] s_axi_control_AWADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control AWVALID" *)
input wire s_axi_control_AWVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control AWREADY" *)
output wire s_axi_control_AWREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control WDATA" *)
input wire [31 : 0] s_axi_control_WDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control WSTRB" *)
input wire [3 : 0] s_axi_control_WSTRB;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control WVALID" *)
input wire s_axi_control_WVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control WREADY" *)
output wire s_axi_control_WREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control BRESP" *)
output wire [1 : 0] s_axi_control_BRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control BVALID" *)
output wire s_axi_control_BVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control BREADY" *)
input wire s_axi_control_BREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control ARADDR" *)
input wire [6 : 0] s_axi_control_ARADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control ARVALID" *)
input wire s_axi_control_ARVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control ARREADY" *)
output wire s_axi_control_ARREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control RDATA" *)
output wire [31 : 0] s_axi_control_RDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control RRESP" *)
output wire [1 : 0] s_axi_control_RRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control RVALID" *)
output wire s_axi_control_RVALID;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_control, ADDR_WIDTH 7, DATA_WIDTH 32, PROTOCOL AXI4LITE, READ_WRITE_MODE READ_WRITE, FREQ_HZ 300000000, ID_WIDTH 0, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 0, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.000, CLK_DOMAIN ulp_clk_kernel_in, NUM_READ_THREADS 1, NUM_WRITE_TH\
READS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_control RREADY" *)
input wire s_axi_control_RREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ap_clk, ASSOCIATED_BUSIF s_axi_control:m_axi_aximm1:m_axi_aximm2, ASSOCIATED_RESET ap_rst_n, FREQ_HZ 300000000, FREQ_TOLERANCE_HZ 0, PHASE 0.000, CLK_DOMAIN ulp_clk_kernel_in, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
input wire ap_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ap_rst_n, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ap_rst_n RST" *)
input wire ap_rst_n;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME event_done, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 event_done DATA" *)
output wire event_done;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME interrupt, SENSITIVITY LEVEL_HIGH, PortWidth 1" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt INTERRUPT" *)
output wire interrupt;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME event_start, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 event_start DATA" *)
output wire event_start;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWADDR" *)
output wire [63 : 0] m_axi_aximm1_AWADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWLEN" *)
output wire [7 : 0] m_axi_aximm1_AWLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWSIZE" *)
output wire [2 : 0] m_axi_aximm1_AWSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWBURST" *)
output wire [1 : 0] m_axi_aximm1_AWBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWLOCK" *)
output wire [1 : 0] m_axi_aximm1_AWLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWREGION" *)
output wire [3 : 0] m_axi_aximm1_AWREGION;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWCACHE" *)
output wire [3 : 0] m_axi_aximm1_AWCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWPROT" *)
output wire [2 : 0] m_axi_aximm1_AWPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWQOS" *)
output wire [3 : 0] m_axi_aximm1_AWQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWVALID" *)
output wire m_axi_aximm1_AWVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 AWREADY" *)
input wire m_axi_aximm1_AWREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 WDATA" *)
output wire [63 : 0] m_axi_aximm1_WDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 WSTRB" *)
output wire [7 : 0] m_axi_aximm1_WSTRB;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 WLAST" *)
output wire m_axi_aximm1_WLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 WVALID" *)
output wire m_axi_aximm1_WVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 WREADY" *)
input wire m_axi_aximm1_WREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 BRESP" *)
input wire [1 : 0] m_axi_aximm1_BRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 BVALID" *)
input wire m_axi_aximm1_BVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 BREADY" *)
output wire m_axi_aximm1_BREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARADDR" *)
output wire [63 : 0] m_axi_aximm1_ARADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARLEN" *)
output wire [7 : 0] m_axi_aximm1_ARLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARSIZE" *)
output wire [2 : 0] m_axi_aximm1_ARSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARBURST" *)
output wire [1 : 0] m_axi_aximm1_ARBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARLOCK" *)
output wire [1 : 0] m_axi_aximm1_ARLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARREGION" *)
output wire [3 : 0] m_axi_aximm1_ARREGION;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARCACHE" *)
output wire [3 : 0] m_axi_aximm1_ARCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARPROT" *)
output wire [2 : 0] m_axi_aximm1_ARPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARQOS" *)
output wire [3 : 0] m_axi_aximm1_ARQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARVALID" *)
output wire m_axi_aximm1_ARVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 ARREADY" *)
input wire m_axi_aximm1_ARREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 RDATA" *)
input wire [63 : 0] m_axi_aximm1_RDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 RRESP" *)
input wire [1 : 0] m_axi_aximm1_RRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 RLAST" *)
input wire m_axi_aximm1_RLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 RVALID" *)
input wire m_axi_aximm1_RVALID;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_aximm1, ADDR_WIDTH 64, MAX_BURST_LENGTH 256, NUM_READ_OUTSTANDING 16, NUM_WRITE_OUTSTANDING 16, MAX_READ_BURST_LENGTH 16, MAX_WRITE_BURST_LENGTH 16, PROTOCOL AXI4, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 64, FREQ_HZ 300000000, ID_WIDTH 0, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 1, HAS_REGION 1, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, PHASE 0.000, CLK_DOMAI\
N ulp_clk_kernel_in, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm1 RREADY" *)
output wire m_axi_aximm1_RREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWADDR" *)
output wire [63 : 0] m_axi_aximm2_AWADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWLEN" *)
output wire [7 : 0] m_axi_aximm2_AWLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWSIZE" *)
output wire [2 : 0] m_axi_aximm2_AWSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWBURST" *)
output wire [1 : 0] m_axi_aximm2_AWBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWLOCK" *)
output wire [1 : 0] m_axi_aximm2_AWLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWREGION" *)
output wire [3 : 0] m_axi_aximm2_AWREGION;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWCACHE" *)
output wire [3 : 0] m_axi_aximm2_AWCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWPROT" *)
output wire [2 : 0] m_axi_aximm2_AWPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWQOS" *)
output wire [3 : 0] m_axi_aximm2_AWQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWVALID" *)
output wire m_axi_aximm2_AWVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 AWREADY" *)
input wire m_axi_aximm2_AWREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 WDATA" *)
output wire [511 : 0] m_axi_aximm2_WDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 WSTRB" *)
output wire [63 : 0] m_axi_aximm2_WSTRB;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 WLAST" *)
output wire m_axi_aximm2_WLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 WVALID" *)
output wire m_axi_aximm2_WVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 WREADY" *)
input wire m_axi_aximm2_WREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 BRESP" *)
input wire [1 : 0] m_axi_aximm2_BRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 BVALID" *)
input wire m_axi_aximm2_BVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 BREADY" *)
output wire m_axi_aximm2_BREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARADDR" *)
output wire [63 : 0] m_axi_aximm2_ARADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARLEN" *)
output wire [7 : 0] m_axi_aximm2_ARLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARSIZE" *)
output wire [2 : 0] m_axi_aximm2_ARSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARBURST" *)
output wire [1 : 0] m_axi_aximm2_ARBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARLOCK" *)
output wire [1 : 0] m_axi_aximm2_ARLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARREGION" *)
output wire [3 : 0] m_axi_aximm2_ARREGION;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARCACHE" *)
output wire [3 : 0] m_axi_aximm2_ARCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARPROT" *)
output wire [2 : 0] m_axi_aximm2_ARPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARQOS" *)
output wire [3 : 0] m_axi_aximm2_ARQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARVALID" *)
output wire m_axi_aximm2_ARVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 ARREADY" *)
input wire m_axi_aximm2_ARREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 RDATA" *)
input wire [511 : 0] m_axi_aximm2_RDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 RRESP" *)
input wire [1 : 0] m_axi_aximm2_RRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 RLAST" *)
input wire m_axi_aximm2_RLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 RVALID" *)
input wire m_axi_aximm2_RVALID;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axi_aximm2, ADDR_WIDTH 64, MAX_BURST_LENGTH 256, NUM_READ_OUTSTANDING 16, NUM_WRITE_OUTSTANDING 16, MAX_READ_BURST_LENGTH 16, MAX_WRITE_BURST_LENGTH 16, PROTOCOL AXI4, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 512, FREQ_HZ 300000000, ID_WIDTH 0, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 1, HAS_REGION 1, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, PHASE 0.000, CLK_DOMA\
IN ulp_clk_kernel_in, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_aximm2 RREADY" *)
output wire m_axi_aximm2_RREADY;

(* SDX_KERNEL = "true" *)
(* SDX_KERNEL_TYPE = "hls" *)
(* SDX_KERNEL_SYNTH_INST = "inst" *)
  ydma #(
    .C_S_AXI_CONTROL_ADDR_WIDTH(7),
    .C_S_AXI_CONTROL_DATA_WIDTH(32),
    .C_M_AXI_AXIMM1_ID_WIDTH(1),
    .C_M_AXI_AXIMM1_ADDR_WIDTH(64),
    .C_M_AXI_AXIMM1_DATA_WIDTH(64),
    .C_M_AXI_AXIMM1_AWUSER_WIDTH(1),
    .C_M_AXI_AXIMM1_ARUSER_WIDTH(1),
    .C_M_AXI_AXIMM1_WUSER_WIDTH(1),
    .C_M_AXI_AXIMM1_RUSER_WIDTH(1),
    .C_M_AXI_AXIMM1_BUSER_WIDTH(1),
    .C_M_AXI_AXIMM1_USER_VALUE(32'H00000000),
    .C_M_AXI_AXIMM1_PROT_VALUE(3'B000),
    .C_M_AXI_AXIMM1_CACHE_VALUE(4'B0011),
    .C_M_AXI_AXIMM2_ID_WIDTH(1),
    .C_M_AXI_AXIMM2_ADDR_WIDTH(64),
    .C_M_AXI_AXIMM2_DATA_WIDTH(512),
    .C_M_AXI_AXIMM2_AWUSER_WIDTH(1),
    .C_M_AXI_AXIMM2_ARUSER_WIDTH(1),
    .C_M_AXI_AXIMM2_WUSER_WIDTH(1),
    .C_M_AXI_AXIMM2_RUSER_WIDTH(1),
    .C_M_AXI_AXIMM2_BUSER_WIDTH(1),
    .C_M_AXI_AXIMM2_USER_VALUE(32'H00000000),
    .C_M_AXI_AXIMM2_PROT_VALUE(3'B000),
    .C_M_AXI_AXIMM2_CACHE_VALUE(4'B0011)
  ) inst (
    .stall_start_ext(stall_start_ext),
    .stall_done_ext(stall_done_ext),
    .stall_start_str(stall_start_str),
    .stall_done_str(stall_done_str),
    .stall_start_int(stall_start_int),
    .stall_done_int(stall_done_int),
    .s_axi_control_AWADDR(s_axi_control_AWADDR),
    .s_axi_control_AWVALID(s_axi_control_AWVALID),
    .s_axi_control_AWREADY(s_axi_control_AWREADY),
    .s_axi_control_WDATA(s_axi_control_WDATA),
    .s_axi_control_WSTRB(s_axi_control_WSTRB),
    .s_axi_control_WVALID(s_axi_control_WVALID),
    .s_axi_control_WREADY(s_axi_control_WREADY),
    .s_axi_control_BRESP(s_axi_control_BRESP),
    .s_axi_control_BVALID(s_axi_control_BVALID),
    .s_axi_control_BREADY(s_axi_control_BREADY),
    .s_axi_control_ARADDR(s_axi_control_ARADDR),
    .s_axi_control_ARVALID(s_axi_control_ARVALID),
    .s_axi_control_ARREADY(s_axi_control_ARREADY),
    .s_axi_control_RDATA(s_axi_control_RDATA),
    .s_axi_control_RRESP(s_axi_control_RRESP),
    .s_axi_control_RVALID(s_axi_control_RVALID),
    .s_axi_control_RREADY(s_axi_control_RREADY),
    .ap_clk(ap_clk),
    .ap_rst_n(ap_rst_n),
    .event_done(event_done),
    .interrupt(interrupt),
    .event_start(event_start),
    .m_axi_aximm1_AWID(),
    .m_axi_aximm1_AWADDR(m_axi_aximm1_AWADDR),
    .m_axi_aximm1_AWLEN(m_axi_aximm1_AWLEN),
    .m_axi_aximm1_AWSIZE(m_axi_aximm1_AWSIZE),
    .m_axi_aximm1_AWBURST(m_axi_aximm1_AWBURST),
    .m_axi_aximm1_AWLOCK(m_axi_aximm1_AWLOCK),
    .m_axi_aximm1_AWREGION(m_axi_aximm1_AWREGION),
    .m_axi_aximm1_AWCACHE(m_axi_aximm1_AWCACHE),
    .m_axi_aximm1_AWPROT(m_axi_aximm1_AWPROT),
    .m_axi_aximm1_AWQOS(m_axi_aximm1_AWQOS),
    .m_axi_aximm1_AWUSER(),
    .m_axi_aximm1_AWVALID(m_axi_aximm1_AWVALID),
    .m_axi_aximm1_AWREADY(m_axi_aximm1_AWREADY),
    .m_axi_aximm1_WID(),
    .m_axi_aximm1_WDATA(m_axi_aximm1_WDATA),
    .m_axi_aximm1_WSTRB(m_axi_aximm1_WSTRB),
    .m_axi_aximm1_WLAST(m_axi_aximm1_WLAST),
    .m_axi_aximm1_WUSER(),
    .m_axi_aximm1_WVALID(m_axi_aximm1_WVALID),
    .m_axi_aximm1_WREADY(m_axi_aximm1_WREADY),
    .m_axi_aximm1_BID(1'B0),
    .m_axi_aximm1_BRESP(m_axi_aximm1_BRESP),
    .m_axi_aximm1_BUSER(1'B0),
    .m_axi_aximm1_BVALID(m_axi_aximm1_BVALID),
    .m_axi_aximm1_BREADY(m_axi_aximm1_BREADY),
    .m_axi_aximm1_ARID(),
    .m_axi_aximm1_ARADDR(m_axi_aximm1_ARADDR),
    .m_axi_aximm1_ARLEN(m_axi_aximm1_ARLEN),
    .m_axi_aximm1_ARSIZE(m_axi_aximm1_ARSIZE),
    .m_axi_aximm1_ARBURST(m_axi_aximm1_ARBURST),
    .m_axi_aximm1_ARLOCK(m_axi_aximm1_ARLOCK),
    .m_axi_aximm1_ARREGION(m_axi_aximm1_ARREGION),
    .m_axi_aximm1_ARCACHE(m_axi_aximm1_ARCACHE),
    .m_axi_aximm1_ARPROT(m_axi_aximm1_ARPROT),
    .m_axi_aximm1_ARQOS(m_axi_aximm1_ARQOS),
    .m_axi_aximm1_ARUSER(),
    .m_axi_aximm1_ARVALID(m_axi_aximm1_ARVALID),
    .m_axi_aximm1_ARREADY(m_axi_aximm1_ARREADY),
    .m_axi_aximm1_RID(1'B0),
    .m_axi_aximm1_RDATA(m_axi_aximm1_RDATA),
    .m_axi_aximm1_RRESP(m_axi_aximm1_RRESP),
    .m_axi_aximm1_RLAST(m_axi_aximm1_RLAST),
    .m_axi_aximm1_RUSER(1'B0),
    .m_axi_aximm1_RVALID(m_axi_aximm1_RVALID),
    .m_axi_aximm1_RREADY(m_axi_aximm1_RREADY),
    .m_axi_aximm2_AWID(),
    .m_axi_aximm2_AWADDR(m_axi_aximm2_AWADDR),
    .m_axi_aximm2_AWLEN(m_axi_aximm2_AWLEN),
    .m_axi_aximm2_AWSIZE(m_axi_aximm2_AWSIZE),
    .m_axi_aximm2_AWBURST(m_axi_aximm2_AWBURST),
    .m_axi_aximm2_AWLOCK(m_axi_aximm2_AWLOCK),
    .m_axi_aximm2_AWREGION(m_axi_aximm2_AWREGION),
    .m_axi_aximm2_AWCACHE(m_axi_aximm2_AWCACHE),
    .m_axi_aximm2_AWPROT(m_axi_aximm2_AWPROT),
    .m_axi_aximm2_AWQOS(m_axi_aximm2_AWQOS),
    .m_axi_aximm2_AWUSER(),
    .m_axi_aximm2_AWVALID(m_axi_aximm2_AWVALID),
    .m_axi_aximm2_AWREADY(m_axi_aximm2_AWREADY),
    .m_axi_aximm2_WID(),
    .m_axi_aximm2_WDATA(m_axi_aximm2_WDATA),
    .m_axi_aximm2_WSTRB(m_axi_aximm2_WSTRB),
    .m_axi_aximm2_WLAST(m_axi_aximm2_WLAST),
    .m_axi_aximm2_WUSER(),
    .m_axi_aximm2_WVALID(m_axi_aximm2_WVALID),
    .m_axi_aximm2_WREADY(m_axi_aximm2_WREADY),
    .m_axi_aximm2_BID(1'B0),
    .m_axi_aximm2_BRESP(m_axi_aximm2_BRESP),
    .m_axi_aximm2_BUSER(1'B0),
    .m_axi_aximm2_BVALID(m_axi_aximm2_BVALID),
    .m_axi_aximm2_BREADY(m_axi_aximm2_BREADY),
    .m_axi_aximm2_ARID(),
    .m_axi_aximm2_ARADDR(m_axi_aximm2_ARADDR),
    .m_axi_aximm2_ARLEN(m_axi_aximm2_ARLEN),
    .m_axi_aximm2_ARSIZE(m_axi_aximm2_ARSIZE),
    .m_axi_aximm2_ARBURST(m_axi_aximm2_ARBURST),
    .m_axi_aximm2_ARLOCK(m_axi_aximm2_ARLOCK),
    .m_axi_aximm2_ARREGION(m_axi_aximm2_ARREGION),
    .m_axi_aximm2_ARCACHE(m_axi_aximm2_ARCACHE),
    .m_axi_aximm2_ARPROT(m_axi_aximm2_ARPROT),
    .m_axi_aximm2_ARQOS(m_axi_aximm2_ARQOS),
    .m_axi_aximm2_ARUSER(),
    .m_axi_aximm2_ARVALID(m_axi_aximm2_ARVALID),
    .m_axi_aximm2_ARREADY(m_axi_aximm2_ARREADY),
    .m_axi_aximm2_RID(1'B0),
    .m_axi_aximm2_RDATA(m_axi_aximm2_RDATA),
    .m_axi_aximm2_RRESP(m_axi_aximm2_RRESP),
    .m_axi_aximm2_RLAST(m_axi_aximm2_RLAST),
    .m_axi_aximm2_RUSER(1'B0),
    .m_axi_aximm2_RVALID(m_axi_aximm2_RVALID),
    .m_axi_aximm2_RREADY(m_axi_aximm2_RREADY)
  );
endmodule
