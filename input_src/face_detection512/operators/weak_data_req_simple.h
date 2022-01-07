void weak_data_req_simple
(
  hls::stream<ap_uint<32> > & Input_1,
  hls::stream<ap_uint<128> > & Output_1,
  hls::stream<ap_uint<128> > & Output_2,
  hls::stream<ap_uint<128> > & Output_3,
  hls::stream<ap_uint<128> > & Output_4,
  hls::stream<ap_uint<128> > & Output_5
);
#pragma map_target = HW page_num = 23 inst_mem_size = 131072
