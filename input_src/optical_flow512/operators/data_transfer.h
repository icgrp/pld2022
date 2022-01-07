void data_transfer(
		hls::stream< ap_uint<512> > &Input_1,
		hls::stream< ap_uint<64> > &Output_1);
#pragma map_target = HW page_num = 10 inst_mem_size = 65536

