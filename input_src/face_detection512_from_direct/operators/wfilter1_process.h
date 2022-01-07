
void wfilter1_process(
	hls::stream<ap_uint<128> > & Input_1,
	hls::stream<ap_uint<32> > & Output_1
);
#pragma map_target = HW page_num = 16 inst_mem_size = 65536
