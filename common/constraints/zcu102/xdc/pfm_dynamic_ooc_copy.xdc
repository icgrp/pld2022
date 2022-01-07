################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name clkwiz_kernel2_clk_out1 -period 3.333 [get_ports clkwiz_kernel2_clk_out1]
create_clock -name clkwiz_kernel3_clk_out -period 10 [get_ports clkwiz_kernel3_clk_out]
create_clock -name clkwiz_kernel4_clk_out -period 5 [get_ports clkwiz_kernel4_clk_out]
create_clock -name clkwiz_kernel5_clk_out -period 2.500 [get_ports clkwiz_kernel5_clk_out]
create_clock -name clkwiz_kernel6_clk_out -period 1.667 [get_ports clkwiz_kernel6_clk_out]
create_clock -name clkwiz_kernel_clk_out1 -period 6.667 [get_ports clkwiz_kernel_clk_out1]
create_clock -name clkwiz_sysclks_clk_out2 -period 13.333 [get_ports clkwiz_sysclks_clk_out2]

################################################################################