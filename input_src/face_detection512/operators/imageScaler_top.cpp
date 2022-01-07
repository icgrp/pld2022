#include "../host/typedefs.h"

void imageScaler_top
(
  hls::stream<ap_uint<512> > & Input_1,
  hls::stream<ap_uint<32> > & Output_1
)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Output_1
	  static unsigned char Data[IMAGE_HEIGHT/2][IMAGE_WIDTH];
	  int i, j, k;
	  int y;
	  int x;
	  int w1 = IMAGE_WIDTH;
	  int h1 = IMAGE_HEIGHT;
	  //float scaleFactor = 1.2;
	  //float factor;
	  static unsigned char  factor=0;
	  int width=0;
	  int height=0;

	  static ap_uint<9> height_list[12] = {199, 166, 138, 115, 96, 80, 66, 55, 46, 38, 32, 26};
	  static ap_uint<9> width_list[12] = {266, 222, 185, 154, 128, 107, 89, 74, 62, 51, 43, 35};


	  LOAD_i: for( i = 0; i < IMAGE_HEIGHT/2; i++){
	    LOAD_j: for( j = 0; j < IMAGE_WIDTH/64; j++){
	    	bit512 Input_tmp = Input_1.read();
	      LOAD_k: for( k = 0; k < 64; k++){
#pragma HLS pipeline II=1
	    	  Data[i][j*64+k] = Input_tmp(8*k+7, 8*k);
	      }

	    }
	  }

	  CROSS_i: for( i = IMAGE_HEIGHT/2; i < IMAGE_HEIGHT; i++){
	    CROSS_j: for( j = 0; j < IMAGE_WIDTH/64; j++){
	    	bit512 Input_tmp = Input_1.read();
	    	CROSS_k: for( k = 0; k < 64; k++){
#pragma HLS pipeline
	    		bit32 out_tmp;
	    		out_tmp(7,0) = Input_tmp(8*k+7, 8*k);
	    		Output_1.write(out_tmp);
	    	}

	    }
	  }


	  L1:
	  while ( factor < 12 )
	  {

		height = height_list[factor];
		width  = width_list[factor];
	    int w2 = width;
	    int h2 = height;
	    int rat = 0;

	    int x_ratio = (int)((w1<<16)/w2) +1;
	    int y_ratio = (int)((h1<<16)/h2) +1;
	    imageScalerL1: for ( i = 0 ; i < IMAGE_HEIGHT ; i++ ){
	      imageScalerL1_1: for (j=0;j < IMAGE_WIDTH ;j++){
	        #pragma HLS pipeline
	        if ( j < w2 && i < h2 ){
	          x = (i*y_ratio)>>16;
	          y = (j*x_ratio)>>16;
	          if(x<IMAGE_HEIGHT/2){
	        	  Output_1.write(Data[x][y]);
	          }
	        }
	      }
	    }
	    factor++;
	  } /* end of the factor loop, finish all scales in pyramid*/


}


