#include "../host/typedefs.h"

void sfilter4

(
  hls::stream<ap_uint<32> > & Input_1,
  hls::stream<ap_uint<32> > & Input_2,
  hls::stream<ap_uint<128> > & Output_1,
  hls::stream<ap_uint<32> > & Output_2
)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2


  static int res_size_Scale = 0;
  static unsigned char data_in;
  int u,v;
  int i,j,k;
  static char factor=0;
  //float scaleFactor = 1.2;
  static int x = 0;
  static int y = 0;
  static int width=0;
  static int height=0;
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
  static int_SII SII[1][SQ_SIZE]= {0};
  #pragma HLS array_partition variable=SII complete dim=0

  static int read_L=0;




  if(x==0 && y==0 && read_L ==0){
	  SII[0][0] = 0;
	  SII[0][1] = 0;
	  Initailize4v:
	  for ( j = 0; j < IMAGE_WIDTH ; j++){
#pragma HLS PIPELINE II=1


		  for ( i = 0; i < 4; i++ ){
#pragma HLS unroll
			  L_4[i][j] = 0;
		  }
	  }


	  for(j=0; j < WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( u = 0; u < 5; u++ ){
#pragma HLS unroll
			  II_4[u][j] = 0;
		  }
	  }

	  for(j=0; j < 2*WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( i = 0; i < 5 ; i++ ){
#pragma HLS unroll
			  I_4[i][j] = 0;
			  SI_4[i][j] = 0;
		  }
	  }
	  //if( IMAGE_WIDTH/factor > WINDOW_SIZE && IMAGE_HEIGHT/factor > WINDOW_SIZE )
	  //{
		//MySize sz = { (int)( IMAGE_WIDTH/factor ), (int)( IMAGE_HEIGHT/factor ) };
		height = height_list[factor];
		width  = width_list[factor];
	  //}
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


  	  read_L = 0;
      /* Updates for Integral Image Window Buffer (I) */
      /* Updates for Integral Image Window Buffer (I) */

  	for ( v = 0; v < WINDOW_SIZE; v++ ){
#pragma HLS unroll
  		for ( u = 0; u < 5; u++){
      #pragma HLS unroll
          II_4[u][v] = II_4[u][v] + ( I_4[u][v+1] - I_4[u][0] );
        }
     }


      /* Updates for Square Image Window Buffer (SI) */
      SII[0][0] = SII[0][0] + ( SI_4[4][1] - SI_4[4][0] );
      SII[0][1] = SII[0][1] + ( SI_4[4][WINDOW_SIZE] - SI_4[4][0] );

      int stddev = -SII[0][0] + SII[0][1];
      int mean = -II_4[4][0] + II_4[4][24];

      for( j = 0; j < 2*WINDOW_SIZE-1; j++){
#pragma HLS unroll
		if(j != 2*WINDOW_SIZE-21 ){
		  I_4[0][j] = I_4[0][j+1];
		  SI_4[0][j] = SI_4[0][j+1];
	  	}
		else{
		  I_4[0][j] = I_4[0][j+1] + Input_2.read();
		  SI_4[0][j] = SI_4[0][j+1] + Input_2.read();
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



      /* Pass the Integral Image Window buffer through Cascaded Classifier. Only pass
       * when the integral image window buffer has flushed out the initial garbage data */
      if ( element_counter >= ( ( (WINDOW_SIZE-1)*width + WINDOW_SIZE ) + WINDOW_SIZE -1 ) ) {
	 /* Sliding Window should not go beyond the boundary */
         if ( x_index < ( width - (WINDOW_SIZE-1) ) && y_index < ( height - (WINDOW_SIZE-1) ) ){
             int sum[60]={0};
	     #pragma HLS array_partition variable=sum complete dim=0

            //classifier0

            //20-24
            sum[0]=0;



            //classifier1

            //20-24
            sum[1]=0;



            //classifier2

            //20-24
            sum[2]=0;



            //classifier3

            //20-24
            sum[3]=0;
            sum[3] = sum[3] + -II_4[4][8] * (-4096);
            sum[3] = sum[3] + +II_4[4][17] * (-4096);
            sum[3] = sum[3] + II_4[0][8] * (12288);
            sum[3] = sum[3] + -II_4[0][17] * (12288);
            sum[3] = sum[3] + -II_4[2][8] * (12288);
            sum[3] = sum[3] + +II_4[2][17] * (12288);



            //classifier4

            //20-24
            sum[4]=0;
            sum[4] = sum[4] + -II_4[4][3] * (-4096);
            sum[4] = sum[4] + +II_4[4][7] * (-4096);
            sum[4] = sum[4] + -II_4[4][5] * (8192);
            sum[4] = sum[4] + +II_4[4][7] * (8192);



            //classifier5

            //20-24
            sum[5]=0;
            sum[5] = sum[5] + -II_4[1][6] * (-4096);
            sum[5] = sum[5] + +II_4[1][18] * (-4096);
            sum[5] = sum[5] + -II_4[1][6] * (8192);
            sum[5] = sum[5] + +II_4[1][18] * (8192);



            //classifier6

            //20-24
            sum[6]=0;



            //classifier7

            //20-24
            sum[7]=0;
            sum[7] = sum[7] + -II_4[4][11] * (-4096);
            sum[7] = sum[7] + +II_4[4][15] * (-4096);
            sum[7] = sum[7] + -II_4[4][11] * (8192);
            sum[7] = sum[7] + +II_4[4][15] * (8192);



            //classifier8

            //20-24
            sum[8]=0;



            //classifier9

            //20-24
            sum[9]=0;



            //classifier10

            //20-24
            sum[10]=0;



            //classifier11

            //20-24
            sum[11]=0;
            sum[11] = sum[11] + -II_4[0][1] * (-4096);
            sum[11] = sum[11] + +II_4[0][20] * (-4096);



            //classifier12

            //20-24
            sum[12]=0;



            //classifier13

            //20-24
            sum[13]=0;
            sum[13] = sum[13] + -II_4[4][9] * (-4096);
            sum[13] = sum[13] + +II_4[4][15] * (-4096);



            //classifier14

            //20-24
            sum[14]=0;



            //classifier15

            //20-24
            sum[15]=0;



            //classifier16

            //20-24
            sum[16]=0;



            //classifier17

            //20-24
            sum[17]=0;



            //classifier18

            //20-24
            sum[18]=0;



            //classifier19

            //20-24
            sum[19]=0;



            //classifier20

            //20-24
            sum[20]=0;



            //classifier21

            //20-24
            sum[21]=0;



            //classifier22

            //20-24
            sum[22]=0;



            //classifier23

            //20-24
            sum[23]=0;
            sum[23] = sum[23] + -II_4[4][7] * (-4096);
            sum[23] = sum[23] + +II_4[4][17] * (-4096);
            sum[23] = sum[23] + II_4[0][7] * (12288);
            sum[23] = sum[23] + -II_4[0][17] * (12288);
            sum[23] = sum[23] + -II_4[2][7] * (12288);
            sum[23] = sum[23] + +II_4[2][17] * (12288);



            //classifier24

            //20-24
            sum[24]=0;



            //classifier25

            //20-24
            sum[25]=0;



            //classifier26

            //20-24
            sum[26]=0;



            //classifier27

            //20-24
            sum[27]=0;
            sum[27] = sum[27] + -II_4[0][9] * (-4096);
            sum[27] = sum[27] + +II_4[0][14] * (-4096);
            sum[27] = sum[27] + -II_4[0][9] * (8192);
            sum[27] = sum[27] + +II_4[0][14] * (8192);



            //classifier28

            //20-24
            sum[28]=0;



            //classifier29

            //20-24
            sum[29]=0;



            //classifier30

            //20-24
            sum[30]=0;
            sum[30] = sum[30] + II_4[1][3] * (-4096);
            sum[30] = sum[30] + -II_4[1][21] * (-4096);
            sum[30] = sum[30] + -II_4[4][3] * (-4096);
            sum[30] = sum[30] + +II_4[4][21] * (-4096);
            sum[30] = sum[30] + II_4[1][9] * (12288);
            sum[30] = sum[30] + -II_4[1][15] * (12288);
            sum[30] = sum[30] + -II_4[4][9] * (12288);
            sum[30] = sum[30] + +II_4[4][15] * (12288);



            //classifier31

            //20-24
            sum[31]=0;



            //classifier32

            //20-24
            sum[32]=0;



            //classifier33

            //20-24
            sum[33]=0;



            //classifier34

            //20-24
            sum[34]=0;
            sum[34] = sum[34] + -II_4[3][0] * (-4096);
            sum[34] = sum[34] + +II_4[3][24] * (-4096);
            sum[34] = sum[34] + -II_4[3][8] * (12288);
            sum[34] = sum[34] + +II_4[3][16] * (12288);



            //classifier35

            //20-24
            sum[35]=0;



            //classifier36

            //20-24
            sum[36]=0;
            sum[36] = sum[36] + -II_4[4][2] * (-4096);
            sum[36] = sum[36] + +II_4[4][23] * (-4096);
            sum[36] = sum[36] + -II_4[0][2] * (12288);
            sum[36] = sum[36] + +II_4[0][23] * (12288);



            //classifier37

            //20-24
            sum[37]=0;



            //classifier38

            //20-24
            sum[38]=0;
            sum[38] = sum[38] + -II_4[3][2] * (-4096);
            sum[38] = sum[38] + +II_4[3][22] * (-4096);
            sum[38] = sum[38] + -II_4[3][2] * (8192);
            sum[38] = sum[38] + +II_4[3][12] * (8192);



            //classifier39

            //20-24
            sum[39]=0;



            //classifier40

            //20-24
            sum[40]=0;



            //classifier41

            //20-24
            sum[41]=0;
            sum[41] = sum[41] + -II_4[4][0] * (-4096);
            sum[41] = sum[41] + +II_4[4][22] * (-4096);
            sum[41] = sum[41] + -II_4[4][11] * (8192);
            sum[41] = sum[41] + +II_4[4][22] * (8192);



            //classifier42

            //20-24
            sum[42]=0;



            //classifier43

            //20-24
            sum[43]=0;



            //classifier44

            //20-24
            sum[44]=0;



            //classifier45

            //20-24
            sum[45]=0;



            //classifier46

            //20-24
            sum[46]=0;



            //classifier47

            //20-24
            sum[47]=0;



            //classifier48

            //20-24
            sum[48]=0;



            //classifier49

            //20-24
            sum[49]=0;



            //classifier50

            //20-24
            sum[50]=0;
            sum[50] = sum[50] + -II_4[4][17] * (-4096);
            sum[50] = sum[50] + +II_4[4][21] * (-4096);
            sum[50] = sum[50] + -II_4[4][17] * (8192);
            sum[50] = sum[50] + +II_4[4][19] * (8192);



            //classifier51

            //20-24
            sum[51]=0;



            bit128 out_tmp;

             out_tmp(31,0) = (ap_int<32>) stddev;
             out_tmp(63,32) = (ap_int<32>) mean;
             Output_1.write(out_tmp);

             for(i=0; i<6; i++)
             {
#pragma HLS PIPELINE II=1
            	 for(j=0; j<10; j++)
            	 {
#pragma HLS unroll
            		 out_tmp(j*12+11, j*12) = (ap_int<12>) (sum[10*i+j]/1048576);
            	 }
            	 Output_1.write(out_tmp);
             }

         }// inner if
         if ( x_index < width-1 )
             x_index = x_index + 1;
         else{
             x_index = 0;
             y_index = y_index + 1;
         }
       } // outer if
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
     		    if(factor == 12 )
     		    {
     		  	  factor = 0;
     		    }
     	  }
       }

}


