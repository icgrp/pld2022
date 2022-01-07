#include "../host/typedefs.h"

void sfilter2

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
  int result;
  int step;
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

  static unsigned char L_2[5][IMAGE_WIDTH]= {0};
  #pragma HLS array_partition variable=L_2 complete dim=1

  static int_I I_2[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=I_2 complete dim=0



  /** Integral Image Window buffer ( 625 registers )*/
  static int_II II_2[5][WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=II_2 complete dim=0

  static int_SI SI_2[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=SI_2 complete dim=0


/** Loop over each point in the Image ( scaled ) **/
  /* Updates for Integral Image Window Buffer (I) */
  /* Updates for Integral Image Window Buffer (I) */



  if(x==0 && y==0 && read_L == 0){
	  Initailize2v:
	  for ( j = 0; j < IMAGE_WIDTH ; j++){
#pragma HLS PIPELINE II=1

		  for ( i = 0; i < 5; i++ ){
#pragma HLS unroll
			  L_2[i][j] = 0;
		}
	  }

	  for(j=0; j<WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( u = 0; u < 5; u++ ){
#pragma HLS unroll
			  II_2[u][j] = 0;
		  }
	  }

	  for(j=0; j<2*WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( i = 0; i < 5 ; i++ ){
#pragma HLS unroll
			  I_2[i][j] = 0;
			  SI_2[i][j] = 0;
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
	Output_2.write(L_2[0][x]);
	Output_3.write(I_2[4][35]);
	Output_3.write(SI_2[4][35]);
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
		  II_2[u][v] = II_2[u][v] + ( I_2[u][v+1] - I_2[u][0] );
      }
  }




      for( j = 0; j < 2*WINDOW_SIZE-1; j++){
#pragma HLS unroll
    	if( j != 2*WINDOW_SIZE-11 ){
		  I_2[0][j] = I_2[0][j+1];
		  SI_2[0][j] = SI_2[0][j+1];
	  	}
		else{
		  I_2[0][j] = I_2[0][j+1] + Input_2.read();
		  SI_2[0][j] = SI_2[0][j+1] + Input_2.read();
		}
        for( i = 1; i < 5; i++ ){
        #pragma HLS unroll
          if( i+j != 2*WINDOW_SIZE-11 ){
            I_2[i][j] = I_2[i][j+1];
            SI_2[i][j] = SI_2[i][j+1];
          }
          else {
            I_2[i][j] = I_2[i][j+1] + I_2[i-1][j+1];
            SI_2[i][j] = SI_2[i][j+1] + SI_2[i-1][j+1];
          }
        }
      }




      /** Last column of the I[][] matrix **/

      for( i = 0; i < 5; i++ ){
      #pragma HLS unroll
        I_2[i][2*WINDOW_SIZE-1] = L_2[i][x];
        SI_2[i][2*WINDOW_SIZE-1] = L_2[i][x]*L_2[i][x];
      }




      for( k = 0; k < 4; k++ ){
      #pragma HLS unroll
        L_2[k][x] = L_2[k+1][x];
      }
      L_2[4][x] = data_in;



      /* Pass the Integral Image Window buffer through Cascaded Classifier. Only pass
       * when the integral image window buffer has flushed out the initial garbage data */
      if ( element_counter >= ( ( (WINDOW_SIZE-1)*width + WINDOW_SIZE ) + WINDOW_SIZE -1 ) ) {
	 /* Sliding Window should not go beyond the boundary */
         if ( x_index < ( width - (WINDOW_SIZE-1) ) && y_index < ( height - (WINDOW_SIZE-1) ) ){
             int sum[60]={0};
	     #pragma HLS array_partition variable=sum complete dim=0
           //classifier0

            //10-14
            sum[0]=0;
            sum[0] = sum[0] + -II_2[3][6] * (-4096);
            sum[0] = sum[0] + +II_2[3][18] * (-4096);
            sum[0] = sum[0] + -II_2[0][6] * (12288);
            sum[0] = sum[0] + +II_2[0][18] * (12288);



            //classifier1

            //10-14
            sum[1]=0;
            sum[1] = sum[1] + -II_2[1][6] * (-4096);
            sum[1] = sum[1] + +II_2[1][18] * (-4096);
            sum[1] = sum[1] + -II_2[1][10] * (12288);
            sum[1] = sum[1] + +II_2[1][14] * (12288);



            //classifier2

            //10-14
            sum[2]=0;
            sum[2] = sum[2] + II_2[2][3] * (12288);
            sum[2] = sum[2] + -II_2[2][21] * (12288);



            //classifier3

            //10-14
            sum[3]=0;



            //classifier4

            //10-14
            sum[4]=0;



            //classifier5

            //10-14
            sum[5]=0;
            sum[5] = sum[5] + II_2[3][6] * (8192);
            sum[5] = sum[5] + -II_2[3][18] * (8192);



            //classifier6

            //10-14
            sum[6]=0;
            sum[6] = sum[6] + -II_2[4][5] * (-4096);
            sum[6] = sum[6] + +II_2[4][17] * (-4096);
            sum[6] = sum[6] + II_2[1][5] * (8192);
            sum[6] = sum[6] + -II_2[1][17] * (8192);
            sum[6] = sum[6] + -II_2[4][5] * (8192);
            sum[6] = sum[6] + +II_2[4][17] * (8192);



            //classifier7

            //10-14
            sum[7]=0;
            sum[7] = sum[7] + II_2[4][11] * (-4096);
            sum[7] = sum[7] + -II_2[4][15] * (-4096);



            //classifier8

            //10-14
            sum[8]=0;



            //classifier9

            //10-14
            sum[9]=0;
            sum[9] = sum[9] + -II_2[2][6] * (-4096);
            sum[9] = sum[9] + +II_2[2][18] * (-4096);
            sum[9] = sum[9] + -II_2[0][6] * (12288);
            sum[9] = sum[9] + +II_2[0][18] * (12288);



            //classifier10

            //10-14
            sum[10]=0;
            sum[10] = sum[10] + -II_2[1][6] * (-4096);
            sum[10] = sum[10] + +II_2[1][18] * (-4096);
            sum[10] = sum[10] + -II_2[1][10] * (12288);
            sum[10] = sum[10] + +II_2[1][14] * (12288);



            //classifier11

            //10-14
            sum[11]=0;
            sum[11] = sum[11] + II_2[2][1] * (12288);
            sum[11] = sum[11] + -II_2[2][20] * (12288);



            //classifier12

            //10-14
            sum[12]=0;



            //classifier13

            //10-14
            sum[13]=0;
            sum[13] = sum[13] + II_2[4][9] * (12288);
            sum[13] = sum[13] + -II_2[4][15] * (12288);



            //classifier14

            //10-14
            sum[14]=0;
            sum[14] = sum[14] + II_2[1][5] * (8192);
            sum[14] = sum[14] + -II_2[1][19] * (8192);



            //classifier15

            //10-14
            sum[15]=0;



            //classifier16

            //10-14
            sum[16]=0;
            sum[16] = sum[16] + II_2[1][13] * (-4096);
            sum[16] = sum[16] + -II_2[1][22] * (-4096);
            sum[16] = sum[16] + II_2[1][16] * (12288);
            sum[16] = sum[16] + -II_2[1][19] * (12288);



            //classifier17

            //10-14
            sum[17]=0;



            //classifier18

            //10-14
            sum[18]=0;



            //classifier19

            //10-14
            sum[19]=0;
            sum[19] = sum[19] + -II_2[4][2] * (-4096);
            sum[19] = sum[19] + +II_2[4][6] * (-4096);
            sum[19] = sum[19] + -II_2[4][4] * (8192);
            sum[19] = sum[19] + +II_2[4][6] * (8192);



            //classifier20

            //10-14
            sum[20]=0;
            sum[20] = sum[20] + -II_2[1][18] * (-4096);
            sum[20] = sum[20] + +II_2[1][24] * (-4096);
            sum[20] = sum[20] + -II_2[1][20] * (12288);
            sum[20] = sum[20] + +II_2[1][22] * (12288);



            //classifier21

            //10-14
            sum[21]=0;



            //classifier22

            //10-14
            sum[22]=0;



            //classifier23

            //10-14
            sum[23]=0;



            //classifier24

            //10-14
            sum[24]=0;
            sum[24] = sum[24] + II_2[3][5] * (8192);
            sum[24] = sum[24] + -II_2[3][19] * (8192);



            //classifier25

            //10-14
            sum[25]=0;



            //classifier26

            //10-14
            sum[26]=0;
            sum[26] = sum[26] + -II_2[4][5] * (-4096);
            sum[26] = sum[26] + +II_2[4][20] * (-4096);
            sum[26] = sum[26] + II_2[1][5] * (8192);
            sum[26] = sum[26] + -II_2[1][20] * (8192);
            sum[26] = sum[26] + -II_2[4][5] * (8192);
            sum[26] = sum[26] + +II_2[4][20] * (8192);



            //classifier27

            //10-14
            sum[27]=0;
            sum[27] = sum[27] + II_2[3][9] * (8192);
            sum[27] = sum[27] + -II_2[3][14] * (8192);



            //classifier28

            //10-14
            sum[28]=0;



            //classifier29

            //10-14
            sum[29]=0;
            sum[29] = sum[29] + II_2[2][6] * (8192);
            sum[29] = sum[29] + -II_2[2][9] * (8192);



            //classifier30

            //10-14
            sum[30]=0;



            //classifier31

            //10-14
            sum[31]=0;
            sum[31] = sum[31] + -II_2[2][5] * (-4096);
            sum[31] = sum[31] + +II_2[2][18] * (-4096);
            sum[31] = sum[31] + -II_2[0][5] * (12288);
            sum[31] = sum[31] + +II_2[0][18] * (12288);



            //classifier32

            //10-14
            sum[32]=0;



            //classifier33

            //10-14
            sum[33]=0;



            //classifier34

            //10-14
            sum[34]=0;



            //classifier35

            //10-14
            sum[35]=0;
            sum[35] = sum[35] + -II_2[2][5] * (8192);
            sum[35] = sum[35] + +II_2[2][12] * (8192);
            sum[35] = sum[35] + II_2[2][12] * (8192);
            sum[35] = sum[35] + -II_2[2][19] * (8192);



            //classifier36

            //10-14
            sum[36]=0;
            sum[36] = sum[36] + II_2[2][2] * (-4096);
            sum[36] = sum[36] + -II_2[2][23] * (-4096);



            //classifier37

            //10-14
            sum[37]=0;
            sum[37] = sum[37] + -II_2[1][8] * (-4096);
            sum[37] = sum[37] + +II_2[1][12] * (-4096);
            sum[37] = sum[37] + -II_2[1][10] * (8192);
            sum[37] = sum[37] + +II_2[1][12] * (8192);



            //classifier38

            //10-14
            sum[38]=0;
            sum[38] = sum[38] + II_2[3][2] * (-4096);
            sum[38] = sum[38] + -II_2[3][22] * (-4096);
            sum[38] = sum[38] + II_2[3][2] * (8192);
            sum[38] = sum[38] + -II_2[3][12] * (8192);



            //classifier39

            //10-14
            sum[39]=0;
            sum[39] = sum[39] + -II_2[4][0] * (-4096);
            sum[39] = sum[39] + +II_2[4][6] * (-4096);
            sum[39] = sum[39] + -II_2[4][2] * (12288);
            sum[39] = sum[39] + +II_2[4][4] * (12288);



            //classifier40

            //10-14
            sum[40]=0;



            //classifier41

            //10-14
            sum[41]=0;



            //classifier42

            //10-14
            sum[42]=0;
            sum[42] = sum[42] + -II_2[3][18] * (-4096);
            sum[42] = sum[42] + +II_2[3][24] * (-4096);
            sum[42] = sum[42] + -II_2[3][20] * (12288);
            sum[42] = sum[42] + +II_2[3][22] * (12288);



            //classifier43

            //10-14
            sum[43]=0;
            sum[43] = sum[43] + -II_2[4][0] * (-4096);
            sum[43] = sum[43] + +II_2[4][6] * (-4096);
            sum[43] = sum[43] + -II_2[4][2] * (12288);
            sum[43] = sum[43] + +II_2[4][4] * (12288);



            //classifier44

            //10-14
            sum[44]=0;
            sum[44] = sum[44] + -II_2[0][12] * (-4096);
            sum[44] = sum[44] + +II_2[0][16] * (-4096);
            sum[44] = sum[44] + -II_2[0][12] * (8192);
            sum[44] = sum[44] + +II_2[0][14] * (8192);



            //classifier45

            //10-14
            sum[45]=0;



            //classifier46

            //10-14
            sum[46]=0;
            sum[46] = sum[46] + -II_2[0][12] * (-4096);
            sum[46] = sum[46] + +II_2[0][16] * (-4096);
            sum[46] = sum[46] + -II_2[0][12] * (8192);
            sum[46] = sum[46] + +II_2[0][14] * (8192);



            //classifier47

            //10-14
            sum[47]=0;
            sum[47] = sum[47] + -II_2[0][8] * (-4096);
            sum[47] = sum[47] + +II_2[0][12] * (-4096);
            sum[47] = sum[47] + -II_2[0][10] * (8192);
            sum[47] = sum[47] + +II_2[0][12] * (8192);



            //classifier48

            //10-14
            sum[48]=0;
            sum[48] = sum[48] + -II_2[2][12] * (8192);
            sum[48] = sum[48] + +II_2[2][19] * (8192);
            sum[48] = sum[48] + II_2[2][5] * (8192);
            sum[48] = sum[48] + -II_2[2][12] * (8192);



            //classifier49

            //10-14
            sum[49]=0;
            sum[49] = sum[49] + II_2[0][1] * (-4096);
            sum[49] = sum[49] + -II_2[0][19] * (-4096);
            sum[49] = sum[49] + -II_2[2][1] * (-4096);
            sum[49] = sum[49] + +II_2[2][19] * (-4096);
            sum[49] = sum[49] + II_2[1][1] * (8192);
            sum[49] = sum[49] + -II_2[1][19] * (8192);
            sum[49] = sum[49] + -II_2[2][1] * (8192);
            sum[49] = sum[49] + +II_2[2][19] * (8192);



            //classifier50

            //10-14
            sum[50]=0;
            sum[50] = sum[50] + II_2[3][17] * (-4096);
            sum[50] = sum[50] + -II_2[3][21] * (-4096);
            sum[50] = sum[50] + II_2[3][17] * (8192);
            sum[50] = sum[50] + -II_2[3][19] * (8192);



            //classifier51

            //10-14
            sum[51]=0;
            sum[51] = sum[51] + -II_2[3][0] * (-4096);
            sum[51] = sum[51] + +II_2[3][6] * (-4096);
            sum[51] = sum[51] + -II_2[0][0] * (12288);
            sum[51] = sum[51] + +II_2[0][6] * (12288);

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
     		    if(factor == 12)
     		    {
     		  	  factor = 0;
     		    }
     	  }
       }

}


