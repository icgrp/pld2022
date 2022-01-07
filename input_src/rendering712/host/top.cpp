/*===============================================================*/
/*                                                               */
/*                        rendering.cpp                          */
/*                                                               */
/*                 C++ kernel for 3D Rendering                   */
/*                                                               */
/*===============================================================*/

#include "../host/typedefs.h"
#include "../operators/data_redir_m.h"
#include "../operators/zculling_top.h"
#include "../operators/zculling_bot.h"
#include "../operators/coloringFB_bot_m.h"
#include "../operators/coloringFB_top_m.h"

/*======================UTILITY FUNCTIONS========================*/
const int default_depth = 128;


void data_gen(
		  hls::stream<ap_uint<32> > & Output_1
		)

//( bit32 input[3*NUM_3D_TRI], bit32 output[NUM_FB])
{
#pragma HLS INTERFACE axis register_mode=both register port=Output_1
#include "input_data.h"
    // create space for input and output
    bit32 input_tmp;
    bit32 input[3 * NUM_3D_TRI];
    bit32 output[NUM_FB];

    // pack input data for better performance
    for ( int i = 0; i < NUM_3D_TRI; i++)
    {
        input_tmp(7,   0) = triangle_3ds[i].x0;
        input_tmp(15,  8) = triangle_3ds[i].y0;
        input_tmp(23, 16) = triangle_3ds[i].z0;
        input_tmp(31, 24) = triangle_3ds[i].x1;
        Output_1.write(input_tmp);

        input_tmp(7, 0) = triangle_3ds[i].y1;
        input_tmp(15, 8) = triangle_3ds[i].z1;
        input_tmp(23, 16) = triangle_3ds[i].x2;
        input_tmp(31, 24) = triangle_3ds[i].y2;
        Output_1.write(input_tmp);

        input_tmp(7, 0) = triangle_3ds[i].z2;
        input_tmp(31, 8) = 0;
        Output_1.write(input_tmp);
    }
}

void top (
		  hls::stream<ap_uint<32> > & Input_1,
		  hls::stream<ap_uint<32> > & Output_1
		)

