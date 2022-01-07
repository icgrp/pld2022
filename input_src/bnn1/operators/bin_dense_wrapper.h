
void bin_dense_wrapper(
	hls::stream< bit32 > & Input_1,
	hls::stream< bit32 > & Input_2,
	hls::stream< bit32 > & Output_1
);
#pragma map_target = RISCV page_num = 10 inst_mem_size = 98304
