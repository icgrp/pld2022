void data_1_4_2(
		    hls::stream<ap_uint<64> > & Input_1,
			hls::stream<ap_uint<32> > & Input_2,
			hls::stream<ap_uint<32> > & Input_3,
			hls::stream<ap_uint<32> > & Input_4,
			hls::stream<ap_uint<32> > & Input_5,
			hls::stream<ap_uint<64> > & Output_1,
			hls::stream<ap_uint<64> > & Output_2,
			hls::stream<ap_uint<64> > & Output_3,
			hls::stream<ap_uint<64> > & Output_4,
			hls::stream<ap_uint<32> > & Output_5
			);
#pragma map_target = HW page_num = 15 inst_mem_size = 32768

