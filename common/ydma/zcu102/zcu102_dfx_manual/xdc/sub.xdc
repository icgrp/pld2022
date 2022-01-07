
create_pblock p_2
add_cells_to_pblock [get_pblocks p_2] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page2_inst]]
resize_pblock [get_pblocks p_2] -add {SLICE_X70Y0:SLICE_X95Y59}
resize_pblock [get_pblocks p_2] -add {DSP48E2_X14Y0:DSP48E2_X17Y23}
resize_pblock [get_pblocks p_2] -add {IOB_X0Y0:IOB_X0Y37}
resize_pblock [get_pblocks p_2] -add {RAMB18_X9Y0:RAMB18_X12Y23}
resize_pblock [get_pblocks p_2] -add {RAMB36_X9Y0:RAMB36_X12Y11}

create_pblock p_3
add_cells_to_pblock [get_pblocks p_3] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page3_inst]]
resize_pblock [get_pblocks p_3] -add {SLICE_X77Y120:SLICE_X95Y179}
resize_pblock [get_pblocks p_3] -add {CFGIO_SITE_X0Y0:CFGIO_SITE_X0Y0}
resize_pblock [get_pblocks p_3] -add {DSP48E2_X16Y48:DSP48E2_X17Y71}
resize_pblock [get_pblocks p_3] -add {RAMB18_X10Y48:RAMB18_X12Y71}
resize_pblock [get_pblocks p_3] -add {RAMB36_X10Y24:RAMB36_X12Y35}

create_pblock p_4
add_cells_to_pblock [get_pblocks p_4] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page4_inst]]
resize_pblock [get_pblocks p_4] -add {SLICE_X77Y180:SLICE_X95Y239}
resize_pblock [get_pblocks p_4] -add {DSP48E2_X16Y72:DSP48E2_X17Y95}
resize_pblock [get_pblocks p_4] -add {IOB_X0Y156:IOB_X0Y193}
resize_pblock [get_pblocks p_4] -add {RAMB18_X10Y72:RAMB18_X12Y95}
resize_pblock [get_pblocks p_4] -add {RAMB36_X10Y36:RAMB36_X12Y47}

create_pblock p_5
add_cells_to_pblock [get_pblocks p_5] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page5_inst]]
resize_pblock [get_pblocks p_5] -add {SLICE_X77Y240:SLICE_X95Y299}
resize_pblock [get_pblocks p_5] -add {DSP48E2_X16Y96:DSP48E2_X17Y119}
resize_pblock [get_pblocks p_5] -add {IOB_X0Y208:IOB_X0Y231}
resize_pblock [get_pblocks p_5] -add {RAMB18_X10Y96:RAMB18_X12Y119}
resize_pblock [get_pblocks p_5] -add {RAMB36_X10Y48:RAMB36_X12Y59}

create_pblock p_6
add_cells_to_pblock [get_pblocks p_6] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page6_inst]]
resize_pblock [get_pblocks p_6] -add {SLICE_X79Y300:SLICE_X95Y359}
resize_pblock [get_pblocks p_6] -add {DSP48E2_X16Y120:DSP48E2_X17Y143}
resize_pblock [get_pblocks p_6] -add {IOB_X0Y232:IOB_X0Y255}
resize_pblock [get_pblocks p_6] -add {RAMB18_X10Y120:RAMB18_X12Y143}
resize_pblock [get_pblocks p_6] -add {RAMB36_X10Y60:RAMB36_X12Y71}

create_pblock p_7
add_cells_to_pblock [get_pblocks p_7] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page7_inst]]
resize_pblock [get_pblocks p_7] -add {SLICE_X79Y360:SLICE_X95Y419}
resize_pblock [get_pblocks p_7] -add {DSP48E2_X16Y144:DSP48E2_X17Y167}
resize_pblock [get_pblocks p_7] -add {IOB_X0Y256:IOB_X0Y279}
resize_pblock [get_pblocks p_7] -add {RAMB18_X10Y144:RAMB18_X12Y167}
resize_pblock [get_pblocks p_7] -add {RAMB36_X10Y72:RAMB36_X12Y83}

