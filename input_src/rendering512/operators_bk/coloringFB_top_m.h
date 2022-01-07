// color the frame buffer
void coloringFB_top_m(
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Input_2,
		hls::stream<ap_uint<32> > & Output_1);
#pragma map_target = HW page_num = 12 inst_mem_size = 65536
