#include "../host/typedefs.h"
void data_2_1(
			hls::stream<ap_uint<32> > & Input_1,
			hls::stream<ap_uint<32> > & Input_2,
			hls::stream<ap_uint<512> > & Output_1
			)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1
bit512 out_tmp;

	static unsigned int theta[NUM_FEATURES / F_VECTOR_SIZE * 2];

	  STREAM_IN_1: for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE; i ++ )
	  {
	    #pragma HLS pipeline II=1
		theta[i] = Input_1.read();
	  }
	  STREAM_IN_2: for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE; i ++ )
	  {
	    #pragma HLS pipeline II=1
		theta[i+NUM_FEATURES / F_VECTOR_SIZE] = Input_2.read();
	  }

	  //Output_1.write(1025);

	  STREAM_OUT: for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE*2/16; i ++ )
	  {
	    #pragma HLS pipeline II=1
                for(int j=0; j<16; j++){
                  out_tmp(j*32+31, j*32) = theta[16*i+j];
                }
                Output_1.write(out_tmp);
	  }
}