//( bit32 input[3*NUM_3D_TRI], bit32 output[NUM_FB])
{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1
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
  hls::stream<ap_uint<32> > Output_redir_odd("sb1");
#pragma HLS STREAM variable=Output_redir_odd depth=default_depth




  hls::stream<ap_uint<32> > Output_redir_even("sb2");
#pragma HLS STREAM variable=Output_redir_even depth=default_depth

  hls::stream<ap_uint<32> > Output_projc_odd("sb3");
#pragma HLS STREAM variable=Output_projc_odd depth=default_depth
  hls::stream<ap_uint<32> > Output_projc_even("sb4");
#pragma HLS STREAM variable=Output_projc_even depth=default_depth
  hls::stream<ap_uint<32> > Output_r1_odd("sb5");
#pragma HLS STREAM variable=Output_r1_odd depth=default_depth
  hls::stream<ap_uint<32> > Output_r1_even("sb6");
#pragma HLS STREAM variable=Output_r1_even depth=default_depth

  hls::stream<ap_uint<32> > Output_r2_odd_top("sb7");
#pragma HLS STREAM variable=Output_r2_odd_top depth=default_depth
  hls::stream<ap_uint<32> > Output_r2_odd_bot("sb8");
#pragma HLS STREAM variable=Output_r2_odd_bot depth=default_depth
  hls::stream<ap_uint<32> > Output_r2_even_top("sb9");
#pragma HLS STREAM variable=Output_r2_even_top depth=default_depth
  hls::stream<ap_uint<32> > Output_r2_even_bot("sb10");
#pragma HLS STREAM variable=Output_r2_even_bot depth=default_depth


  hls::stream<ap_uint<32> > Output_zcu_top("sb11");
#pragma HLS STREAM variable=Output_zcu_top depth=default_depth
  hls::stream<ap_uint<32> > Output_zcu_bot("sb12");
#pragma HLS STREAM variable=Output_zcu_bot depth=default_depth
  hls::stream<ap_uint<32> > Output_cfb_top("sb13");
#pragma HLS STREAM variable=Output_cfb_top depth=default_depth
  hls::stream<ap_uint<32> > Output_cfb_bot("sb14");
#pragma HLS STREAM variable=Output_cfb_bot depth=default_depth

  hls::stream<ap_uint<32> > Output_pp("sb15");


  hls::stream<ap_uint<32> > Output_data_m("data_1");


  // processing NUM_3D_TRI 3D triangles
  TRIANGLES: for (int i = 0; i < NUM_3D_TRI/2; i++)
  {

	  //printf("i=%d\n", i);
    // five stages for processing each 3D triangle
	data_redir_m(Input_1,Output_r2_odd_top, Output_r2_odd_bot, Output_r2_even_top, Output_r2_even_bot);

    zculling_top( Output_r2_odd_top, Output_r2_even_top, Output_zcu_top);
    zculling_bot(Output_r2_odd_bot, Output_r2_even_bot, Output_zcu_bot);
    coloringFB_bot_m(Output_zcu_bot, Output_cfb_bot);
    coloringFB_top_m(Output_zcu_top, Output_cfb_bot, Output_1);



    zculling_top( Output_r2_odd_top, Output_r2_even_top, Output_zcu_top);
    zculling_bot(Output_r2_odd_bot, Output_r2_even_bot, Output_zcu_bot);
    coloringFB_bot_m(Output_zcu_bot, Output_cfb_bot);
    coloringFB_top_m(Output_zcu_top, Output_cfb_bot, Output_1);


  }

  // output values: frame buffer
  //output_FB_dul(Output_cfb_top, Output_cfb_bot,Output_1);

#ifdef PROFILE
  printf("data_redir_m_in_1,%d\n", data_redir_m_in_1);
  printf("data_redir_m_out_1,%d\n", data_redir_m_out_1);
  printf("data_redir_m_out_2,%d\n", data_redir_m_out_2);
  printf("rasterization2_m_in_1,%d\n", rasterization2_m_in_1);
  printf("rasterization2_m_in_2,%d\n", rasterization2_m_in_2);
  printf("rasterization2_m_out_1,%d\n", rasterization2_m_out_1);
  printf("rasterization2_m_out_2,%d\n", rasterization2_m_out_2);
  printf("rasterization2_m_out_3,%d\n", rasterization2_m_out_3);
  printf("rasterization2_m_out_4,%d\n", rasterization2_m_out_4);
  printf("zculling_top_in_1,%d\n", zculling_top_in_1);
  printf("zculling_top_in_2,%d\n", zculling_top_in_2);
  printf("zculling_top_out_1,%d\n", zculling_top_out_1);
  printf("zculling_bot_in_1,%d\n", zculling_bot_in_1);
  printf("zculling_bot_in_2,%d\n", zculling_bot_in_2);
  printf("zculling_bot_out_1,%d\n", zculling_bot_out_1);
  printf("coloringFB_top_in_1,%d\n", coloringFB_top_m_in_1);
  printf("coloringFB_top_in_2,%d\n", coloringFB_top_m_in_2);
  printf("coloringFB_top_out_1,%d\n", coloringFB_top_m_out_1);
  printf("coloringFB_bot_in_1,%d\n", coloringFB_bot_m_in_1);
  printf("coloringFB_bot_out_1,%d\n", coloringFB_bot_m_out_1);
#endif


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


void config_parser(
		hls::stream< bit64 > & input1,
		hls::stream< bit32 > & input2,
		hls::stream< bit64 > & output1,
		hls::stream< bit32 > & output2,
		hls::stream< bit64 > & output3

		)
{
#pragma HLS INTERFACE axis register_mode=both register port=input1
#pragma HLS INTERFACE axis register_mode=both register port=input2
#pragma HLS INTERFACE axis register_mode=both register port=output1
#pragma HLS INTERFACE axis register_mode=both register port=output2
#pragma HLS INTERFACE axis register_mode=both register port=output3

	bit64 v1_buffer[256];
	unsigned int config_num;
	unsigned int data_num;

	config_num = input1.read();
	data_num = input1.read();


	// read the configuration packets
	for(int i=0; i<config_num; i++){
#pragma HLS PIPELINE II=1
		v1_buffer[i] = input1.read();
	}

	// send the configuration packets to the BFT
	for(int i=0; i<config_num; i++){
#pragma HLS PIPELINE II=1
		output1.write(v1_buffer[i]);
	}

	// send the configuration packets back to the host
	output3.write(config_num);
	output3.write(data_num);
	for(int i=0; i<config_num; i++){
#pragma HLS PIPELINE II=1
		output3.write(i);
	}

	// transfer the data to the kernel
	for(int i=0; i<data_num; i++){
#pragma HLS PIPELINE II=1
		output2.write(input2.read());
	}
}
void config_collector(
		hls::stream< bit64 > & input1,
		hls::stream< bit64 > & input2,
		hls::stream< bit64 > & output1
		)
{
#pragma HLS INTERFACE axis register_mode=both register port=input1
#pragma HLS INTERFACE axis register_mode=both register port=input2
#pragma HLS INTERFACE axis register_mode=both register port=output1

	bit64 v1_buffer[256];

	for(int i=0; i<10; i++){
#pragma HLS PIPELINE II=1
		v1_buffer[i] = input1.read();
	}

	for(int i=0; i<12; i++){
#pragma HLS PIPELINE II=1
		bit64 tmp;
		tmp = v1_buffer[i] + input2.read();
		output1.write(tmp);
	}

}
