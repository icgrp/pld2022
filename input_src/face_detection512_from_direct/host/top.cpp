/*===============================================================*/
/*                                                               */
/*                      face_detect.cpp                          */
/*                                                               */
/*     Hardware function for the Face Detection application.     */
/*                                                               */
/*===============================================================*/

#include "../host/typedefs.h"
#include "../operators/imageScaler_top.h"
#include "../operators/imageScaler_bot.h"
#include "../operators/sfilter0.h"
#include "../operators/sfilter1.h"
#include "../operators/sfilter2.h"
#include "../operators/sfilter3.h"
#include "../operators/sfilter4.h"

#include "../operators/wfilter0.h"
#include "../operators/wfilter1.h"
#include "../operators/wfilter2.h"
#include "../operators/wfilter3.h"
#include "../operators/wfilter4.h"

#include "../operators/wfilter0_process.h"
#include "../operators/wfilter1_process.h"
#include "../operators/wfilter2_process.h"
#include "../operators/wfilter3_process.h"
#include "../operators/wfilter4_process.h"

#include "../operators/weak_data_req_simple.h"
#include "../operators/strong_classifier.h"
#include "../operators/weak_process_new.h"
static  int stages_array[25] = {
9,16,27,32,52,53,62,72,83,91,99,115,127,135,136,137,159,155,169,196,197,181,199,211,200
};

static int  myRound ( float value )
{
  return (int)(value + (value >= 0 ? 0.5 : -0.5));
}

void data_gen
(
  hls::stream<ap_uint<512> > & Output_1
)
{
#pragma HLS INTERFACE ap_hs port=Output_1
	int i, j, k;
#include "../host/image0_320_240.h"
#pragma HLS ARRAY_PARTITION variable=Data cyclic factor=16 dim=0

	GEN_1:for ( i = 0; i < IMAGE_HEIGHT; i ++ )
	{
		GEN_2: for( j = 0; j < IMAGE_WIDTH/64; j++)
		{
#pragma HLS PIPELINE II=1
			bit512 Input_tmp;
			GEN_3: for (k=0; k<64; k++){
#pragma HLS UNROLL
				Input_tmp(k*8+7, k*8) = Data[i][j*64+k];
			}
			Output_1.write(Input_tmp);
		}

	}

}



//========================================================================================
// TOP LEVEL MODULE OR DUT (DEVICE UNDER TEST) 
//========================================================================================
void top

