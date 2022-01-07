
#include "typedefs.h"
#include "../operators/data_transfer.h"
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






#define INPUT_SIZE (IMAGE_NUM*2048/16)
#define OUTPUT_SIZE (IMAGE_NUM)



void top (
    hls::stream<bit512 > & Input_1,
    hls::stream< bit512 > & Output_1
  )
{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1
#pragma HLS DATAFLOW


  hls::stream< bit32 > tran_out1("data_tran_out1");
  hls::stream< bit32 > tran_out2("data_tran_out2");
  hls::stream< bit32 > tran_out3("data_tran_out3");
  hls::stream< bit32 > tran_out4("data_tran_out4");
  hls::stream< bit32 > tran_out5("data_tran_out5");
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
    data_transfer(Input_1, tran_out1, tran_out2, tran_out3, tran_out4, tran_out5);
 
    bc0_gen_0(tran_out2, bin_conv_gen0_out1);

    bc1_gen_0(tran_out3, bc1_gen_0_out1);
    bc1_gen_1(bc1_gen_0_out1, bc1_gen_1_out1);
    bc1_gen_2(bc1_gen_1_out1, bc1_gen_2_out1);

    bc2_gen_0(tran_out4, bc2_gen_0_out1);
    bc2_gen_1(bc2_gen_0_out1, bc2_gen_1_out1);

    bd_gen_0(tran_out5, bd_gen_0_out1);
    bd_gen_1(bd_gen_0_out1, bd_gen_1_out1);
    bd_gen_2(bd_gen_1_out1, bd_gen_2_out1);
    bd_gen_3(bd_gen_2_out1, bd_gen_3_out1);
    bd_gen_4(bd_gen_3_out1, bd_gen_4_out1);
    bd_gen_5(bd_gen_4_out1, bd_gen_5_out1);
    bd_gen_6(bd_gen_5_out1, bd_gen_6_out1);
    bd_gen_7(bd_gen_6_out1, bd_gen_7_out1);
    bd_gen_8(bd_gen_7_out1, bd_gen_8_out1);
    bd_gen_9(bd_gen_8_out1, bd_gen_9_out1);

    fp_conv(tran_out1,fp_conv_out1);

    for(j=0; j<3; j++){
      printf("bin_conv_0=%d\n", j);
      bin_conv_0(bin_conv_gen0_out1, fp_conv_out1, bin_conv0_out1);
    }

    for(j=0; j<7; j++){
      printf("bin_conv_1=%d\n", j);
      bin_conv_1(bc1_gen_2_out1, bin_conv0_out1, bin_conv1_out1);
    }

    for(j=0; j<6; j++){
      printf("bin_conv_2=%d\n", j);
      bin_conv_2(bc2_gen_1_out1, bin_conv1_out1, bin_conv2_out1);
    }

    for(j=0; j<37; j++){
      printf("bin_dense=%d\n", j);
      bin_dense_wrapper(bd_gen_9_out1, bin_conv2_out1, Output_1);
    }

    printf("done\n");
  }


} 


extern "C" {
	void ydma (
			bit64 * input1,
			bit512 * input2,
			bit64 * output1,
			bit512 * output2,
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

          hls::stream<ap_uint<512> > Input_1("Input_1_str");
          hls::stream<ap_uint<512> > Output_1("Output_str");

          for(int i=0; i<config_size; i++){
            v1_buffer[i] = input1[i];
          }
          for(int i=0; i<config_size; i++){
            output1[i] = v1_buffer[i];
          }

	  for(int i=0; i<input_size;  i++){
             bit32 in_tmp;
             Input_1.write(input2[i]);
          }

          top(Input_1, Output_1);

          for(int i=0; i<output_size; i++){
            printf("out_pull=%d\n", i);
            bit512 in_tmp = Output_1.read();
            output2[i] = in_tmp;
          }
	}

}
