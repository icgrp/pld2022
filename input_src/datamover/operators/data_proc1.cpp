#include "../host/typedefs.h"



void data_proc1 (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1
		)
{
#pragma HLS INTERFACE axis register both port=Input_1
#pragma HLS INTERFACE axis register both port=Output_1

	unsigned int tmp;

	for(int i=0; i<MAX_X; i++){
		tmp = Input_1.read();
		tmp = tmp + 3;
		Output_1.write(tmp);
	}
}

