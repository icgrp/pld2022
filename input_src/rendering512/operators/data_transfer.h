void data_transfer (
		hls::stream<ap_uint<512> > & Input_1,
		hls::stream<ap_uint<128> > & Output_1
		);

#pragma map_target = HW page_num = 16 inst_mem_size = 32768

