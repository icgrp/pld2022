#include "top.h"

#include "../operators/flow_calc_1.h"
#include "../operators/flow_calc_2.h"
#include "../operators/gradient_weight_x1.h"
#include "../operators/gradient_weight_x2.h"
#include "../operators/gradient_weight_x3.h"
#include "../operators/gradient_weight_y_1.h"
#include "../operators/gradient_weight_y_2.h"
#include "../operators/gradient_weight_y_3.h"
#include "../operators/gradient_xyz_calc.h"
#include "../operators/outer_product1.h"
#include "../operators/outer_product2.h"
#include "../operators/output_fun.h"
#include "../operators/tensor_weight_x1.h"
#include "../operators/tensor_weight_x2.h"
#include "../operators/tensor_weight_y1.h"
#include "../operators/tensor_weight_y2.h"
#include "../operators/data_transfer.h"

void top(hls::stream< ap_uint<512> > &Input_1,
		 hls::stream< ap_uint<512> > &Output_1)
{

#pragma HLS interface ap_hs port=Input_1
#pragma HLS interface ap_hs port=Output_1
  #pragma HLS DATAFLOW

  // FIFOs connecting the stages

  //static pixel_t gradient_x[MAX_HEIGHT][MAX_WIDTH];
  static hls::stream<databus_t> gradient_x;
  #pragma HLS STREAM variable=gradient_x depth=default_depth

  //static pixel_t gradient_y[MAX_HEIGHT][MAX_WIDTH];
  static hls::stream<databus_t> gradient_y;
  #pragma HLS STREAM variable=gradient_y depth=default_depth

  //static pixel_t gradient_z[MAX_HEIGHT][MAX_WIDTH];
  static hls::stream<databus_t> gradient_z;
  #pragma HLS STREAM variable=gradient_z depth=max_width*4

  //static gradient_t y_filtered[MAX_HEIGHT][MAX_WIDTH];
  //#pragma HLS STREAM variable=y_filtered depth=default_depth
  static hls::stream<databus_t> y_filtered_x;
  static hls::stream<databus_t> y_filtered_y;
  static hls::stream<databus_t> y_filtered_z;
  #pragma HLS STREAM variable=y_filtered_x depth=default_depth
  #pragma HLS STREAM variable=y_filtered_y depth=default_depth
  #pragma HLS STREAM variable=y_filtered_z depth=default_depth

  //static gradient_t filtered_gradient[MAX_HEIGHT][MAX_WIDTH];
  //#pragma HLS STREAM variable=filtered_gradient depth=default_depth
  static hls::stream<databus_t> filtered_gradient_x1;
  static hls::stream<databus_t> filtered_gradient_y1;
  static hls::stream<databus_t> filtered_gradient_z1;
  #pragma HLS STREAM variable=filtered_gradient_x1 depth=default_depth
  #pragma HLS STREAM variable=filtered_gradient_y1 depth=default_depth
  #pragma HLS STREAM variable=filtered_gradient_z1 depth=default_depth

  static hls::stream<databus_t> filtered_gradient_x2;
  static hls::stream<databus_t> filtered_gradient_y2;
  static hls::stream<databus_t> filtered_gradient_z2;
  #pragma HLS STREAM variable=filtered_gradient_x2 depth=default_depth
  #pragma HLS STREAM variable=filtered_gradient_y2 depth=default_depth
  #pragma HLS STREAM variable=filtered_gradient_z2 depth=default_depth

  static hls::stream< ap_uint<160> > out_product1;
  #pragma HLS STREAM variable=out_product1 depth=default_depth
  static hls::stream< ap_uint<160> > out_product2;
  #pragma HLS STREAM variable=out_product2 depth=default_depth
  static hls::stream< ap_uint<160> > tensor_y1;
  #pragma HLS STREAM variable=tensor_y1 depth=default_depth
  static hls::stream< ap_uint<160> > tensor_y2;
  #pragma HLS STREAM variable=tensor_y2 depth=default_depth
  static hls::stream< ap_uint<160> > tx1_out;
  #pragma HLS STREAM variable=tx1_out depth=default_depth
  static hls::stream< ap_uint<160> > tx2_out;
  #pragma HLS STREAM variable=tx2_out depth=default_depth
  static hls::stream< ap_uint<160> > tx1_out1;
  #pragma HLS STREAM variable=tx1_out1 depth=default_depth
  static hls::stream< ap_uint<160> > tx2_out1;
  #pragma HLS STREAM variable=tx2_out1 depth=default_depth

  static hls::stream<databus_t> out_product1a;
  #pragma HLS STREAM variable=out_product1a depth=default_depth
  static hls::stream<databus_t> out_product2a;
  #pragma HLS STREAM variable=out_product2a depth=default_depth
  static hls::stream<databus_t> tensor_y1a;
  #pragma HLS STREAM variable=tensor_y1a depth=default_depth
  static hls::stream<databus_t> tensor_y2a;
  #pragma HLS STREAM variable=tensor_y2a depth=default_depth
  static hls::stream<databus_t> tx1_outa;
  #pragma HLS STREAM variable=tx1_outa depth=default_depth
  static hls::stream<databus_t> tx2_outa;
  #pragma HLS STREAM variable=tx2_outa depth=default_depth
  static hls::stream<databus_t> tx1_out1a;
  #pragma HLS STREAM variable=tx1_out1a depth=default_depth
  static hls::stream<databus_t> tx2_out1a;
  #pragma HLS STREAM variable=tx2_out1a depth=default_depth

  static hls::stream<databus_t> frame3_a;
  #pragma HLS STREAM variable=frame3_a depth=default_depth
  static hls::stream<databus_t> frame1_a;
  #pragma HLS STREAM variable=frame1_a depth=default_depth
  static hls::stream<databus_t> frame2_a;
  #pragma HLS STREAM variable=frame2_a depth=default_depth
  static hls::stream<databus_t> frame3_b;
  #pragma HLS STREAM variable=frame3_b depth=default_depth
  static hls::stream<databus_t> frame4_a;
  #pragma HLS STREAM variable=frame4_a depth=default_depth
  static hls::stream<databus_t> frame5_a;
  #pragma HLS STREAM variable=frame5_a depth=default_depth
//  static input_t frame3_b[MAX_HEIGHT][MAX_WIDTH];
//  #pragma HLS STREAM variable=frame3_b depth=default_depth
  static hls::stream<stdio_t> in;
  #pragma HLS STREAM variable=in depth=default_depth
  static hls::stream<stdio_t> in1;
  #pragma HLS STREAM variable=in1 depth=default_depth
  // stream in and organize the inputs
  //

  static hls::stream< bit64 > tran_out;


  data_transfer(Input_1, tran_out);

  gradient_xyz_calc(tran_out, gradient_x, gradient_y,gradient_z);
  gradient_weight_y_1(gradient_x, y_filtered_x);
  gradient_weight_y_2(gradient_y, y_filtered_y);
  gradient_weight_y_3(gradient_z, y_filtered_z);
  gradient_weight_x1(y_filtered_x,filtered_gradient_x1,filtered_gradient_x2);
  gradient_weight_x2(y_filtered_y,
		     filtered_gradient_y1,
	             filtered_gradient_y2); // 32 * 3 + 32 * 3
  gradient_weight_x3(y_filtered_z,
		     filtered_gradient_z1,
	            filtered_gradient_z2); // 32 * 3 + 32 * 3
  outer_product1(filtered_gradient_x1, filtered_gradient_y1, filtered_gradient_z1, out_product1); // 32 * 3 + 3 * 48
  outer_product2(filtered_gradient_x2, filtered_gradient_y2, filtered_gradient_z2, out_product2); // 32 * 3 + 3 * 48
  tensor_weight_y1(out_product1,tensor_y1); // 6 * 48 + 6 * 48
  tensor_weight_y2(out_product2,tensor_y2); // 6 * 48 + 6 * 48
  tensor_weight_x1(tensor_y1,
		   tx1_out,tx1_out1); // 6 * 48 + 6 * 48
  tensor_weight_x2(tensor_y2,
		   tx2_out,tx2_out1); // 6 * 48 + 6 * 48
  flow_calc_1(tx1_out, tx2_out, in); // 6 * 48 + 32 * 2
  flow_calc_2(tx1_out1, tx2_out1,in1); // 6 * 48 + 32 * 2
  output_fun(in,in1,Output_1);
  printf("sbbbbb\n");
}


void data_gen(
		 hls::stream< ap_uint<512> > &Output_1)
{
#pragma HLS interface ap_hs port=Output_1


#include "./input_data.h"
#pragma HLS ARRAY_PARTITION variable=input_data cyclic factor=2 dim=1

	int i;
	bit512 tmp;
	for (i=0; i<446464/8; i++)
	{
#pragma HLS pipeline II=1
		for(int j=0; j<8; j++){
			tmp(j*64+63,j*64+32) = input_data[(i*8+j)*2];
			tmp(j*64+31,j*64+0 ) = input_data[(i*8+j)*2+1];
		}
		Output_1.write(tmp);
	}
}


