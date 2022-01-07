#include "../host/typedefs.h"
void output_fun(hls::stream<stdio_t> &Input_1,
		hls::stream<stdio_t> &Input_2,
		hls::stream< ap_uint<512> > &Output_1)
{
#pragma HLS interface axis register port=Input_1
#pragma HLS interface axis register port=Output_1
#pragma HLS interface axis register port=Input_2
	//while (Input_1.empty());

	OUT_CONVERT: for (int i = 0; i < MAX_HEIGHT*MAX_WIDTH/8; i++)
	{
	  bit512 tmpframe;
      #pragma HLS pipeline II = 4
	  for(int j=0; j<8; j++){
		  tmpframe(j*64+31, j*64   ) = Input_1.read();
		  tmpframe(j*64+63, j*64+32) = Input_2.read();
	  }
	  Output_1.write(tmpframe);
	}
}


