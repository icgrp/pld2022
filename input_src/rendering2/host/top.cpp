/*===============================================================*/
/*                                                               */
/*                        rendering.cpp                          */
/*                                                               */
/*                 C++ kernel for 3D Rendering                   */
/*                                                               */
/*===============================================================*/

#include "../host/typedefs.h"
#include "../operators/data_redir_m.h"
#include "../operators/rasterization2_m.h"


/*======================UTILITY FUNCTIONS========================*/
const int default_depth = 128;





void top (
		  hls::stream<ap_uint<32> > & Input_1,
		  hls::stream<ap_uint<32> > & Output_1
		)
{
#pragma HLS INTERFACE axis register both port=Input_1
#pragma HLS INTERFACE axis register both port=Output_1
#pragma HLS DATAFLOW
  // local variables
  Triangle_2D triangle_2ds;
  Triangle_2D triangle_2ds_same;

  bit16 size_fragment;
  CandidatePixel fragment[500];

  bit16 size_pixels;
  Pixel pixels[500];

  bit8 frame_buffer[MAX_X][MAX_Y];
  bit2 angle = 0;

  bit8 max_min[5];
  bit16 max_index[1];
  bit2 flag;
  hls::stream<ap_uint<32> > Output_redir_odd("Output_redir_odd");
#pragma HLS STREAM variable=Output_redir_odd depth=1024


  hls::stream<ap_uint<32> > Output_r2_odd_top("Output_r2_odd_top");
#pragma HLS STREAM variable=Output_r2_odd_top depth=1024

  hls::stream<ap_uint<32> > Output_zcu_top("Output_zcu_top");
#pragma HLS STREAM variable=Output_zcu_top depth=1024


  // processing NUM_3D_TRI 3D triangles
  TRIANGLES: for (bit16 i = 0; i < NUM_3D_TRI; i++)
  {

    //printf("we are processing i=%d\n", (unsigned int) i);

    // five stages for processing each 3D triangle
	data_redir_m(Input_1, Output_redir_odd);
    rasterization2_m(Output_redir_odd, Output_1);
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