create_pblock p_8
add_cells_to_pblock [get_pblocks p_8] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page8_inst]]
resize_pblock [get_pblocks p_8] -add {SLICE_X37Y360:SLICE_X66Y419}
resize_pblock [get_pblocks p_8] -add {DSP48E2_X7Y144:DSP48E2_X12Y167}
resize_pblock [get_pblocks p_8] -add {RAMB18_X5Y144:RAMB18_X8Y167}
resize_pblock [get_pblocks p_8] -add {RAMB36_X5Y72:RAMB36_X8Y83}

create_pblock p_9
add_cells_to_pblock [get_pblocks p_9] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page9_inst]]
resize_pblock [get_pblocks p_9] -add {SLICE_X37Y300:SLICE_X66Y359}
resize_pblock [get_pblocks p_9] -add {DSP48E2_X7Y120:DSP48E2_X12Y143}
resize_pblock [get_pblocks p_9] -add {RAMB18_X5Y120:RAMB18_X8Y143}
resize_pblock [get_pblocks p_9] -add {RAMB36_X5Y60:RAMB36_X8Y71}

create_pblock p_10
add_cells_to_pblock [get_pblocks p_10] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page10_inst]]
resize_pblock [get_pblocks p_10] -add {SLICE_X37Y242:SLICE_X66Y299}
resize_pblock [get_pblocks p_10] -add {DSP48E2_X7Y98:DSP48E2_X12Y119}
resize_pblock [get_pblocks p_10] -add {RAMB18_X5Y98:RAMB18_X8Y119}
resize_pblock [get_pblocks p_10] -add {RAMB36_X5Y49:RAMB36_X8Y59}

create_pblock p_11
add_cells_to_pblock [get_pblocks p_11] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page11_inst]]
resize_pblock [get_pblocks p_11] -add {SLICE_X0Y360:SLICE_X27Y419}
resize_pblock [get_pblocks p_11] -add {DSP48E2_X0Y144:DSP48E2_X4Y167}
resize_pblock [get_pblocks p_11] -add {GTHE4_CHANNEL_X0Y12:GTHE4_CHANNEL_X0Y15}
resize_pblock [get_pblocks p_11] -add {GTHE4_COMMON_X0Y3:GTHE4_COMMON_X0Y3}
resize_pblock [get_pblocks p_11] -add {RAMB18_X0Y144:RAMB18_X3Y167}
resize_pblock [get_pblocks p_11] -add {RAMB36_X0Y72:RAMB36_X3Y83}

create_pblock p_12
add_cells_to_pblock [get_pblocks p_12] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page12_inst]]
resize_pblock [get_pblocks p_12] -add {SLICE_X0Y300:SLICE_X10Y359}
resize_pblock [get_pblocks p_12] -add {DSP48E2_X0Y120:DSP48E2_X1Y143}
resize_pblock [get_pblocks p_12] -add {GTHE4_CHANNEL_X0Y8:GTHE4_CHANNEL_X0Y11}
resize_pblock [get_pblocks p_12] -add {GTHE4_COMMON_X0Y2:GTHE4_COMMON_X0Y2}
resize_pblock [get_pblocks p_12] -add {RAMB18_X0Y120:RAMB18_X1Y143}
resize_pblock [get_pblocks p_12] -add {RAMB36_X0Y60:RAMB36_X1Y71}

create_pblock p_13
add_cells_to_pblock [get_pblocks p_13] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page13_inst]]
resize_pblock [get_pblocks p_13] -add {SLICE_X11Y300:SLICE_X27Y359}
resize_pblock [get_pblocks p_13] -add {DSP48E2_X2Y120:DSP48E2_X4Y143}
resize_pblock [get_pblocks p_13] -add {RAMB18_X2Y120:RAMB18_X3Y143}
resize_pblock [get_pblocks p_13] -add {RAMB36_X2Y60:RAMB36_X3Y71}

create_pblock p_14
add_cells_to_pblock [get_pblocks p_14] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page14_inst]]
resize_pblock [get_pblocks p_14] -add {SLICE_X0Y240:SLICE_X10Y299}
resize_pblock [get_pblocks p_14] -add {DSP48E2_X0Y96:DSP48E2_X1Y119}
resize_pblock [get_pblocks p_14] -add {GTHE4_CHANNEL_X0Y4:GTHE4_CHANNEL_X0Y7}
resize_pblock [get_pblocks p_14] -add {GTHE4_COMMON_X0Y1:GTHE4_COMMON_X0Y1}
resize_pblock [get_pblocks p_14] -add {RAMB18_X0Y96:RAMB18_X1Y119}
resize_pblock [get_pblocks p_14] -add {RAMB36_X0Y48:RAMB36_X1Y59}

