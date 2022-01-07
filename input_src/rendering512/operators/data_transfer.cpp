#include "../host/typedefs.h"


void data_transfer (
		hls::stream<ap_uint<512> > & Input_1,
		hls::stream<ap_uint<128> > & Output_1
		)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Output_1
	bit512 in_tmp;
	bit128 out_tmp;

    for ( int i = 0; i < NUM_3D_TRI/4; i++)
    {
    	in_tmp = Input_1.read();

    	for (int j=0; j<4; j++){
#pragma HLS PIPELINE II=1
                for(int jj=0; jj<4; jj++){
    		  out_tmp(jj*32+31, jj*32) = in_tmp(j*128+jj*32+31, j*128+jj*32);
                }
    		Output_1.write(out_tmp);
    	}
    }

}

