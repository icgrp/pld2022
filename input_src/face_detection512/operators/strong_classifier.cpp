#include "../host/typedefs.h"

static  int stages_thresh_array[25] = {
-1290,-1275,-1191,-1140,-1122,-1057,-1029,-994,-983,-933,-990,-951,-912,-947,-877,-899,-920,-868,-829,-821,-839,-849,-833,-862,-766
};


static unsigned int int_sqrt 
( 
  ap_uint<32> value
)
{
  int i;
  unsigned int a = 0, b = 0, c = 0;

  for ( i = 0 ; i < (32 >> 1) ; i++ )
  {
    #pragma HLS unroll
    c<<= 2;   
    #define UPPERBITS(value) (value>>30)
    c += UPPERBITS(value);
    #undef UPPERBITS
    value = value<<2;
    a <<= 1;
    b = (a<<1) | 1;
    if ( c >= b )
    {
      c -= b;
      a++;
    }
  }
  return a;
}


void strong_classifier

(
  hls::stream<ap_uint<704> > & Input_1,
  hls::stream<ap_uint<640> > & Input_2,
  hls::stream<ap_uint<640> > & Input_3,
  hls::stream<ap_uint<640> > & Input_4,
  hls::stream<ap_uint<704> > & Input_5,
  hls::stream<ap_uint<32> > & Output_1
)
{
//#pragma HLS DATAFLOW
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Input_3
#pragma HLS INTERFACE axis register port=Input_4
#pragma HLS INTERFACE axis register port=Input_5
#pragma HLS INTERFACE axis register port=Output_1

  static int res_size_Scale = 0;
  unsigned char data_in;
  MyPoint p;
  int result;
  int step;
  MySize winSize;
  int u,v;
  int i,j,k;
  static float factor=1.2;
  float scaleFactor = 1.2;
  static int x = 0;
  static int y = 0;
  static MySize winSize0 = {24, 24};
  static int width=0;
  static int height=0;


  static unsigned char L_4[4][IMAGE_WIDTH]= {0};
  #pragma HLS array_partition variable=L_4 complete dim=1


  static int_I I_4[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=I_4 complete dim=0

  /** Integral Image Window buffer ( 625 registers )*/
  static int_II II_4[5][WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=II_4 complete dim=0

  static int_SI SI_4[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=SI_4 complete dim=0


  static int ss[52];
  #pragma HLS array_partition variable=ss complete dim=0


  static int element_counter = 0;
  static int x_index = 0;
  static int y_index = 0;
  /** Square Integral Image Window buffer ( 625 registers )*/
  static int_SII SII[SQ_SIZE][SQ_SIZE]= {0};
  #pragma HLS array_partition variable=SII complete dim=0

  int stddev = 0;
  int mean = 0;
  ap_uint<704> in_tmp1;
  ap_uint<640> in_tmp2;
  ap_uint<640> in_tmp3;
  ap_uint<640> in_tmp4;
  ap_uint<704> in_tmp5;
  in_tmp1 = Input_1.read();
  in_tmp2 = Input_2.read();
  in_tmp3 = Input_3.read();
  in_tmp4 = Input_4.read();
  in_tmp5 = Input_5.read();

  stddev = (int)in_tmp1(31,0) + (int)in_tmp5(31,0);

  mean = (int)in_tmp1(63,32) + (int)in_tmp5(63,32);

  stddev = (stddev*(WINDOW_SIZE-1)*(WINDOW_SIZE-1));
  stddev =  stddev - mean*mean;

  if( stddev > 0 )
    stddev = int_sqrt(stddev);
  else
    stddev = 1;


  int final_sum[52]={0};
	#pragma HLS array_partition variable=final_sum complete dim=0

  ap_int<12> sum_tmp[5][60]={0};
#pragma HLS array_partition variable=sum_tmp complete dim=0

    for(i=0; i<52; i++){
#pragma HLS unroll
	  sum_tmp[0][i] = (ap_int<12>)in_tmp1(i*12+75,i*12+64);
	  sum_tmp[1][i] = (ap_int<12>)in_tmp2(i*12+11,i*12);
	  sum_tmp[2][i] = (ap_int<12>)in_tmp3(i*12+11,i*12);
	  sum_tmp[3][i] = (ap_int<12>)in_tmp4(i*12+11,i*12);
	  sum_tmp[4][i] = (ap_int<12>)in_tmp5(i*12+75,i*12+64);
    }



  for(i=0; i<52; i++){
	#pragma HLS unroll
	  final_sum[i] = 0;
	  final_sum[i] = 0;
	  final_sum[i] = 0;
	  final_sum[i] = 0;
	  final_sum[i] = 0;
  }


  for(i=0; i<52; i++){
	#pragma HLS unroll
	  final_sum[i] = final_sum[i]+((int)sum_tmp[0][i])*1048576;
	  final_sum[i] = final_sum[i]+((int)sum_tmp[1][i])*1048576;
	  final_sum[i] = final_sum[i]+((int)sum_tmp[2][i])*1048576;
	  final_sum[i] = final_sum[i]+((int)sum_tmp[3][i])*1048576;
	  final_sum[i] = final_sum[i]+((int)sum_tmp[4][i])*1048576;
  }

  //classifier0
    if(final_sum[0]>= (-129 * stddev))
       ss[0] = -567;
    else
       ss[0] = 534;

  //classifier1
    if(final_sum[1]>= (50 * stddev))
       ss[1] = 339;
    else
       ss[1] = -477;

  //classifier2
    if(final_sum[2]>= (89 * stddev))
       ss[2] = 272;
    else
       ss[2] = -386;

  //classifier3
    if(final_sum[3]>= (23 * stddev))
       ss[3] = 301;
    else
       ss[3] = -223;

  //classifier4
    if(final_sum[4]>= (61 * stddev))
       ss[4] = 322;
    else
       ss[4] = -199;

  //classifier5
    if(final_sum[5]>= (407 * stddev))
       ss[5] = -479;
    else
       ss[5] = 142;

  //classifier6
    if(final_sum[6]>= (11 * stddev))
       ss[6] = 112;
    else
       ss[6] = -432;

  //classifier7
    if(final_sum[7]>= (-77 * stddev))
       ss[7] = 113;
    else
       ss[7] = -378;

  //classifier8
    if(final_sum[8]>= (24 * stddev))
       ss[8] = 218;
    else
       ss[8] = -219;

  //classifier9
    if(final_sum[9]>= (-86 * stddev))
       ss[9] = -402;
    else
       ss[9] = 318;

  //classifier10
    if(final_sum[10]>= (83 * stddev))
       ss[10] = 302;
    else
       ss[10] = -414;

  //classifier11
    if(final_sum[11]>= (87 * stddev))
       ss[11] = 179;
    else
       ss[11] = -497;

  //classifier12
    if(final_sum[12]>= (375 * stddev))
       ss[12] = 442;
    else
       ss[12] = -142;

  //classifier13
    if(final_sum[13]>= (148 * stddev))
       ss[13] = -558;
    else
       ss[13] = 68;

  //classifier14
    if(final_sum[14]>= (-78 * stddev))
       ss[14] = 116;
    else
       ss[14] = -684;

  //classifier15
    if(final_sum[15]>= (33 * stddev))
       ss[15] = 137;
    else
       ss[15] = -277;

  //classifier16
    if(final_sum[16]>= (75 * stddev))
       ss[16] = 238;
    else
       ss[16] = -90;

  //classifier17
    if(final_sum[17]>= (-28 * stddev))
       ss[17] = -169;
    else
       ss[17] = 237;

  //classifier18
    if(final_sum[18]>= (-40 * stddev))
       ss[18] = -76;
    else
       ss[18] = 296;

  //classifier19
    if(final_sum[19]>= (64 * stddev))
       ss[19] = 347;
    else
       ss[19] = -107;

  //classifier20
    if(final_sum[20]>= (-84 * stddev))
       ss[20] = -50;
    else
       ss[20] = 373;

  //classifier21
    if(final_sum[21]>= (-563 * stddev))
       ss[21] = -135;
    else
       ss[21] = 286;

  //classifier22
    if(final_sum[22]>= (58 * stddev))
       ss[22] = 292;
    else
       ss[22] = -89;

  //classifier23
    if(final_sum[23]>= (41 * stddev))
       ss[23] = 197;
    else
       ss[23] = -155;

  //classifier24
    if(final_sum[24]>= (374 * stddev))
       ss[24] = -387;
    else
       ss[24] = 99;

  //classifier25
    if(final_sum[25]>= (285 * stddev))
       ss[25] = 375;
    else
       ss[25] = -259;

  //classifier26
    if(final_sum[26]>= (129 * stddev))
       ss[26] = 256;
    else
       ss[26] = -421;

  //classifier27
    if(final_sum[27]>= (58 * stddev))
       ss[27] = -408;
    else
       ss[27] = 118;

  //classifier28
    if(final_sum[28]>= (59 * stddev))
       ss[28] = 212;
    else
       ss[28] = -167;

  //classifier29
    if(final_sum[29]>= (-12 * stddev))
       ss[29] = 108;
    else
       ss[29] = -357;

  //classifier30
    if(final_sum[30]>= (134 * stddev))
       ss[30] = 269;
    else
       ss[30] = -129;

  //classifier31
    if(final_sum[31]>= (-29 * stddev))
       ss[31] = -344;
    else
       ss[31] = 93;

  //classifier32
    if(final_sum[32]>= (206 * stddev))
       ss[32] = 371;
    else
       ss[32] = -77;

  //classifier33
    if(final_sum[33]>= (192 * stddev))
       ss[33] = 310;
    else
       ss[33] = -103;

  //classifier34
    if(final_sum[34]>= (-284 * stddev))
       ss[34] = -117;
    else
       ss[34] = 269;

  //classifier35
    if(final_sum[35]>= (-200 * stddev))
       ss[35] = 39;
    else
       ss[35] = -416;

  //classifier36
    if(final_sum[36]>= (347 * stddev))
       ss[36] = -400;
    else
       ss[36] = 72;

  //classifier37
    if(final_sum[37]>= (-7 * stddev))
       ss[37] = 59;
    else
       ss[37] = -259;

  //classifier38
    if(final_sum[38]>= (473 * stddev))
       ss[38] = 327;
    else
       ss[38] = -42;

  //classifier39
    if(final_sum[39]>= (-210 * stddev))
       ss[39] = -77;
    else
       ss[39] = 388;

  //classifier40
    if(final_sum[40]>= (-174 * stddev))
       ss[40] = -13;
    else
       ss[40] = 451;

  //classifier41
    if(final_sum[41]>= (1522 * stddev))
       ss[41] = 393;
    else
       ss[41] = -80;

  //classifier42
    if(final_sum[42]>= (79 * stddev))
       ss[42] = 239;
    else
       ss[42] = -25;

  //classifier43
    if(final_sum[43]>= (71 * stddev))
       ss[43] = 246;
    else
       ss[43] = -103;

  //classifier44
    if(final_sum[44]>= (162 * stddev))
       ss[44] = -757;
    else
       ss[44] = 43;

  //classifier45
    if(final_sum[45]>= (-37 * stddev))
       ss[45] = -112;
    else
       ss[45] = 227;

  //classifier46
    if(final_sum[46]>= (7 * stddev))
       ss[46] = 102;
    else
       ss[46] = -95;

  //classifier47
    if(final_sum[47]>= (123 * stddev))
       ss[47] = -677;
    else
       ss[47] = 16;

  //classifier48
    if(final_sum[48]>= (-322 * stddev))
       ss[48] = 72;
    else
       ss[48] = -447;

  //classifier49
    if(final_sum[49]>= (8 * stddev))
       ss[49] = 59;
    else
       ss[49] = -240;

  //classifier50
    if(final_sum[50]>= (110 * stddev))
       ss[50] = 275;
    else
       ss[50] = -13;

  //classifier51
    if(final_sum[51]>= (-184 * stddev))
       ss[51] = 25;
    else
       ss[51] = -468;








  int stage_sum = 0;
  int noface = 0;

  stage_sum = ss[0] + ss[1] + ss[2] + ss[3] + ss[4] + ss[5] + ss[6] + ss[7] + ss[8];

  if( stage_sum < 0.4*stages_thresh_array[0] ){
	  noface = 1;
  }




  /* Hard-Coding Classifier 1 */
  stage_sum = 0;


  stage_sum = ss[9] + ss[10] + ss[11] + ss[12] + ss[13] + ss[14] + ss[15] + ss[16];
  stage_sum+= ss[17] + ss[18] + ss[19] + ss[20] + ss[21] + ss[22] + ss[23] + ss[24];

  if( stage_sum < 0.4*stages_thresh_array[1] ){

  	noface = 1;
  }




  /* Hard-Coding Classifier 2 */
  stage_sum = 0;


  stage_sum = ss[25] + ss[26] + ss[27] + ss[28] + ss[29] + ss[30] + ss[31] + ss[32];
  stage_sum+= ss[33] + ss[34] + ss[35] + ss[36] + ss[37] + ss[38] + ss[39] + ss[40];
  stage_sum+= ss[41] + ss[42] + ss[43] + ss[44] + ss[45] + ss[46] + ss[47] + ss[48];
  stage_sum+= ss[49] + ss[50] + ss[51];

  if( stage_sum < 0.4*stages_thresh_array[2] ){

	  noface = 1;
  }


  Output_1.write(noface);

}

