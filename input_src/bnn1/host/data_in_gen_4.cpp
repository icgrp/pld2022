#include "typedefs.h"
void data_in_gen_4(int image_num, hls::stream< Word > & Input_1, hls::stream< bit32 > & Output_1){
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1
#include "data_in_par_4.h"

Word in_tmp;
int counter=0;

 loop_redir: for(int i=0; i<81920; i++){
#pragma HLS PIPELINE II=1
	if(counter < image_num*1024){
		in_tmp = Input_1.read();
		Output_1.write(in_tmp(31,  0));
		Output_1.write(in_tmp(63, 32));
	}else
		Input_1.read();
	counter++;
  }
 loop_0: for(int i=0; i<16384; i++){
#pragma HLS PIPELINE II=1
	 if(counter < image_num*1024){
		 Output_1.write(data_in_4_0[i](31,  0));
	     Output_1.write(data_in_4_0[i](63, 32));
	 }
  }


 loop_1: for(int i=0; i<4096; i++){
#pragma HLS PIPELINE II=1
	 if(counter < image_num*1024){
		 Output_1.write(data_in_4_1[i](31,  0));
	     Output_1.write(data_in_4_1[i](63, 32));
	 }
  }
}
