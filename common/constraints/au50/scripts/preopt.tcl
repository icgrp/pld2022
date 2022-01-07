
# Renaming hbm aclk to align with what is expected in the scaleable system clock definition 
create_generated_clock -name hbm_aclk [get_pins level0_i/ulp/ulp_ucs/inst/clkwiz_hbm/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT0] -quiet



# #######################################################################
# WARNING: WORKAROUND!
# #######################################################################
#
# These constraints are added as a workaround to CR-1038346 
# Remove these constraints when CR is resolved.
#
# Error codes: ERROR: [VPL 30-1112] 
#
# The problem is that the XSA cannot register the parent PBLOCKS in the EARLY XDC processing stage and only as NORMAL. This creates a race condition where the 
# constraints for the parent and child processing occurs. They cannot be moved to LATE since that is where the constraints of the MSS happen. That would just move the 
# race condition from the NORMAL phase to the LATE phase.
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR0] [get_cells level0_i/ulp/SLR0]
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR0] [get_cells level0_i/ulp/memory_subsystem/inst/memory/plram_mem00] -quiet
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR0] [get_cells level0_i/ulp/memory_subsystem/inst/memory/plram_mem01] -quiet
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR0] [get_cells level0_i/ulp/memory_subsystem/inst/memory/plram_mem00_bram] -quiet
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR0] [get_cells level0_i/ulp/memory_subsystem/inst/memory/plram_mem01_bram] -quiet

# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR1] [get_cells level0_i/ulp/SLR1]
# #add_cells_to_pblock [get_pblocks pblock_dynamic_SLR1] [get_cells level0_i/ulp/ulp_ucs]
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR1] [get_cells level0_i/ulp/memory_subsystem/inst/memory/plram_mem02] -quiet
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR1] [get_cells level0_i/ulp/memory_subsystem/inst/memory/plram_mem03] -quiet
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR1] [get_cells level0_i/ulp/memory_subsystem/inst/memory/plram_mem02_bram] -quiet
# add_cells_to_pblock [get_pblocks pblock_dynamic_SLR1] [get_cells level0_i/ulp/memory_subsystem/inst/memory/plram_mem03_bram] -quiet


# set_property CONTAIN_ROUTING 0 [get_pblocks pblock_dynamic_SLR0]
# set_property EXCLUDE_PLACEMENT 0 [get_pblocks pblock_dynamic_SLR0]
# set_property CONTAIN_ROUTING 0 [get_pblocks pblock_dynamic_SLR1]
# set_property EXCLUDE_PLACEMENT 0 [get_pblocks pblock_dynamic_SLR1]
