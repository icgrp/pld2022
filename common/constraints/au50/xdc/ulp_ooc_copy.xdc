################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name blp_s_aclk_ctrl_00 -period 20 [get_ports blp_s_aclk_ctrl_00]
create_clock -name blp_s_aclk_freerun_ref_00 -period 10 [get_ports blp_s_aclk_freerun_ref_00]
create_clock -name blp_s_aclk_pcie_00 -period 4 [get_ports blp_s_aclk_pcie_00]
create_clock -name clk_kernel_in -period 3.333 [get_ports clk_kernel_in]
create_clock -name clk_kernel2_in -period 2 [get_ports clk_kernel2_in]
create_clock -name hbm_aclk_in -period 2.222 [get_ports hbm_aclk_in]

################################################################################
# Kernel clock overridden by user
create_clock -name USER_clk_kernel_in -period 5.0 [get_ports clk_kernel_in]
