void data_transfer(
		hls::stream< ap_uint<512> > &Input_1,
		hls::stream< ap_uint<32> > &Output_1,
		hls::stream< ap_uint<32> > &Output_2,
		hls::stream< ap_uint<32> > &Output_3,
		hls::stream< ap_uint<32> > &Output_4,
		hls::stream< ap_uint<32> > &Output_5);
#pragma map_target = HW page_num = 12 inst_mem_size = 65536

