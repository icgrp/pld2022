ungroup_bd_cells [get_bd_cells axi_leaf]
startgroup
delete_bd_objs [get_bd_nets axi_dma_0_m_axis_mm2s_tvalid] [get_bd_nets astream_shell_in1_ready_upward] [get_bd_nets xlconstant_0_dout_1] [get_bd_intf_nets axi_dma_0_M_AXI_SG] [get_bd_intf_nets axi_dma_0_M_AXI_MM2S] [get_bd_intf_nets axi_dma_0_M_AXI_S2MM] [get_bd_intf_nets ps8_0_axi_periph_M01_AXI] [get_bd_intf_nets ip2DMA_0_m_axis_mm2s] [get_bd_intf_nets axi_smc_M00_AXI] [get_bd_intf_nets zynq_ultra_ps_e_0_M_AXI_HPM0_FPD] [get_bd_intf_nets zynq_ultra_ps_e_0_M_AXI_HPM1_FPD] [get_bd_intf_nets ps8_0_axi_periph_M00_AXI] [get_bd_nets axi_dma_0_m_axis_mm2s_tdata] [get_bd_cells axi_smc] [get_bd_cells zynq_ultra_ps_e_0] [get_bd_cells axi_dma_0] [get_bd_cells xlconstant_2] [get_bd_cells AxiLite2Bft_v2_0_0]
delete_bd_objs [get_bd_cells ps8_0_axi_periph]
endgroup
startgroup
create_bd_port -dir I -from 127 -to 0 din
connect_bd_net [get_bd_pins /astream_shell_in1/din] [get_bd_ports din]
endgroup
set_property location {1 201 1334} [get_bd_cells astream_shell_in1]
startgroup
create_bd_port -dir I val_in
connect_bd_net [get_bd_pins /astream_shell_in1/val_in] [get_bd_ports val_in]
endgroup
startgroup
create_bd_port -dir O ready_upward
connect_bd_net [get_bd_pins /astream_shell_in1/ready_upward] [get_bd_ports ready_upward]
endgroup


create_bd_port -dir O -from 127 -to 0 m_axis_mm2s_tdata
connect_bd_net [get_bd_pins /ip2DMA_0/m_axis_mm2s_tdata] [get_bd_ports m_axis_mm2s_tdata]
create_bd_port -dir O -from 15 -to 0 m_axis_mm2s_tkeep
connect_bd_net [get_bd_pins /ip2DMA_0/m_axis_mm2s_tkeep] [get_bd_ports m_axis_mm2s_tkeep]
create_bd_port -dir O m_axis_mm2s_tlast
connect_bd_net [get_bd_pins /ip2DMA_0/m_axis_mm2s_tlast] [get_bd_ports m_axis_mm2s_tlast]
create_bd_port -dir O m_axis_mm2s_tvalid
connect_bd_net [get_bd_pins /ip2DMA_0/m_axis_mm2s_tvalid] [get_bd_ports m_axis_mm2s_tvalid]
create_bd_port -dir I m_axis_mm2s_tready
connect_bd_net [get_bd_pins /ip2DMA_0/m_axis_mm2s_tready] [get_bd_ports m_axis_mm2s_tready]

create_bd_port -dir I clk_bft
connect_bd_net [get_bd_ports clk_bft] [get_bd_pins net0/clk]
create_bd_port -dir I clk_user
connect_bd_net [get_bd_ports clk_user] [get_bd_pins rst_axi/slowest_sync_clk]
create_bd_port -dir I reset_n
connect_bd_net [get_bd_ports reset_n] [get_bd_pins rst_axi/ext_reset_in]



































