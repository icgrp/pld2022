void Sigmoid_axi(
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Input_2,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2);
#pragma map_target = HW page_num = 21 inst_mem_size = 131072
