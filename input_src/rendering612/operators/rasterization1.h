void rasterization1 (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2
		);

#pragma map_target = RISCV page_num = 18 inst_mem_size = 65536
