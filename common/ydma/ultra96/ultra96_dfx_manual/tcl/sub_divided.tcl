
open_checkpoint ./checkpoint/hw_bb_locked.dcp             
pr_subdivide -cell pfm_top_i/dynamic_region -subcells {pfm_top_i/dynamic_region/ydma_1/page2_inst pfm_top_i/dynamic_region/ydma_1/page3_inst } ./checkpoint/pfm_dynamic_new_bb.dcp
write_checkpoint -force ./checkpoint/hw_bb_divided.dcp

