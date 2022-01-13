// color the frame buffer
void coloringFB_top_m15(
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<128> > & Input_2,
		hls::stream<ap_uint<512> > & Output_1);
#pragma map_target = HW page_num = 15 inst_mem_size = 65536