(
  hls::stream<ap_uint<512> > & Input_1,
  hls::stream<ap_uint<512> > & Output_1
)
{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1

	int i, j;

	int result_x_Scale[RESULT_SIZE];
	int result_y_Scale[RESULT_SIZE];
	int result_w_Scale[RESULT_SIZE];
	int result_h_Scale[RESULT_SIZE];
	int res_size_Scale = 0;
	int *result_size_Scale = &res_size_Scale;

	float  scaleFactor = 1.2;




	unsigned char IMG1_data[IMAGE_HEIGHT][IMAGE_WIDTH];
	static int AllCandidates_x[RESULT_SIZE];
	static int AllCandidates_y[RESULT_SIZE];
	static int AllCandidates_w[RESULT_SIZE];
	static int AllCandidates_h[RESULT_SIZE];
	int height, width;

	/** Integral Image Window buffer ( 625 registers )*/
	static int_II II[WINDOW_SIZE+1][WINDOW_SIZE];
	#pragma HLS array_partition variable=II complete dim=0
	static int ss[52];
	#pragma HLS array_partition variable=ss complete dim=0


	/** Square Integral Image Window buffer ( 625 registers )*/
	static int_SII SII[SQ_SIZE][SQ_SIZE];
	#pragma HLS array_partition variable=SII complete dim=0
	static float factor=1.2;



	hls::stream<ap_uint<32> > scaler_top_out("top");
	hls::stream<ap_uint<32> > scaler_bot_out_1("bot1");
	hls::stream<ap_uint<32> > scaler_bot_out_2("bot2");

	hls::stream<ap_uint<32> > Input_1_process_II_SII;
	hls::stream<ap_uint<32> > Output_1_process_II_SII;
	hls::stream<ap_uint<32> > Input_1_p4("ip41");

	hls::stream<ap_uint<128> > Output_1_p4("p41");
	hls::stream<ap_uint<32> > Output_2_p4("p42");

	hls::stream<ap_uint<128> > Output_1_p3("p31");
	hls::stream<ap_uint<32> > Output_2_p3("p32");
	hls::stream<ap_uint<32> > Output_3_p3("p33");

	hls::stream<ap_uint<128> > Output_1_p2("p21");
	hls::stream<ap_uint<32> > Output_2_p2("p22");
	hls::stream<ap_uint<32> > Output_3_p2("p23");

	hls::stream<ap_uint<128> > Output_1_p1("p11");
	hls::stream<ap_uint<32> > Output_2_p1("p12");
	hls::stream<ap_uint<32> > Output_3_p1("p13");

	hls::stream<ap_uint<128> > Output_1_p0("p01");
	hls::stream<ap_uint<32> > Output_2_p0("p02");

	hls::stream<ap_uint<32> > Input_1_p4_weak("ip41_weak");

	hls::stream<ap_uint<128> > Output_1_p4_weak("p41_weak");
	hls::stream<ap_uint<32> > Output_2_p4_weak("p42_weak");

	hls::stream<ap_uint<128> > Output_1_p3_weak("p31_weak");
	hls::stream<ap_uint<32> > Output_2_p3_weak("p32_weak");
	hls::stream<ap_uint<32> > Output_3_p3_weak("p33_weak");

	hls::stream<ap_uint<128> > Output_1_p2_weak("p21_weak");
	hls::stream<ap_uint<32> > Output_2_p2_weak("p22_weak");
	hls::stream<ap_uint<32> > Output_3_p2_weak("p23_weak");

	hls::stream<ap_uint<128> > Output_1_p1_weak("p11_weak");
	hls::stream<ap_uint<32> > Output_2_p1_weak("p12_weak");
	hls::stream<ap_uint<32> > Output_3_p1_weak("p13_weak");

	hls::stream<ap_uint<128> > Output_1_p0_weak("p01_weak");
	hls::stream<ap_uint<32> > Output_2_p0_weak("p02_weak");

	hls::stream<ap_uint<32> > weak_data_req_in("sb1");
	hls::stream<ap_uint<32> > weak_data_req_out("sb2");
	hls::stream<ap_uint<32> > weak_process_in("sb3");
	hls::stream<ap_uint<32> > weak_process_out("sb4");
	hls::stream<ap_uint<32> > Input_noface("noface");
	hls::stream<ap_uint<128> > cmd_1("cmd1");
	hls::stream<ap_uint<128> > cmd_2("cmd2");
	hls::stream<ap_uint<128> > cmd_3("cmd3");
	hls::stream<ap_uint<128> > cmd_4("cmd4");
	hls::stream<ap_uint<128> > cmd_5("cmd5");
	hls::stream<ap_uint<32> > Output_1_imgscl;
	hls::stream<ap_uint<32> > Output_1_strong_classifier("str_cls");

	hls::stream<ap_uint<32> > Output_1_wfilter0_process("wp0");
	hls::stream<ap_uint<32> > Output_1_wfilter1_process("wp1");
	hls::stream<ap_uint<32> > Output_1_wfilter2_process("wp2");
	hls::stream<ap_uint<32> > Output_1_wfilter3_process("wp3");
	hls::stream<ap_uint<32> > Output_1_wfilter4_process("wp4");



	MySize winSize0;
	winSize0.width = 24;
	winSize0.height= 24;

	factor = scaleFactor ;


	imageScaler_top(Input_1, scaler_top_out);




	imageScaler_bot (scaler_top_out, scaler_bot_out_1,scaler_bot_out_2);


	int sb = 0;
	L1:
	//while ( IMAGE_WIDTH/factor > WINDOW_SIZE && IMAGE_HEIGHT/factor > WINDOW_SIZE )
	while(sb < 12)
	{
		printf("frame=%d\n", sb);

		unsigned char data_in;
		MyPoint p;
		int result;
		int step;
		MySize winSize;
		int u,v;
		int x,y,i,j,k;
		float scaleFactor = 1.2;
		int x_index = 0;
		int y_index = 0;
		int ii, jj;
		int element_counter;

		/////////////ctro instructions
		MySize winSize0;
		winSize0.width = 24;
		winSize0.height= 24;
		int width=0;
		int height=0;

		sb++;
		if( IMAGE_WIDTH/factor > WINDOW_SIZE && IMAGE_HEIGHT/factor > WINDOW_SIZE )
		{
		  winSize.width = myRound(winSize0.width*factor);
		  winSize.height= myRound(winSize0.height*factor);
		  MySize sz = { (int)( IMAGE_WIDTH/factor ), (int)( IMAGE_HEIGHT/factor ) };
		  height = sz.height;
		  width  = sz.width;
		}


		/////////////ctro instructions end


		element_counter = 0;
		/** Loop over each point in the Image ( scaled ) **/
		Pixely: for( y = 0; y < height; y++ ){
		  Pixelx : for ( x = 0; x < width; x++ ){

			sfilter4(scaler_bot_out_1, Output_3_p3, Output_1_p4, Output_2_p4);
			sfilter3(Output_2_p4, Output_3_p2, Output_1_p3, Output_2_p3, Output_3_p3);
			sfilter2(Output_2_p3, Output_3_p1, Output_1_p2, Output_2_p2, Output_3_p2);
			sfilter1(Output_2_p2, Output_2_p0, Output_1_p1, Output_2_p1, Output_3_p1);
			sfilter0(Output_2_p1, Output_1_p0, Output_2_p0);

			sfilter4(scaler_bot_out_1, Output_3_p3, Output_1_p4, Output_2_p4);
			sfilter3(Output_2_p4, Output_3_p2, Output_1_p3, Output_2_p3, Output_3_p3);
			sfilter2(Output_2_p3, Output_3_p1, Output_1_p2, Output_2_p2, Output_3_p2);
			sfilter1(Output_2_p2, Output_2_p0, Output_1_p1, Output_2_p1, Output_3_p1);
			sfilter0(Output_2_p1, Output_1_p0, Output_2_p0);

			sfilter0(Output_2_p1, Output_1_p0, Output_2_p0);
			sfilter1(Output_2_p2, Output_2_p0, Output_1_p1, Output_2_p1, Output_3_p1);
			sfilter2(Output_2_p3, Output_3_p1, Output_1_p2, Output_2_p2, Output_3_p2);
			sfilter3(Output_2_p4, Output_3_p2, Output_1_p3, Output_2_p3, Output_3_p3);
			sfilter4(scaler_bot_out_1, Output_3_p3, Output_1_p4, Output_2_p4);


			wfilter4(scaler_bot_out_2, Output_3_p3_weak, cmd_5, Output_1_p4_weak, Output_2_p4_weak);
			wfilter3(Output_2_p4_weak, Output_3_p2_weak, cmd_4, Output_1_p3_weak, Output_2_p3_weak, Output_3_p3_weak);
			wfilter2(Output_2_p3_weak, Output_3_p1_weak, cmd_3, Output_1_p2_weak, Output_2_p2_weak, Output_3_p2_weak);
			wfilter1(Output_2_p2_weak, Output_2_p0_weak, cmd_2, Output_1_p1_weak, Output_2_p1_weak, Output_3_p1_weak);
			wfilter0(Output_2_p1_weak, cmd_1, Output_1_p0_weak, Output_2_p0_weak);


			wfilter4(scaler_bot_out_2, Output_3_p3_weak, cmd_5, Output_1_p4_weak, Output_2_p4_weak);
			wfilter3(Output_2_p4_weak, Output_3_p2_weak, cmd_4, Output_1_p3_weak, Output_2_p3_weak, Output_3_p3_weak);
			wfilter2(Output_2_p3_weak, Output_3_p1_weak, cmd_3, Output_1_p2_weak, Output_2_p2_weak, Output_3_p2_weak);
			wfilter1(Output_2_p2_weak, Output_2_p0_weak, cmd_2, Output_1_p1_weak, Output_2_p1_weak, Output_3_p1_weak);
			wfilter0(Output_2_p1_weak, cmd_1, Output_1_p0_weak, Output_2_p0_weak);


			wfilter0(Output_2_p1_weak, cmd_1, Output_1_p0_weak, Output_2_p0_weak);
			wfilter1(Output_2_p2_weak, Output_2_p0_weak, cmd_2, Output_1_p1_weak, Output_2_p1_weak, Output_3_p1_weak);
			wfilter2(Output_2_p3_weak, Output_3_p1_weak, cmd_3, Output_1_p2_weak, Output_2_p2_weak, Output_3_p2_weak);
			wfilter3(Output_2_p4_weak, Output_3_p2_weak, cmd_4, Output_1_p3_weak, Output_2_p3_weak, Output_3_p3_weak);
			wfilter4(scaler_bot_out_2, Output_3_p3_weak, cmd_5, Output_1_p4_weak, Output_2_p4_weak);
			weak_process_new(
					Input_noface,
				Output_1_wfilter0_process,
				Output_1_wfilter1_process,
				Output_1_wfilter2_process,
				Output_1_wfilter3_process,
				Output_1_wfilter4_process,
				Output_1,
				weak_data_req_in
				);


			if ( element_counter >= ( ( (WINDOW_SIZE-1)*width + WINDOW_SIZE ) + WINDOW_SIZE -1 ) ) {
				if ( x_index < ( width - (WINDOW_SIZE-1) ) && y_index < ( height - (WINDOW_SIZE-1) ) ){
					p.x = x_index;
					p.y = y_index;

					int noface = 0;
					strong_classifier(Output_1_p0,
									Output_1_p1,
									Output_1_p2,
									Output_1_p3,
									Output_1_p4,
									Output_1_strong_classifier);

					noface = Output_1_strong_classifier.read();
					Input_noface.write(noface);
					weak_process_new(
							Input_noface,
						Output_1_wfilter0_process,
						Output_1_wfilter1_process,
						Output_1_wfilter2_process,
						Output_1_wfilter3_process,
						Output_1_wfilter4_process,
						Output_1,
						weak_data_req_in
						);

					if(noface){
						result = -1;
						weak_data_req_simple(weak_data_req_in, cmd_1, cmd_2, cmd_3, cmd_4, cmd_5);
						wfilter0(Output_2_p1_weak, cmd_1, Output_1_p0_weak, Output_2_p0_weak);
						wfilter1(Output_2_p2_weak, Output_2_p0_weak, cmd_2, Output_1_p1_weak, Output_2_p1_weak, Output_3_p1_weak);
						wfilter2(Output_2_p3_weak, Output_3_p1_weak, cmd_3, Output_1_p2_weak, Output_2_p2_weak, Output_3_p2_weak);
						wfilter3(Output_2_p4_weak, Output_3_p2_weak, cmd_4, Output_1_p3_weak, Output_2_p3_weak, Output_3_p3_weak);
						wfilter4(scaler_bot_out_2, Output_3_p3_weak, cmd_5, Output_1_p4_weak, Output_2_p4_weak);

					}else{
					//result = cascadeClassifier_decomp (II, SII);
						int move_i, move_j;
						move_i = 3;
						for(move_i = 3; move_i < 25; move_i++){

							weak_process_new(
									Input_noface,
								Output_1_wfilter0_process,
								Output_1_wfilter1_process,
								Output_1_wfilter2_process,
								Output_1_wfilter3_process,
								Output_1_wfilter4_process,
								Output_1,
								weak_data_req_in
								);

							weak_data_req_simple(weak_data_req_in, cmd_1, cmd_2, cmd_3, cmd_4, cmd_5);
							for ( j = 0; j < stages_array[move_i] ; j++ ){

								wfilter0(Output_2_p1_weak, cmd_1, Output_1_p0_weak, Output_2_p0_weak);
								wfilter1(Output_2_p2_weak, Output_2_p0_weak, cmd_2, Output_1_p1_weak, Output_2_p1_weak, Output_3_p1_weak);
								wfilter2(Output_2_p3_weak, Output_3_p1_weak, cmd_3, Output_1_p2_weak, Output_2_p2_weak, Output_3_p2_weak);
								wfilter3(Output_2_p4_weak, Output_3_p2_weak, cmd_4, Output_1_p3_weak, Output_2_p3_weak, Output_3_p3_weak);
								wfilter4(scaler_bot_out_2, Output_3_p3_weak, cmd_5, Output_1_p4_weak, Output_2_p4_weak);
								wfilter0_process(Output_1_p0_weak, Output_1_wfilter0_process);
								wfilter1_process(Output_1_p1_weak, Output_1_wfilter1_process);
								wfilter2_process(Output_1_p2_weak, Output_1_wfilter2_process);
								wfilter3_process(Output_1_p3_weak, Output_1_wfilter3_process);
								wfilter4_process(Output_1_p4_weak, Output_1_wfilter4_process);
							}

							weak_process_new(
									Input_noface,
								Output_1_wfilter0_process,
								Output_1_wfilter1_process,
								Output_1_wfilter2_process,
								Output_1_wfilter3_process,
								Output_1_wfilter4_process,
								Output_1,
								weak_data_req_in
								);
							result = FIRST;
							if(result<0){
								break;
							}
						}

						weak_data_req_simple(weak_data_req_in, cmd_1, cmd_2, cmd_3, cmd_4, cmd_5);
						wfilter0(Output_2_p1_weak, cmd_1, Output_1_p0_weak, Output_2_p0_weak);
						wfilter1(Output_2_p2_weak, Output_2_p0_weak, cmd_2, Output_1_p1_weak, Output_2_p1_weak, Output_3_p1_weak);
						wfilter2(Output_2_p3_weak, Output_3_p1_weak, cmd_3, Output_1_p2_weak, Output_2_p2_weak, Output_3_p2_weak);
						wfilter3(Output_2_p4_weak, Output_3_p2_weak, cmd_4, Output_1_p3_weak, Output_2_p3_weak, Output_3_p3_weak);
						wfilter4(scaler_bot_out_2, Output_3_p3_weak, cmd_5, Output_1_p4_weak, Output_2_p4_weak);

					}
				}else{

					weak_data_req_simple(weak_data_req_in, cmd_1, cmd_2, cmd_3, cmd_4, cmd_5);
					wfilter0(Output_2_p1_weak, cmd_1, Output_1_p0_weak, Output_2_p0_weak);
					wfilter1(Output_2_p2_weak, Output_2_p0_weak, cmd_2, Output_1_p1_weak, Output_2_p1_weak, Output_3_p1_weak);
					wfilter2(Output_2_p3_weak, Output_3_p1_weak, cmd_3, Output_1_p2_weak, Output_2_p2_weak, Output_3_p2_weak);
					wfilter3(Output_2_p4_weak, Output_3_p2_weak, cmd_4, Output_1_p3_weak, Output_2_p3_weak, Output_3_p3_weak);
					wfilter4(scaler_bot_out_2, Output_3_p3_weak, cmd_5, Output_1_p4_weak, Output_2_p4_weak);

				}
				if ( x_index < width-1 )
				   x_index = x_index + 1;
				else{
				   x_index = 0;
				   y_index = y_index + 1;
				}
			 }else{

				weak_data_req_simple(weak_data_req_in, cmd_1, cmd_2, cmd_3, cmd_4, cmd_5);
				wfilter0(Output_2_p1_weak, cmd_1, Output_1_p0_weak, Output_2_p0_weak);
				wfilter1(Output_2_p2_weak, Output_2_p0_weak, cmd_2, Output_1_p1_weak, Output_2_p1_weak, Output_3_p1_weak);
				wfilter2(Output_2_p3_weak, Output_3_p1_weak, cmd_3, Output_1_p2_weak, Output_2_p2_weak, Output_3_p2_weak);
				wfilter3(Output_2_p4_weak, Output_3_p2_weak, cmd_4, Output_1_p3_weak, Output_2_p3_weak, Output_3_p3_weak);
				wfilter4(scaler_bot_out_2, Output_3_p3_weak, cmd_5, Output_1_p4_weak, Output_2_p4_weak);

			 }

			 element_counter +=1;
		  }
		}

		factor *= scaleFactor;
		if( IMAGE_WIDTH/factor < WINDOW_SIZE || IMAGE_HEIGHT/factor < WINDOW_SIZE )
		{
			factor = 1.2;
		}


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
          for(int i=0; i<config_size; i++){ output1[i] = v1_buffer[i]; }

	  for(int i=0; i<input_size;  i++){ 
            bit512 in_tmp = input2[i];
            Input_1.write(in_tmp);
          }
	  
          top(Input_1, Output_1);
 
          for(int i=0; i<output_size; i++){ 
            bit512 out_tmp;
            out_tmp = Output_1.read();
            output2[i] = out_tmp;
	  }

	}

}