create_pblock p_15
add_cells_to_pblock [get_pblocks p_15] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page15_inst]]
resize_pblock [get_pblocks p_15] -add {SLICE_X11Y240:SLICE_X27Y299}
resize_pblock [get_pblocks p_15] -add {DSP48E2_X2Y96:DSP48E2_X4Y119}
resize_pblock [get_pblocks p_15] -add {RAMB18_X2Y96:RAMB18_X3Y119}
resize_pblock [get_pblocks p_15] -add {RAMB36_X2Y48:RAMB36_X3Y59}

create_pblock p_16
add_cells_to_pblock [get_pblocks p_16] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page16_inst]]
resize_pblock [get_pblocks p_16] -add {SLICE_X0Y180:SLICE_X10Y239}
resize_pblock [get_pblocks p_16] -add {DSP48E2_X0Y72:DSP48E2_X1Y95}
resize_pblock [get_pblocks p_16] -add {GTHE4_CHANNEL_X0Y0:GTHE4_CHANNEL_X0Y3}
resize_pblock [get_pblocks p_16] -add {GTHE4_COMMON_X0Y0:GTHE4_COMMON_X0Y0}
resize_pblock [get_pblocks p_16] -add {RAMB18_X0Y72:RAMB18_X1Y95}
resize_pblock [get_pblocks p_16] -add {RAMB36_X0Y36:RAMB36_X1Y47}

create_pblock p_17
add_cells_to_pblock [get_pblocks p_17] [get_cells -quiet [list pfm_top_i/dynamic_region/ydma_1/page17_inst]]
resize_pblock [get_pblocks p_17] -add {SLICE_X11Y180:SLICE_X27Y239}
resize_pblock [get_pblocks p_17] -add {DSP48E2_X2Y72:DSP48E2_X4Y95}
resize_pblock [get_pblocks p_17] -add {RAMB18_X2Y72:RAMB18_X3Y95}
resize_pblock [get_pblocks p_17] -add {RAMB36_X2Y36:RAMB36_X3Y47}



set_property IS_SOFT FALSE [get_pblocks p_2]
set_property IS_SOFT FALSE [get_pblocks p_3]
set_property IS_SOFT FALSE [get_pblocks p_4]
set_property IS_SOFT FALSE [get_pblocks p_5]
set_property IS_SOFT FALSE [get_pblocks p_6]
set_property IS_SOFT FALSE [get_pblocks p_7]
set_property IS_SOFT FALSE [get_pblocks p_8]
set_property IS_SOFT FALSE [get_pblocks p_9]
set_property IS_SOFT FALSE [get_pblocks p_10]
set_property IS_SOFT FALSE [get_pblocks p_11]
set_property IS_SOFT FALSE [get_pblocks p_12]
set_property IS_SOFT FALSE [get_pblocks p_13]
set_property IS_SOFT FALSE [get_pblocks p_14]
set_property IS_SOFT FALSE [get_pblocks p_15]
set_property IS_SOFT FALSE [get_pblocks p_16]
set_property IS_SOFT FALSE [get_pblocks p_17]



set_property SNAPPING_MODE ON [get_pblocks p_2]
set_property SNAPPING_MODE ON [get_pblocks p_3]
set_property SNAPPING_MODE ON [get_pblocks p_4]
set_property SNAPPING_MODE ON [get_pblocks p_5]
set_property SNAPPING_MODE ON [get_pblocks p_6]
set_property SNAPPING_MODE ON [get_pblocks p_7]
set_property SNAPPING_MODE ON [get_pblocks p_8]
set_property SNAPPING_MODE ON [get_pblocks p_9]
set_property SNAPPING_MODE ON [get_pblocks p_10]
set_property SNAPPING_MODE ON [get_pblocks p_11]
set_property SNAPPING_MODE ON [get_pblocks p_12]
set_property SNAPPING_MODE ON [get_pblocks p_13]
set_property SNAPPING_MODE ON [get_pblocks p_14]
set_property SNAPPING_MODE ON [get_pblocks p_15]
set_property SNAPPING_MODE ON [get_pblocks p_16]
set_property SNAPPING_MODE ON [get_pblocks p_17]

















