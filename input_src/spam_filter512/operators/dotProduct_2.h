
void dotProduct_2(hls::stream<ap_uint<64> > & Input_1,
		hls::stream<ap_uint<32> > & Input_2,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2
);
#pragma map_target = HW page_num = 7 inst_mem_size = 65536

