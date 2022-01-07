
//data_input_redirection
void data_in_redir( hls::stream<ap_uint<512> > & Input_1,
			hls::stream<ap_uint<64> > & Output_1,
			hls::stream<ap_uint<64> > & Output_2
			);

#pragma map_target = HW page_num = 12 inst_mem_size = 65535



