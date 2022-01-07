#include "../host/typedefs.h"


void sfilter3

(
  hls::stream<ap_uint<32> > & Input_1,
  hls::stream<ap_uint<32> > & Input_2,
  hls::stream<ap_uint<128> > & Output_1,
  hls::stream<ap_uint<32> > & Output_2,
  hls::stream<ap_uint<32> > & Output_3
)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2
#pragma HLS INTERFACE axis register port=Output_3

  static int res_size_Scale = 0;
  static unsigned char data_in;
  int u,v;
  int i,j,k;
  static unsigned char factor=0;
  //float scaleFactor = 1.2;
  static int x = 0;
  static int y = 0;
  static int width=0;
  static int height=0;
  static int read_L = 0;
  static int element_counter = 0;
  static int x_index = 0;
  static int y_index = 0;
  static ap_uint<9> height_list[12] = {199, 166, 138, 115, 96, 80, 66, 55, 46, 38, 32, 26};
  static ap_uint<9> width_list[12] = {266, 222, 185, 154, 128, 107, 89, 74, 62, 51, 43, 35};

  static unsigned char L_3[5][IMAGE_WIDTH]= {0};
  #pragma HLS array_partition variable=L_3 complete dim=1

  static int_I I_3[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=I_3 complete dim=0



  /** Integral Image Window buffer ( 625 registers )*/
  static int_II II_3[5][WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=II_3 complete dim=0

  static int_SI SI_3[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=SI_3 complete dim=0


/** Loop over each point in the Image ( scaled ) **/
  /* Updates for Integral Image Window Buffer (I) */
  /* Updates for Integral Image Window Buffer (I) */



  if(x==0 && y==0 && read_L==0){
	  Initailize3v:
	  for ( j = 0; j < IMAGE_WIDTH ; j++){//IMAGE_WIDTH; x++ ){
#pragma HLS PIPELINE

		  for ( i = 0; i < 5; i++ ){
#pragma HLS unroll
			  L_3[i][j] = 0;
		  }
	  }

	  for(j=0; j<WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( u = 0; u < 5; u++ ){
#pragma HLS unroll
			  II_3[u][j] = 0;
		  }
	  }

	  for(j=0; j< 2*WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( i = 0; i < 5 ; i++ ){
#pragma HLS unroll
			  I_3[i][j] = 0;
			  SI_3[i][j] = 0;
		  }
	  }



	  //if( IMAGE_WIDTH/factor > WINDOW_SIZE && IMAGE_HEIGHT/factor > WINDOW_SIZE )
	  //{
		//MySize sz = { (int)( IMAGE_WIDTH/factor ), (int)( IMAGE_HEIGHT/factor ) };
		height = height_list[factor];
		width  = width_list[factor];
	  //}
  }

  if(read_L == 0){
	  Output_2.write(L_3[0][x]);
	  Output_3.write(I_3[4][30]);
	  Output_3.write(SI_3[4][30]);
	read_L = 1;
	return;
  }


  if(read_L == 1){
	  data_in = Input_1.read();
	read_L = 2;
	return;
  }
  	  read_L = 0;
  	  for ( v = 0; v < WINDOW_SIZE; v++ ){
#pragma HLS unroll
  		  for ( u = 0; u < 5; u++){
#pragma HLS unroll
  			  II_3[u][v] = II_3[u][v] + ( I_3[u][v+1] - I_3[u][0] );
  		  }
  	  }



      for( j = 0; j < 2*WINDOW_SIZE-1; j++){
#pragma HLS unroll
		if( j != 2*WINDOW_SIZE-16 ){
		  I_3[0][j] = I_3[0][j+1];
		  SI_3[0][j] = SI_3[0][j+1];
	  	}
		else{
		  I_3[0][j] = I_3[0][j+1] + Input_2.read();
		  SI_3[0][j] = SI_3[0][j+1] + Input_2.read();
		}
        for( i = 1; i < 5; i++ ){
        #pragma HLS unroll
          if( i+j != 2*WINDOW_SIZE-16 ){
            I_3[i][j] = I_3[i][j+1];
            SI_3[i][j] = SI_3[i][j+1];
          }
          else{
            I_3[i][j] = I_3[i][j+1] + I_3[i-1][j+1];
            SI_3[i][j] = SI_3[i][j+1] + SI_3[i-1][j+1];
          }
        }
      }





      /** Last column of the I[][] matrix **/


      for( i = 0; i < 5; i++ ){
      #pragma HLS unroll
        I_3[i][2*WINDOW_SIZE-1] = L_3[i][x];
        SI_3[i][2*WINDOW_SIZE-1] = L_3[i][x]*L_3[i][x];
      }



      for( k = 0; k < 4; k++ ){
      #pragma HLS unroll
        L_3[k][x] = L_3[k+1][x];
      }
      L_3[4][x] = data_in;





      /* Pass the Integral Image Window buffer through Cascaded Classifier. Only pass
       * when the integral image window buffer has flushed out the initial garbage data */
      if ( element_counter >= ( ( (WINDOW_SIZE-1)*width + WINDOW_SIZE ) + WINDOW_SIZE -1 ) ) {
	 /* Sliding Window should not go beyond the boundary */
         if ( x_index < ( width - (WINDOW_SIZE-1) ) && y_index < ( height - (WINDOW_SIZE-1) ) ){


             int sum[60]={0};
	     #pragma HLS array_partition variable=sum complete dim=0
            //classifier0

            //15-19
            sum[0]=0;



            //classifier1

            //15-19
            sum[1]=0;



            //classifier2

            //15-19
            sum[2]=0;
            sum[2] = sum[2] + -II_3[3][3] * (-4096);
            sum[2] = sum[2] + +II_3[3][21] * (-4096);
            sum[2] = sum[2] + -II_3[0][3] * (12288);
            sum[2] = sum[2] + +II_3[0][21] * (12288);



            //classifier3

            //15-19
            sum[3]=0;
            sum[3] = sum[3] + II_3[3][8] * (-4096);
            sum[3] = sum[3] + -II_3[3][17] * (-4096);



            //classifier4

            //15-19
            sum[4]=0;



            //classifier5

            //15-19
            sum[5]=0;



            //classifier6

            //15-19
            sum[6]=0;



            //classifier7

            //15-19
            sum[7]=0;
            sum[7] = sum[7] + II_3[4][11] * (8192);
            sum[7] = sum[7] + -II_3[4][15] * (8192);



            //classifier8

            //15-19
            sum[8]=0;



            //classifier9

            //15-19
            sum[9]=0;



            //classifier10

            //15-19
            sum[10]=0;



            //classifier11

            //15-19
            sum[11]=0;
            sum[11] = sum[11] + -II_3[1][1] * (12288);
            sum[11] = sum[11] + +II_3[1][20] * (12288);



            //classifier12

            //15-19
            sum[12]=0;



            //classifier13

            //15-19
            sum[13]=0;
            sum[13] = sum[13] + -II_3[4][9] * (12288);
            sum[13] = sum[13] + +II_3[4][15] * (12288);



            //classifier14

            //15-19
            sum[14]=0;
            sum[14] = sum[14] + -II_3[1][5] * (-4096);
            sum[14] = sum[14] + +II_3[1][19] * (-4096);
            sum[14] = sum[14] + -II_3[1][5] * (8192);
            sum[14] = sum[14] + +II_3[1][19] * (8192);



            //classifier15

            //15-19
            sum[15]=0;



            //classifier16

            //15-19
            sum[16]=0;
            sum[16] = sum[16] + -II_3[2][13] * (-4096);
            sum[16] = sum[16] + +II_3[2][22] * (-4096);
            sum[16] = sum[16] + -II_3[2][16] * (12288);
            sum[16] = sum[16] + +II_3[2][19] * (12288);



            //classifier17

            //15-19
            sum[17]=0;
            sum[17] = sum[17] + -II_3[0][7] * (-4096);
            sum[17] = sum[17] + +II_3[0][13] * (-4096);
            sum[17] = sum[17] + -II_3[0][9] * (12288);
            sum[17] = sum[17] + +II_3[0][11] * (12288);



            //classifier18

            //15-19
            sum[18]=0;
            sum[18] = sum[18] + -II_3[3][10] * (-4096);
            sum[18] = sum[18] + +II_3[3][16] * (-4096);
            sum[18] = sum[18] + -II_3[3][12] * (12288);
            sum[18] = sum[18] + +II_3[3][14] * (12288);



            //classifier19

            //15-19
            sum[19]=0;



            //classifier20

            //15-19
            sum[20]=0;



            //classifier21

            //15-19
            sum[21]=0;
            sum[21] = sum[21] + -II_3[4][0] * (-4096);
            sum[21] = sum[21] + +II_3[4][24] * (-4096);
            sum[21] = sum[21] + -II_3[4][8] * (12288);
            sum[21] = sum[21] + +II_3[4][16] * (12288);



            //classifier22

            //15-19
            sum[22]=0;
            sum[22] = sum[22] + -II_3[0][9] * (-4096);
            sum[22] = sum[22] + +II_3[0][15] * (-4096);
            sum[22] = sum[22] + -II_3[0][11] * (12288);
            sum[22] = sum[22] + +II_3[0][13] * (12288);



            //classifier23

            //15-19
            sum[23]=0;
            sum[23] = sum[23] + II_3[3][7] * (-4096);
            sum[23] = sum[23] + -II_3[3][17] * (-4096);



            //classifier24

            //15-19
            sum[24]=0;
            sum[24] = sum[24] + -II_3[4][5] * (-4096);
            sum[24] = sum[24] + +II_3[4][19] * (-4096);
            sum[24] = sum[24] + -II_3[4][5] * (8192);
            sum[24] = sum[24] + +II_3[4][19] * (8192);



            //classifier25

            //15-19
            sum[25]=0;



            //classifier26

            //15-19
            sum[26]=0;



            //classifier27

            //15-19
            sum[27]=0;



            //classifier28

            //15-19
            sum[28]=0;
            sum[28] = sum[28] + -II_3[0][9] * (-4096);
            sum[28] = sum[28] + +II_3[0][15] * (-4096);
            sum[28] = sum[28] + -II_3[0][11] * (12288);
            sum[28] = sum[28] + +II_3[0][13] * (12288);



            //classifier29

            //15-19
            sum[29]=0;
            sum[29] = sum[29] + -II_3[3][6] * (-4096);
            sum[29] = sum[29] + +II_3[3][9] * (-4096);
            sum[29] = sum[29] + -II_3[3][6] * (8192);
            sum[29] = sum[29] + +II_3[3][9] * (8192);



            //classifier30

            //15-19
            sum[30]=0;



            //classifier31

            //15-19
            sum[31]=0;



            //classifier32

            //15-19
            sum[32]=0;
            sum[32] = sum[32] + -II_3[1][18] * (-4096);
            sum[32] = sum[32] + +II_3[1][24] * (-4096);
            sum[32] = sum[32] + -II_3[1][18] * (8192);
            sum[32] = sum[32] + +II_3[1][21] * (8192);



            //classifier33

            //15-19
            sum[33]=0;
            sum[33] = sum[33] + -II_3[1][1] * (-4096);
            sum[33] = sum[33] + +II_3[1][7] * (-4096);
            sum[33] = sum[33] + -II_3[1][4] * (8192);
            sum[33] = sum[33] + +II_3[1][7] * (8192);



            //classifier34

            //15-19
            sum[34]=0;



            //classifier35

            //15-19
            sum[35]=0;
            sum[35] = sum[35] + -II_3[3][5] * (-4096);
            sum[35] = sum[35] + +II_3[3][19] * (-4096);
            sum[35] = sum[35] + -II_3[3][12] * (8192);
            sum[35] = sum[35] + +II_3[3][19] * (8192);



            //classifier36

            //15-19
            sum[36]=0;
            sum[36] = sum[36] + II_3[1][2] * (12288);
            sum[36] = sum[36] + -II_3[1][23] * (12288);



            //classifier37

            //15-19
            sum[37]=0;



            //classifier38

            //15-19
            sum[38]=0;



            //classifier39

            //15-19
            sum[39]=0;



            //classifier40

            //15-19
            sum[40]=0;
            sum[40] = sum[40] + -II_3[0][20] * (-4096);
            sum[40] = sum[40] + +II_3[0][24] * (-4096);
            sum[40] = sum[40] + -II_3[0][20] * (8192);
            sum[40] = sum[40] + +II_3[0][22] * (8192);



            //classifier41

            //15-19
            sum[41]=0;



            //classifier42

            //15-19
            sum[42]=0;



            //classifier43

            //15-19
            sum[43]=0;



            //classifier44

            //15-19
            sum[44]=0;



            //classifier45

            //15-19
            sum[45]=0;



            //classifier46

            //15-19
            sum[46]=0;



            //classifier47

            //15-19
            sum[47]=0;



            //classifier48

            //15-19
            sum[48]=0;
            sum[48] = sum[48] + -II_3[4][5] * (-4096);
            sum[48] = sum[48] + +II_3[4][19] * (-4096);
            sum[48] = sum[48] + -II_3[4][5] * (8192);
            sum[48] = sum[48] + +II_3[4][12] * (8192);



            //classifier49

            //15-19
            sum[49]=0;



            //classifier50

            //15-19
            sum[50]=0;



            //classifier51

            //15-19
            sum[51]=0;

            bit128 out_tmp;

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
     		    if( factor == 12 )
     		    {
     		  	  factor = 0;
     		    }
     	  }
       }

}


