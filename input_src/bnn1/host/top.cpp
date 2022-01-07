
#include "typedefs.h"

#include "../operators/fp_conv.h"

#include "../operators/bc0_gen_0.h"

#include "../operators/bc1_gen_0.h"
#include "../operators/bc1_gen_1.h"
#include "../operators/bc1_gen_2.h"

#include "../operators/bc2_gen_0.h"
#include "../operators/bc2_gen_1.h"

#include "../operators/bd_gen_0.h"
#include "../operators/bd_gen_1.h"
#include "../operators/bd_gen_2.h"
#include "../operators/bd_gen_3.h"
#include "../operators/bd_gen_4.h"
#include "../operators/bd_gen_5.h"
#include "../operators/bd_gen_6.h"
#include "../operators/bd_gen_7.h"
#include "../operators/bd_gen_8.h"
#include "../operators/bd_gen_9.h"


#include "../operators/bin_conv_0.h"
#include "../operators/bin_conv_1.h"
#include "../operators/bin_conv_2.h"

#include "../operators/bin_dense_wrapper.h"





void top (
    hls::stream<bit32 > & Input_1,
    hls::stream< bit32 > & Output_1
  )

//( bit32 input[3*NUM_3D_TRI], bit32 output[NUM_FB])
{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1
#pragma HLS DATAFLOW

  hls::stream< bit32 > bin_conv_gen0_out1("bin_conv_gen0_out1");

  hls::stream< bit32 > bc1_gen_0_out1("bc1_gen_0_out1");
  hls::stream< bit32 > bc1_gen_1_out1("bc1_gen_1_out1");
  hls::stream< bit32 > bc1_gen_2_out1("bc1_gen_2_out1");

  hls::stream< bit32 > bc2_gen_0_out1("bc2_gen_0_out1");
  hls::stream< bit32 > bc2_gen_1_out1("bc2_gen_1_out1");

  hls::stream< bit32 > bd_gen_0_out1("bd_gen_0_out1");
  hls::stream< bit32 > bd_gen_1_out1("bd_gen_1_out1");
  hls::stream< bit32 > bd_gen_2_out1("bd_gen_2_out1");
  hls::stream< bit32 > bd_gen_3_out1("bd_gen_3_out1");
  hls::stream< bit32 > bd_gen_4_out1("bd_gen_4_out1");
  hls::stream< bit32 > bd_gen_5_out1("bd_gen_5_out1");
  hls::stream< bit32 > bd_gen_6_out1("bd_gen_6_out1");
  hls::stream< bit32 > bd_gen_7_out1("bd_gen_7_out1");
  hls::stream< bit32 > bd_gen_8_out1("bd_gen_8_out1");
  hls::stream< bit32 > bd_gen_9_out1("bd_gen_9_out1");
  hls::stream< bit32 > bd_gen_10_out1("bd_gen_10_out1");

  hls::stream< bit32 > fp_conv_out1("fp_conv_out1");

  hls::stream< bit32 > bin_conv0_out1("bin_conv0_out1");
  hls::stream< bit32 > bin_conv1_out1("bin_conv1_out1");
  hls::stream< bit32 > bin_conv2_out1("bin_conv1_out1");

  int i, j;


  for (i=0; i<IMAGE_NUM; i++){
	printf("IMAGE_NUM=%d\n", i);
    bc0_gen_0(bin_conv_gen0_out1);

    bc1_gen_0(bc1_gen_0_out1);
    bc1_gen_1(bc1_gen_0_out1, bc1_gen_1_out1);
    bc1_gen_2(bc1_gen_1_out1, bc1_gen_2_out1);

    bc2_gen_0(bc2_gen_0_out1);
    bc2_gen_1(bc2_gen_0_out1, bc2_gen_1_out1);

    bd_gen_0(bd_gen_0_out1);
    bd_gen_1(bd_gen_0_out1, bd_gen_1_out1);
    bd_gen_2(bd_gen_1_out1, bd_gen_2_out1);
    bd_gen_3(bd_gen_2_out1, bd_gen_3_out1);
    bd_gen_4(bd_gen_3_out1, bd_gen_4_out1);
    bd_gen_5(bd_gen_4_out1, bd_gen_5_out1);
    bd_gen_6(bd_gen_5_out1, bd_gen_6_out1);
    bd_gen_7(bd_gen_6_out1, bd_gen_7_out1);
    bd_gen_8(bd_gen_7_out1, bd_gen_8_out1);
    bd_gen_9(bd_gen_8_out1, bd_gen_9_out1);

    fp_conv(Input_1, fp_conv_out1);

    for(j=0; j<3; j++){
      //printf("bin_conv_wrapper_0=%d\n", j);
      bin_conv_0(bin_conv_gen0_out1, fp_conv_out1, bin_conv0_out1);
    }

    for(j=0; j<7; j++){
      bin_conv_1(bc1_gen_2_out1, bin_conv0_out1, bin_conv1_out1);
    }

    for(j=0; j<6; j++){
      bin_conv_2(bc2_gen_1_out1, bin_conv1_out1, bin_conv2_out1);
    }

    for(j=0; j<37; j++){
      bin_dense_wrapper(bd_gen_9_out1, bin_conv2_out1, Output_1);
    }
  }

} 

void top1 (
    hls::stream<bit32 > & Input_1,
    hls::stream< bit32 > & Output_1
  )
{
	for(int i=0; i<IMAGE_NUM*2048; i++){
		Input_1.read();
	}
	for(int i=0; i<IMAGE_NUM; i++){
		Output_1.write(i);
	}
}
extern "C" {
	void ydma (
			bit64 * input1,
			bit32 * input2,
			bit64 * output1,
			bit32 * output2,
			int config_size,
			int input_size,
			int output_size
			)
	{
#pragma HLS INTERFACE m_axi port=input1 bundle=aximm1
#pragma HLS INTERFACE m_axi port=input2 bundle=aximm2
#pragma HLS INTERFACE m_axi port=output1 bundle=aximm1
#pragma HLS INTERFACE m_axi port=output2 bundle=aximm2
	#pragma HLS DATAFLOW

	  bit64 v1_buffer[256];   // Local memory to store vector1
	  //hls::stream< unsigned int > v1_buffer;
	  #pragma HLS STREAM variable=v1_buffer depth=256

          hls::stream<ap_uint<32> > Input_1("Input_1_str");
          hls::stream<ap_uint<32> > Output_1("Output_str");

          for(int i=0; i<config_size; i++){
            v1_buffer[i] = input1[i];
            printf("input1[%d]\n", i);
          }
          for(int i=0; i<config_size; i++){ output1[i] = v1_buffer[i]; }

	  for(int i=0; i<input_size;  i++){
             Input_1.write(input2[i]);
             //printf("input2[%d]\n", i);
          }

          top(Input_1, Output_1);

          for(int i=0; i<output_size; i++){ output2[i] = Output_1.read(); }
	}

}
