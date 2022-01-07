
create_pblock p_2
resize_pblock [get_pblocks p_2] -add {CLOCKREGION_X1Y0:CLOCKREGION_X1Y0}


create_pblock p_3
resize_pblock [get_pblocks p_3] -add {SLICE_X14Y120:SLICE_X47Y179}
resize_pblock [get_pblocks p_3] -add {DSP48E2_X1Y48:DSP48E2_X4Y71}
resize_pblock [get_pblocks p_3] -add {RAMB18_X2Y48:RAMB18_X5Y71}
resize_pblock [get_pblocks p_3] -add {RAMB36_X2Y24:RAMB36_X5Y35}





























set_property IS_SOFT TRUE [get_pblocks p_2]
set_property IS_SOFT TRUE [get_pblocks p_3]

set_property SNAPPING_MODE ON [get_pblocks p_2]
set_property SNAPPING_MODE ON [get_pblocks p_3]

add_cells_to_pblock [get_pblocks p_2] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page2_inst]]
add_cells_to_pblock [get_pblocks p_3] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page3_inst]]


