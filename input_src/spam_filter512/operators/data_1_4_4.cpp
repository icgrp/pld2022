#include "../host/typedefs.h"
void data_1_4_4(
			hls::stream<ap_uint<32> > & Input_1,
			hls::stream<ap_uint<32> > & Input_2,
			hls::stream<ap_uint<32> > & Input_3,
			hls::stream<ap_uint<32> > & Input_4,
			hls::stream<ap_uint<32> > & Input_5,
			hls::stream<ap_uint<32> > & Output_1,
			hls::stream<ap_uint<32> > & Output_2,
			hls::stream<ap_uint<32> > & Output_3,
			hls::stream<ap_uint<32> > & Output_4,
			hls::stream<ap_uint<32> > & Output_5
			)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Input_3
#pragma HLS INTERFACE axis register port=Input_4
#pragma HLS INTERFACE axis register port=Input_5
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2
#pragma HLS INTERFACE axis register port=Output_3
#pragma HLS INTERFACE axis register port=Output_4
#pragma HLS INTERFACE axis register port=Output_5

	static char ExecuteAdd = 1;

	if(ExecuteAdd == 1)
	{
		FeatureType a1;
		FeatureType a2;
		FeatureType a3;
		FeatureType a4;
		FeatureType c;
		a1(31,0) = Input_1.read();
		a2(31,0) = Input_2.read();
		a3(31,0) = Input_3.read();
		a4(31,0) = Input_4.read();
		c = a1+a2+a3+a4;
		bit32 out_tmp;
		out_tmp(31,0) = c.range(31,0);
		Output_1.write(out_tmp);
		ExecuteAdd = 0;
	}else{
		bit32 tmp;
		tmp = Input_5.read();
		Output_2.write(tmp);
		Output_3.write(tmp);
		Output_4.write(tmp);
		Output_5.write(tmp);
		ExecuteAdd = 1;
	}
}
