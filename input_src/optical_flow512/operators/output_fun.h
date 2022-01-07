
void output_fun(hls::stream< ap_uint<32> > &Input_1,
		hls::stream< ap_uint<32> > &Input_2,
		hls::stream< ap_uint<512> > &Output_1);
#pragma map_target=HW page_num=13 inst_mem_size = 32768
