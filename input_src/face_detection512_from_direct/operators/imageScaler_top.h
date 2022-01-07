void imageScaler_top
(
  hls::stream<ap_uint<512> > & Input_1,
  hls::stream<ap_uint<32> > & Output_1);
#pragma map_target = HW page_num = 4 inst_mem_size = 65536
