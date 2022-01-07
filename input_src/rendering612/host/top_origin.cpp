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
#include "../operators/zculling_top.h"
#include "../operators/zculling_bot.h"
#include "../operators/coloringFB_bot_m.h"
#include "../operators/coloringFB_top_m.h"


//#define PROFILE

#ifdef PROFILE
	int data_redir_m_in_1=0;
	int data_redir_m_out_1=0;
	int data_redir_m_out_2=0;
	int rasterization2_m_in_1=0;
	int rasterization2_m_in_2=0;
	int rasterization2_m_out_1=0;
	int rasterization2_m_out_2=0;
	int rasterization2_m_out_3=0;
	int rasterization2_m_out_4=0;
	int zculling_top_in_1=0;
	int zculling_top_in_2=0;
	int zculling_top_out_1=0;
	int zculling_bot_in_1=0;
	int zculling_bot_in_2=0;
	int zculling_bot_out_1=0;
	int coloringFB_top_m_in_1=0;
	int coloringFB_top_m_in_2=0;
	int coloringFB_top_m_out_1=0;
	int coloringFB_bot_m_in_1=0;
	int coloringFB_bot_m_out_1=0;
#endif
/*======================UTILITY FUNCTIONS========================*/
const int default_depth = 128;



int total_1 = 0;
int total_2 = 0;





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
	data_redir_m(Input_1, Output_redir_odd, Output_redir_even);
	data_redir_m(Input_1, Output_redir_odd, Output_redir_even);


    rasterization2_m(Output_redir_odd, Output_r2_odd_top, Output_r2_odd_bot,
    Output_redir_even, Output_r2_even_top, Output_r2_even_bot);

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

void pseudo_riscv(
		  hls::stream<ap_uint<32> > & Input_1,
		  hls::stream<ap_uint<32> > & Output_1,
		  hls::stream<ap_uint<32> > & Output_2
		)
{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1
#pragma HLS INTERFACE ap_hs port=Output_2
	ap_uint<32> in1;
	ap_uint<32> out1;
	in1 = 0;
	int tmp = 0;
	in1 = in1 + Input_1.read();
	in1 = in1 + Input_1.read();
	Output_1.write(in1);
	Output_1.write(in1);
	Output_1.write(in1);
	Output_1.write(in1);

	in1 = 0;
	in1 = in1 + Input_1.read();
	in1 = in1 + Input_1.read();
	in1 = in1 + Input_1.read();
	Output_2.write(in1);
	Output_2.write(in1);
	Output_2.write(in1);
	Output_2.write(in1);

}


void converter(
		  hls::stream<ap_uint<32> > & Input_1,
		  hls::stream<ap_uint<32> > & Input_2,
		  hls::stream<ap_uint<32> > & Output_1
		)
{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Input_2
#pragma HLS INTERFACE ap_hs port=Output_1
	ap_uint<32> in1;
	ap_uint<32> in2;
	ap_uint<32> out1;
	in1 = Input_1.read();
	in2 = Input_2.read();
	out1 = in1;
	if(in2 != 1)
	{
		Output_1.write(4096);
	}
	Output_1.write(out1);

}

void data_gen(
		  hls::stream<ap_uint<32> > & Output_1
		)

//( bit32 input[3*NUM_3D_TRI], bit32 output[NUM_FB])
{
#pragma HLS INTERFACE ap_hs port=Output_1
#include "../host/input_data.h"
    // create space for input and output
    bit32 input_tmp;
    bit32 input[3 * NUM_3D_TRI];
    bit32 output[NUM_FB];

    // pack input data for better performance
    for ( int i = 0; i < NUM_3D_TRI; i++)
    {
#pragma HLS PIPELINE
        input_tmp(7,   0) = triangle_3ds[i].x0;
        input_tmp(15,  8) = triangle_3ds[i].y0;
        input_tmp(23, 16) = triangle_3ds[i].z0;
        input_tmp(31, 24) = triangle_3ds[i].x1;
        Output_1.write(input_tmp);
        input_tmp(7,   0) = triangle_3ds[i].y1;
        input_tmp(15,  8) = triangle_3ds[i].z1;
        input_tmp(23, 16) = triangle_3ds[i].x2;
        input_tmp(31, 24) = triangle_3ds[i].y2;
        Output_1.write(input_tmp);
        input_tmp(7,   0) = triangle_3ds[i].z2;
        input_tmp(31,  8)  = 0;
        Output_1.write(input_tmp);
    }
}


void data_gen_1(
		  hls::stream<ap_uint<32> > & Output_1
		)
{
#pragma HLS INTERFACE ap_hs port=Output_1
#include "/home/ylxiao/ws_201/HLS/rendering/data_gen.h"
	for(int i=0; i<9576; i++){
#pragma HLS PIPELINE
		Output_1.write(data_gen_data[i]);
	}
}

#define USER_WIDTH 64

void user_kernel(
		  hls::stream<ap_uint<USER_WIDTH> > & Input_1,
		  hls::stream<ap_uint<USER_WIDTH> > & Output_1
		)

{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1
		Output_1.write(Input_1.read()+5);
}

void user_fifo(
		  hls::stream<ap_uint<32> > & Input_1,
		  hls::stream<ap_uint<32> > & Output_1
		)

{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1
		int i;
		int tmp[16];
		for (i=0; i<16; i++)
		{
			tmp[i] = Input_1.read();
			Output_1.write(tmp[i]);
		}
}



