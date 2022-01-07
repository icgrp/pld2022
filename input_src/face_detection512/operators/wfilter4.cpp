#include "../host/typedefs.h"

void wfilter4

(
  hls::stream<ap_uint<32> > & Input_1,
  hls::stream<ap_uint<64> > & Input_2,
  hls::stream<ap_uint<128> > & Input_3,
  hls::stream<ap_uint<128> > & Output_1,
  hls::stream<ap_uint<32> > & Output_2
)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Input_3
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2


  static unsigned char data_in;
  int u,v;
  int i,j,k;
  static unsigned char factor=0;
  static int x = 0;
  static int y = 0;
  static int width=0;
  static int height=0;
  static int read_L=0;
  static int haar_counter = 52;
  static int stddev = 0;
  static int mean = 0;
  static int element_counter = 0;
  static int x_index = 0;
  static int y_index = 0;

  static ap_uint<9> height_list[12] = {199, 166, 138, 115, 96, 80, 66, 55, 46, 38, 32, 26};
  static ap_uint<9> width_list[12] = {266, 222, 185, 154, 128, 107, 89, 74, 62, 51, 43, 35};

  static unsigned char L_4[4][IMAGE_WIDTH]= {0};
  #pragma HLS array_partition variable=L_4 complete dim=1


  static int_I I_4[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=I_4 complete dim=0

  /** Integral Image Window buffer ( 625 registers )*/
  static int_II II_4[5][WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=II_4 complete dim=0

  static int_SI SI_4[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=SI_4 complete dim=0

  /** Square Integral Image Window buffer ( 625 registers )*/
  static int_SII SII[SQ_SIZE][SQ_SIZE]= {0};
  #pragma HLS array_partition variable=SII complete dim=0

  uint18_t coord[3][4];
  #pragma HLS array_partition variable=coord complete dim=1

  ap_uint<64> in_tmp2;


  if(x==0 && y==0){
	  for(j=0; j< WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( u = 0; u < 5; u++ ){
#pragma HLS unroll
			  II_4[u][j] = 0;
		  }
	  }


	  SII[0][0] = 0;
	  SII[0][1] = 0;
	  SII[1][0] = 0;
	  SII[1][1] = 0;


	  for(j=0; j < 2*WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( i = 0; i < 5 ; i++ ){
#pragma HLS unroll
			  I_4[i][j] = 0;
			  SI_4[i][j] = 0;
		  }
	  }


	  Initailize4w:
	  for ( j = 0; j < IMAGE_WIDTH ; j++){
#pragma HLS PIPELINE
		  for ( i = 0; i < 4; i++ ){
#pragma HLS unroll
			  L_4[i][j] = 0;
		  }
	  }

		height = height_list[factor];
		width  = width_list[factor];
  }


  /** Loop over each point in the Image ( scaled ) **/
  	  if(read_L == 0){
  		Output_2.write(L_4[0][x]);
  		read_L = 1;
  		return;
  	  }

  	  if(read_L == 1){
  		data_in = (unsigned char) Input_1.read();
  		read_L = 2;
  		return;
  	  }


  	if(read_L == 2){
  	  read_L = 3;

      for ( v = 0; v < WINDOW_SIZE; v++ ){
     #pragma HLS unroll
     //#pragma HLS PIPELINE
       		  for ( u = 0; u < 5; u++){
     #pragma HLS unroll
       			  II_4[u][v] = II_4[u][v] + ( I_4[u][v+1] - I_4[u][0] );
       		  }
           }




      /* Updates for Square Image Window Buffer (SI) */
      SII[1][0] = SII[1][0] + ( SI_4[4][1] - SI_4[4][0] );
      SII[1][1] = SII[1][1] + ( SI_4[4][WINDOW_SIZE] - SI_4[4][0] );

      stddev = -SII[1][0] + SII[1][1];
      mean = -II_4[4][0] + II_4[4][24];



      for( j = 0; j < 2*WINDOW_SIZE-1; j++){
//#pragma HLS PIPELINE
#pragma HLS unroll
		if(j != 2*WINDOW_SIZE-21 ){
		  I_4[0][j] = I_4[0][j+1];
		  SI_4[0][j] = SI_4[0][j+1];
	  	}
		else{
		  in_tmp2 = Input_2.read();
		  I_4[0][j] = I_4[0][j+1] + in_tmp2(12, 0);
		  SI_4[0][j] = SI_4[0][j+1] + in_tmp2(52, 32);
		}
        for( i = 1; i < 5; i++ ){
        #pragma HLS unroll
          if( i+j != 2*WINDOW_SIZE-21 ){
            I_4[i][j] = I_4[i][j+1];
            SI_4[i][j] = SI_4[i][j+1];
          }
          else if ( i > 0 ){
            I_4[i][j] = I_4[i][j+1] + I_4[i-1][j+1];
            SI_4[i][j] = SI_4[i][j+1] + SI_4[i-1][j+1];
          }
        }
      }


      /** Last column of the I[][] matrix **/


      for( i = 0; i < 4; i++ ){
      #pragma HLS unroll
        I_4[i][2*WINDOW_SIZE-1] = L_4[i][x];
        SI_4[i][2*WINDOW_SIZE-1] = L_4[i][x]*L_4[i][x];
      }


      I_4[4][2*WINDOW_SIZE-1] = data_in;
      SI_4[4][2*WINDOW_SIZE-1] = data_in*data_in;




      for( k = 0; k < 3; k++ ){
      #pragma HLS unroll
        L_4[k][x] = L_4[k+1][x];
      }

      L_4[3][x] = data_in;

      return;
  	}


    ap_uint<128> data_req_0;



    int cmd = 0;
    data_req_0 = Input_3.read();
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
         					out_tmp(18*i+17,18*i)=II_4[i][j];
             			}
         				Output_1.write(out_tmp);
             		}

         		}


        		Output_1.write(data_req_0);
				//for(i = 0; i<3; i++){
//#pragma HLS PIPELINE
					//data_req_0 = Input_3.read();
					//Output_1.write(data_req_0);
				//}
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
					if( factor == 12 )
					{
					  factor = 0;
					}
			  }
		   }
      }
}

