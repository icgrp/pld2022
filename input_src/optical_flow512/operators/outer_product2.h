void outer_product2(
    		       hls::stream< ap_uint<32> > &Input_1,
		       hls::stream< ap_uint<32> > &Input_2,
		       hls::stream< ap_uint<32> > &Input_3,
		   hls::stream< ap_uint<160> > &Output_1
			);
#pragma map_target=HW page_num = 12 inst_mem_size = 32768
