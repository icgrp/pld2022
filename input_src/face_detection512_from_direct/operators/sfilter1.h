void sfilter1

(
  hls::stream<ap_uint<32> > & Input_1,
  hls::stream<ap_uint<32> > & Input_2,
  hls::stream<ap_uint<128> > & Output_1,
  hls::stream<ap_uint<32> > & Output_2,
  hls::stream<ap_uint<32> > & Output_3
);
#pragma map_target = HW page_num = 6 inst_mem_size = 65536
