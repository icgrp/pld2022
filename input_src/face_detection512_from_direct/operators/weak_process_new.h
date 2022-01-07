void weak_process_new
(
  hls::stream<ap_uint<32> > & Input_1,
  hls::stream<ap_uint<32> > & Input_2,
  hls::stream<ap_uint<32> > & Input_3,
  hls::stream<ap_uint<32> > & Input_4,
  hls::stream<ap_uint<32> > & Input_5,
  hls::stream<ap_uint<32> > & Input_6,
  hls::stream<ap_uint<512> > & Output_1,
  hls::stream<ap_uint<32> > & Output_2
);
#pragma map_target = HW page_num = 12 inst_mem_size = 65536
