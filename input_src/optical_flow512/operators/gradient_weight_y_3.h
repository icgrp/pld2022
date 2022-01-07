
// average the gradient in y direction
void gradient_weight_y_3(
    hls::stream< ap_uint<32> > &Input_1,
    hls::stream< ap_uint<32> > &Output_1);
#pragma map_target=HW page_num=9 inst_mem_size = 65536
