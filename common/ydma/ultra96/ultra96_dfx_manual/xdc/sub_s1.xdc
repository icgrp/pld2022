create_pblock p_2
resize_pblock [get_pblocks p_2] -add {SLICE_X4Y0:SLICE_X18Y34}
resize_pblock [get_pblocks p_2] -add {DSP48E2_X0Y0:DSP48E2_X0Y13}
resize_pblock [get_pblocks p_2] -add {RAMB18_X1Y0:RAMB18_X2Y13}
resize_pblock [get_pblocks p_2] -add {RAMB36_X1Y0:RAMB36_X2Y6}

create_pblock p_3
resize_pblock [get_pblocks p_3] -add {SLICE_X19Y0:SLICE_X48Y34}
resize_pblock [get_pblocks p_3] -add {DSP48E2_X1Y0:DSP48E2_X4Y13}
resize_pblock [get_pblocks p_3] -add {RAMB18_X3Y0:RAMB18_X5Y13}
resize_pblock [get_pblocks p_3] -add {RAMB36_X3Y0:RAMB36_X5Y6}


create_pblock p_4
resize_pblock [get_pblocks p_4] -add {SLICE_X16Y145:SLICE_X48Y179}
resize_pblock [get_pblocks p_4] -add {DSP48E2_X1Y58:DSP48E2_X4Y71}
resize_pblock [get_pblocks p_4] -add {RAMB18_X2Y58:RAMB18_X5Y71}
resize_pblock [get_pblocks p_4] -add {RAMB36_X2Y29:RAMB36_X5Y35}


create_pblock p_5
resize_pblock [get_pblocks p_5] -add {SLICE_X1Y145:SLICE_X15Y179}
resize_pblock [get_pblocks p_5] -add {DSP48E2_X0Y58:DSP48E2_X0Y71}
resize_pblock [get_pblocks p_5] -add {RAMB18_X0Y58:RAMB18_X1Y71}
resize_pblock [get_pblocks p_5] -add {RAMB36_X0Y29:RAMB36_X1Y35}





set_property IS_SOFT TRUE [get_pblocks p_2]
set_property IS_SOFT TRUE [get_pblocks p_3]
set_property IS_SOFT TRUE [get_pblocks p_4]
set_property IS_SOFT TRUE [get_pblocks p_5]

set_property SNAPPING_MODE ON [get_pblocks p_2]
set_property SNAPPING_MODE ON [get_pblocks p_3]
set_property SNAPPING_MODE ON [get_pblocks p_4]
set_property SNAPPING_MODE ON [get_pblocks p_5]

add_cells_to_pblock [get_pblocks p_2] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page2_inst]]
add_cells_to_pblock [get_pblocks p_3] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page3_inst]]
add_cells_to_pblock [get_pblocks p_4] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page4_inst]]
add_cells_to_pblock [get_pblocks p_5] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page5_inst]]


