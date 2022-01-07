/*===============================================================*/
/*                                                               */
/*                        rendering.cpp                          */
/*                                                               */
/*                 C++ kernel for 3D Rendering                   */
/*                                                               */
/*===============================================================*/

#include "../host/typedefs.h"
#include "../operators/data_proc1.h"
#include "../operators/data_proc2.h"
#include "/home/ylxiao/ws_211/prflow_riscv/workspace/F005_bits_datamover/instr_data2.h"

/*======================UTILITY FUNCTIONS========================*/
const int default_depth = 128;
#define CONFIG_SIZE 24
#define INPUT_SIZE (NUM_FB/16)
#define OUTPUT_SIZE (NUM_FB/16)

void data_gen (
		  hls::stream<ap_uint<64> > & Output_1,
		  hls::stream<ap_uint<512> > & Output_2
		)
{
#pragma HLS INTERFACE axis register both port=Output_1
#pragma HLS INTERFACE axis register both port=Output_2

  bit64 in1;
  bit512 in2;

  in1.range(63, 32) = 0x00000000;
  in1.range(31,  0) = 0x0000800a;
  Output_1.write(in1);

  in1.range(63, 32) = 0x00000000;
  in1.range(31,  0) = INPUT_SIZE;
  Output_1.write(in1);

//data_proc1.Output_1->data_proc2.Input_1
    in1.range(63, 32) = 0x00001000;
    in1.range(31,  0) = 0x91900fe0;
  Output_1.write(in1);
    in1.range(63, 32) = 0x00001880;
    in1.range(31,  0) = 0x21480000;
  Output_1.write(in1);
//DMA.Output_1->data_proc1.Input_1
    in1.range(63, 32) = 0x00000800;
    in1.range(31,  0) = 0x91100fe0;
  Output_1.write(in1);
    in1.range(63, 32) = 0x00001080;
    in1.range(31,  0) = 0x20c80000;
  Output_1.write(in1);
//data_proc2.Output_1->DMA.Input_1
    in1.range(63, 32) = 0x00001800;
    in1.range(31,  0) = 0x90900fe0;
  Output_1.write(in1);
    in1.range(63, 32) = 0x00000880;
    in1.range(31,  0) = 0x21c80000;
  Output_1.write(in1);
    for( int i=0; i<8192; i++){
      in1.range(63, 32) = 0x00001001;
      in1.range(31,  0) = ((i*4+0) << 8) + ((instr_data2[i]>>0 )  & 0x000000ff);
  Output_1.write(in1);
      in1.range(63, 32) = 0x00001001;
      in1.range(31,  0) = ((i*4+1) << 8) + ((instr_data2[i]>>8 )  & 0x000000ff);
  Output_1.write(in1);
      in1.range(63, 32) = 0x00001001;
      in1.range(31,  0) = ((i*4+2) << 8) + ((instr_data2[i]>>16)  & 0x000000ff);
  Output_1.write(in1);
      in1.range(63, 32) = 0x00001001;
      in1.range(31,  0) = ((i*4+3) << 8) + ((instr_data2[i]>>24)  & 0x000000ff);
  Output_1.write(in1);
    }
    // start page2;
    in1.range(63, 32) = 0x00001002;
    in1.range(31,  0) = 0x00000000;
  Output_1.write(in1);
    // start page3;
    in1.range(63, 32) = 0x00001802;
    in1.range(31,  0) = 0x00000000;
  Output_1.write(in1);
  // configure packets

	for ( int i = 0; i < INPUT_SIZE; i++)
	{
	  in2 = i;
          Output_2.write(in2);
	}

}



void top (
		  hls::stream<ap_uint<32> > & Input_1,
		  hls::stream<ap_uint<32> > & Output_1
		)
{
#pragma HLS INTERFACE axis register both port=Input_1
#pragma HLS INTERFACE axis register both port=Output_1
#pragma HLS DATAFLOW

  hls::stream<ap_uint<32> > Output_da1("Output_da1");
#pragma HLS STREAM variable=Output_da1 depth=1024


  // processing NUM_3D_TRI 3D triangles
  TRIANGLES: for (bit16 i = 0; i < 64; i++)
  {

    //printf("we are processing i=%d\n", (unsigned int) i);

    // five stages for processing each 3D triangle
	data_proc1(Input_1, Output_da1);
    data_proc2(Output_da1, Output_1);
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

          hls::stream<ap_uint<32> > Input_1("Input_1_str");
          hls::stream<ap_uint<32> > Output_1("Output_str");

          for(int i=0; i<config_size; i++){ v1_buffer[i] = input1[i]; }
          for(int i=0; i<config_size; i++){ output1[i] = v1_buffer[i]; }

	  for(int i=0; i<input_size;  i++){
            bit512 in_tmp = input2[i];
            for(int j=0; j<16; j++){
              Input_1.write(in_tmp(j*32+31, j*32));
            }
          }
	  
          top(Input_1, Output_1);
 
          for(int i=0; i<output_size; i++){ 
            bit512 out_tmp;
            for(int j=0; j<16; j++){
              out_tmp(j*32+31, j*32) = Output_1.read();
            }
            output2[i] = out_tmp;
	  }
      }
}

