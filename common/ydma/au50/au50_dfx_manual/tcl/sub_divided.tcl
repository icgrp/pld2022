
open_checkpoint ./checkpoint/hw_bb_locked.dcp
pr_subdivide -cell level0_i/ulp -subcells {level0_i/ulp/ydma_1/page2_inst level0_i/ulp/ydma_1/page3_inst level0_i/ulp/ydma_1/page4_inst level0_i/ulp/ydma_1/page5_inst level0_i/ulp/ydma_1/page6_inst level0_i/ulp/ydma_1/page7_inst level0_i/ulp/ydma_1/page8_inst level0_i/ulp/ydma_1/page9_inst level0_i/ulp/ydma_1/page10_inst level0_i/ulp/ydma_1/page11_inst level0_i/ulp/ydma_1/page12_inst level0_i/ulp/ydma_1/page13_inst level0_i/ulp/ydma_1/page14_inst level0_i/ulp/ydma_1/page15_inst level0_i/ulp/ydma_1/page16_inst level0_i/ulp/ydma_1/page17_inst level0_i/ulp/ydma_1/page18_inst  level0_i/ulp/ydma_1/page19_inst level0_i/ulp/ydma_1/page20_inst level0_i/ulp/ydma_1/page21_inst level0_i/ulp/ydma_1/page22_inst level0_i/ulp/ydma_1/page23_inst } ./checkpoint/pfm_dynamic_new_bb.dcp
write_checkpoint -force ./checkpoint/hw_bb_divided.dcp

