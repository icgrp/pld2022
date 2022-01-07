#include "../host/typedefs.h"

void data_transfer(
		hls::stream< bit512 > &Input_1,
		hls::stream< bit64> &Output_1)
{
#pragma HLS interface axis register port=Input_1
#pragma HLS interface axis register port=Output_1

bit512 in_tmp;
bit64  out_tmp;

  for(int i=0; i<446464/8; i++){
#pragma HLS PIPELINE
    in_tmp = Input_1.read();
    for(int j=0; j<8; j++){
      out_tmp(31, 0) = in_tmp((j<<6)+31, (j<<6)+0 );
      out_tmp(63,32) = in_tmp((j<<6)+63, (j<<6)+32);
      Output_1.write(out_tmp);
    }
  }

}
  
     
