void strong_classifier

(
  hls::stream<ap_uint<128> > & Input_1,
  hls::stream<ap_uint<128> > & Input_2,
  hls::stream<ap_uint<128> > & Input_3,
  hls::stream<ap_uint<128> > & Input_4,
  hls::stream<ap_uint<128> > & Input_5,
  hls::stream<ap_uint<32> > & Output_1
);
#pragma map_target = HW page_num = 11 inst_mem_size = 32768
