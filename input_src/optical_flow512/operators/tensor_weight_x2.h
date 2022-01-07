void tensor_weight_x2(hls::stream< ap_uint<160> > &Input_1,
		     hls::stream< ap_uint<160> > &Output_1,
		     hls::stream< ap_uint<160> > &Output_2);
#pragma map_target=HW page_num=15  inst_mem_size = 32768
