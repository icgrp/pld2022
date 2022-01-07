create_pblock p_2
resize_pblock [get_pblocks p_2] -add {SLICE_X9Y0:SLICE_X17Y59}
resize_pblock [get_pblocks p_2] -add {RAMB18_X1Y0:RAMB18_X2Y23}
resize_pblock [get_pblocks p_2] -add {RAMB36_X1Y0:RAMB36_X2Y11}

create_pblock p_3
resize_pblock [get_pblocks p_3] -add {CLOCKREGION_X1Y0:CLOCKREGION_X1Y0}


create_pblock p_4
resize_pblock [get_pblocks p_4] -add {CLOCKREGION_X1Y2:CLOCKREGION_X1Y2}


create_pblock p_5
resize_pblock [get_pblocks p_5] -add {SLICE_X9Y120:SLICE_X17Y179}
resize_pblock [get_pblocks p_5] -add {RAMB18_X1Y48:RAMB18_X2Y71}
resize_pblock [get_pblocks p_5] -add {RAMB36_X1Y24:RAMB36_X2Y35}





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


