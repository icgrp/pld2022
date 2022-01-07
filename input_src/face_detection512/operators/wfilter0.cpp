#include "../host/typedefs.h"

void wfilter0

(
  hls::stream<ap_uint<32> > & Input_1,
  hls::stream<ap_uint<128> > & Input_2,
  hls::stream<ap_uint<128> > & Output_1,
  hls::stream<ap_uint<64> > & Output_2
)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2
  static unsigned char data_in = 0;
  int u,v;
  int i,j,k;

  static unsigned char factor=0;
  static int x = 0;
  static int y = 0;
  static int width=0;
  static int height=0;
  static int read_L = 0;
  static int stddev = 0;
  static int mean = 0;
  static int element_counter = 0;
  static int x_index = 0;
  static int y_index = 0;
  static int haar_counter = 52;
  static ap_uint<9> height_list[12] = {199, 166, 138, 115, 96, 80, 66, 55, 46, 38, 32, 26};
  static ap_uint<9> width_list[12] = {266, 222, 185, 154, 128, 107, 89, 74, 62, 51, 43, 35};
  static unsigned char L_0[5][IMAGE_WIDTH]= {0};
  #pragma HLS array_partition variable=L_0 complete dim=1

  static int_I I_0[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=I_0 complete dim=0

  /** Integral Image Window buffer ( 625 registers )*/
  static int_II II_0[5][WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=II_0 complete dim=0


  static int_SI SI_0[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=SI_0 complete dim=0

  /** Square Integral Image Window buffer ( 625 registers )*/
  static int_SII SII[1][SQ_SIZE]= {0};
  #pragma HLS array_partition variable=SII complete dim=0

  uint18_t coord[3][4];
  #pragma HLS array_partition variable=coord complete dim=1

  ap_uint<64> out_tmp2;

	/** Loop over each point in the Image ( scaled ) **/



	if(x==0 && y==0){
		for(j=0; j<WINDOW_SIZE; j++){
#pragma HLS unroll
			for ( u = 0; u < 5; u++ ){
#pragma HLS unroll
				II_0[u][j] = 0;
			}
		}

	  SII[0][0] = 0;
	  SII[0][1] = 0;


		for(j=0; j < 2*WINDOW_SIZE; j++){
#pragma HLS unroll
			for ( i = 0; i < 5 ; i++ ){
#pragma HLS unroll
				I_0[i][j] = 0;
				SI_0[i][j] = 0;
			}
		}


		Initailize0w:
		for ( j = 0; j < IMAGE_WIDTH ; j++){
#pragma HLS PIPELINE II=1
			for ( i = 0; i < 5; i++ ){
#pragma HLS unroll
				L_0[i][j] = 0;
			}
	  }




		height = height_list[factor];
		width  = width_list[factor];
	}



	/** Loop over each point in the Image ( scaled ) **/

	/* Updates for Integral Image Window Buffer (I) */
	/* Updates for Integral Image Window Buffer (I) */
	if(read_L == 0){
	  out_tmp2(12, 0) = I_0[4][45](12, 0);
	  out_tmp2(52, 32) = SI_0[4][45](20, 0);
	  Output_2.write(out_tmp2);
	  read_L = 1;
	return;
	}

	if(read_L == 1){
	  data_in = Input_1.read();
	  read_L = 2;
	return;
	}
	if(read_L == 2){
		read_L = 3;
		for ( v = 0; v < WINDOW_SIZE; v++ ){
#pragma HLS unroll
//#pragma HLS PIPELINE II=1
			for ( u = 0; u < 5; u++){
#pragma HLS unroll
				II_0[u][v] = II_0[u][v] + ( I_0[u][v+1] - I_0[u][0] );
			}
		}

		/* Updates for Square Image Window Buffer (SI) */
		SII[0][0] = SII[0][0] + ( SI_0[0][1] - SI_0[0][0] );
		SII[0][1] = SII[0][1] + ( SI_0[0][WINDOW_SIZE] - SI_0[0][0] );

		stddev = SII[0][0] - SII[0][1];
		mean = II_0[0][0] - II_0[0][24];



		HARD_LOOP: for( j = 0; j < 2*WINDOW_SIZE-1; j++){
#pragma HLS unroll
//#pragma HLS PIPELINE II=1
			for( i = 0; i < 5; i++ ){
#pragma HLS unroll
				if( i+j != 2*WINDOW_SIZE-1 ){
					I_0[i][j] = I_0[i][j+1];
					SI_0[i][j] = SI_0[i][j+1];
				}
				else if ( i > 0 ){
					I_0[i][j] = I_0[i][j+1] + I_0[i-1][j+1];
					SI_0[i][j] = SI_0[i][j+1] + SI_0[i-1][j+1];
				}
			}
		}



		/** Last column of the I[][] matrix **/

		LAST_LOOP_ISI_0: for( i = 0; i < 5; i++ ){
#pragma HLS unroll
			I_0[i][2*WINDOW_SIZE-1] = L_0[i][x];
			SI_0[i][2*WINDOW_SIZE-1] = L_0[i][x]*L_0[i][x];
		}


		LAST_L_0: for( k = 0; k < 4; k++ ){
#pragma HLS unroll
			L_0[k][x] = L_0[k+1][x];
		}
		L_0[4][x] = data_in;

		return;
    }



    ap_uint<128> data_req_0;
    int cmd = 0;
    data_req_0 = Input_2.read();
    //Output_2.write(data_req_0);
    cmd = data_req_0(127, 126);
    if(cmd == 1){
    	read_L = 0;
    	haar_counter = 52;

    }


      /* Pass the Integral Image Window buffer through Cascaded Classifier. Only pass
       * when the integral image window buffer has flushed out the initial garbage data */
      if ( element_counter >= ( ( (WINDOW_SIZE-1)*width + WINDOW_SIZE ) + WINDOW_SIZE -1 ) ) {
	 /* Sliding Window should not go beyond the boundary */
         if ( x_index < ( width - (WINDOW_SIZE-1) ) && y_index < ( height - (WINDOW_SIZE-1) ) ){
        	 if(cmd == 0){

                bit128 out_tmp;
                out_tmp(31, 0)=haar_counter;
                out_tmp(63,32)=stddev;
                out_tmp(95,64)=mean;
                out_tmp(127,96)=0;
       		    Output_1.write(out_tmp);
        		if(haar_counter == 52){
        			OUTPUT_LOOP: for(j=0; j<25; j++){
#pragma HLS PIPELINE
        				for(i = 0; i<5; i++){
        					out_tmp(18*i+17,18*i)=II_0[i][j];
            			}
        				Output_1.write(out_tmp);
            		}

        		}

        		Output_1.write(data_req_0);
        		haar_counter++;
        	 }


         }// inner if
         if(cmd == 1){

        	 if ( x_index < width-1 )
        		 x_index = x_index + 1;
        	 else{
        		 x_index = 0;
        		 y_index = y_index + 1;
        	 }
         }
       } // outer if

      if(cmd == 1){
		  element_counter +=1;
		   x++;
		   if(x == width){
			  x = 0;
			  y++;
			  if(y == height){
				  y = 0;
				  element_counter = 0;
				  x_index = 0;
				  y_index = 0;
				  factor++;
					if(factor == 12)
					{
					  factor = 0;
					}
			  }
		   }
      }



}


