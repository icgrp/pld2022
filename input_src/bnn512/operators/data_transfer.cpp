#include "../host/typedefs.h"

void data_transfer(
		hls::stream< bit512 > &Input_1,
		hls::stream< bit32 > &Output_1,
		hls::stream< bit32 > &Output_2,
		hls::stream< bit32 > &Output_3,
		hls::stream< bit32 > &Output_4,
		hls::stream< bit32 > &Output_5)
{
#pragma HLS interface axis register port=Input_1
#pragma HLS interface axis register port=Output_1
#pragma HLS interface axis register port=Output_2
#pragma HLS interface axis register port=Output_3
#pragma HLS interface axis register port=Output_4
#pragma HLS interface axis register port=Output_5

bit512 in_tmp;
bit32  out_tmp;
static int sent = 0;

  in_tmp = Input_1.read();
  if(sent == 0){
	  out_tmp(31, 0) = in_tmp(31, 0);
	  Output_2.write(out_tmp);
	  Output_3.write(out_tmp);
	  Output_4.write(out_tmp);
	  Output_5.write(out_tmp);
	  sent = 1;
  }

  for(int j=0; j<16; j++){
#pragma HLS PIPELINE
	out_tmp(31, 0) = in_tmp(32*j+31, 32*j);
	Output_1.write(out_tmp);
  }

  for(int i=0; i<127; i++){
#pragma HLS PIPELINE
    in_tmp = Input_1.read();
    for(int j=0; j<16; j++){
      out_tmp(31, 0) = in_tmp(32*j+31, 32*j);
      Output_1.write(out_tmp);
    }
  }

}
  
     
