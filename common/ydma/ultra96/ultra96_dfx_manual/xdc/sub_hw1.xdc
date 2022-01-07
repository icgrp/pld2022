create_pblock p_2
resize_pblock [get_pblocks p_2] -add {SLICE_X4Y0:SLICE_X28Y19}
resize_pblock [get_pblocks p_2] -add {DSP48E2_X0Y0:DSP48E2_X2Y7}
resize_pblock [get_pblocks p_2] -add {RAMB18_X1Y0:RAMB18_X2Y7}
resize_pblock [get_pblocks p_2] -add {RAMB36_X1Y0:RAMB36_X2Y3}

create_pblock p_3
resize_pblock [get_pblocks p_3] -add {CLOCKREGION_X1Y0:CLOCKREGION_X1Y0}


create_pblock p_4
resize_pblock [get_pblocks p_4] -add {CLOCKREGION_X1Y2:CLOCKREGION_X1Y2}


create_pblock p_5
resize_pblock [get_pblocks p_5] -add {SLICE_X4Y160:SLICE_X28Y179}
resize_pblock [get_pblocks p_5] -add {DSP48E2_X0Y64:DSP48E2_X2Y71}
resize_pblock [get_pblocks p_5] -add {RAMB18_X1Y64:RAMB18_X2Y71}
resize_pblock [get_pblocks p_5] -add {RAMB36_X1Y32:RAMB36_X2Y35}























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


