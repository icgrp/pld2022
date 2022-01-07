
open_checkpoint ./checkpoint/hw_bb_locked.dcp             
pr_subdivide -cell pfm_top_i/dynamic_region -subcells {pfm_top_i/dynamic_region/ydma_1/page2_inst pfm_top_i/dynamic_region/ydma_1/page3_inst pfm_top_i/dynamic_region/ydma_1/page4_inst pfm_top_i/dynamic_region/ydma_1/page5_inst pfm_top_i/dynamic_region/ydma_1/page6_inst pfm_top_i/dynamic_region/ydma_1/page7_inst pfm_top_i/dynamic_region/ydma_1/page8_inst pfm_top_i/dynamic_region/ydma_1/page9_inst pfm_top_i/dynamic_region/ydma_1/page10_inst pfm_top_i/dynamic_region/ydma_1/page11_inst pfm_top_i/dynamic_region/ydma_1/page12_inst pfm_top_i/dynamic_region/ydma_1/page13_inst pfm_top_i/dynamic_region/ydma_1/page14_inst pfm_top_i/dynamic_region/ydma_1/page15_inst pfm_top_i/dynamic_region/ydma_1/page16_inst pfm_top_i/dynamic_region/ydma_1/page17_inst} ./checkpoint/pfm_dynamic_new_bb.dcp
write_checkpoint -force ./checkpoint/hw_bb_divided.dcp

