#include "../host/typedefs.h"

void sfilter1

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
  //static float factor=1.2;
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
  static unsigned char L_1[5][IMAGE_WIDTH]= {0};
  #pragma HLS array_partition variable=L_1 complete dim=1



  static int_I I_1[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=I_1 complete dim=0

  static int_I I_tmp = 0;

  /** Integral Image Window buffer ( 625 registers )*/
  static int_II II_1[5][WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=II_1 complete dim=0



  static int_SI SI_1[5][2*WINDOW_SIZE]= {0};
  #pragma HLS array_partition variable=SI_1 complete dim=0

  static int_SI SI_tmp = 0;
	/** Loop over each point in the Image ( scaled ) **/
	/* Updates for Integral Image Window Buffer (I) */
	/* Updates for Integral Image Window Buffer (I) */


	if(x==0 && y==0 && read_L == 0){

	  Initailize1v:
	  for ( j = 0; j < IMAGE_WIDTH ; j++){
#pragma HLS PIPELINE II=1



		  for ( i = 0; i < 5; i++ ){
#pragma HLS unroll
			  L_1[i][j] = 0;
		  }
	  }

	  for(j=0; j < WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( u = 0; u < 5; u++ ){
#pragma HLS unroll
			  II_1[u][j] = 0;
		  }
	  }

	  for(j=0; j < 2*WINDOW_SIZE; j++){
#pragma HLS unroll
		  for ( i = 0; i < 5 ; i++ ){
#pragma HLS unroll
			  I_1[i][j] = 0;
			  SI_1[i][j] = 0;
		  }
	  }

	  //f( IMAGE_WIDTH/factor > WINDOW_SIZE && IMAGE_HEIGHT/factor > WINDOW_SIZE )
	  //{
		//MySize sz = { (int)( IMAGE_WIDTH/factor ), (int)( IMAGE_HEIGHT/factor ) };
		height = height_list[factor];
		width  = width_list[factor];
	  //}
  }



  	if(read_L == 0){
  		Output_2.write(L_1[0][x]);
        Output_3.write(I_1[4][40]);
        Output_3.write(SI_1[4][40]);
  		read_L = 1;
  		return;
	}

  	if(read_L == 1){
  		data_in = Input_1.read();
  		read_L = 2;
  		return;
	}

	  read_L = 0;
	  ProcessII0v:
	  for ( v = 0; v < WINDOW_SIZE; v++ ){
#pragma HLS unroll
		  for ( u = 0; u < 5; u++){
#pragma HLS unroll
          II_1[u][v] = II_1[u][v] + ( I_1[u][v+1] - I_1[u][0] );
        }
      }


      ProcessI0v:
      for( j = 0; j < 2*WINDOW_SIZE-1; j++){
#pragma HLS unroll
    	if( j != 2*WINDOW_SIZE-6 ){
		  I_1[0][j] = I_1[0][j+1];
		  SI_1[0][j] = SI_1[0][j+1];
	  	}
		else {
		  I_1[0][j] = I_1[0][j+1] + Input_2.read();
		  SI_1[0][j] = SI_1[0][j+1] + Input_2.read();
		}
        for( i = 1; i < 5; i++ ){
        #pragma HLS unroll
          if( i+j != 2*WINDOW_SIZE-6 ){
            I_1[i][j] = I_1[i][j+1];
            SI_1[i][j] = SI_1[i][j+1];
          }
          else{
            I_1[i][j] = I_1[i][j+1] + I_1[i-1][j+1];
            SI_1[i][j] = SI_1[i][j+1] + SI_1[i-1][j+1];
          }
        }
      }




      /** Last column of the I[][] matrix **/
      ProcessLastI0v:
      for( i = 0; i < 5; i++ ){
      #pragma HLS unroll
        I_1[i][2*WINDOW_SIZE-1] = L_1[i][x];
        SI_1[i][2*WINDOW_SIZE-1] = L_1[i][x]*L_1[i][x];
      }


      ProcessLastL0v:
      for( k = 0; k < 4; k++ ){
      #pragma HLS unroll
        L_1[k][x] = L_1[k+1][x];
      }
      L_1[4][x] = data_in;





      /* Pass the Integral Image Window buffer through Cascaded Classifier. Only pass
       * when the integral image window buffer has flushed out the initial garbage data */
      if ( element_counter >= ( ( (WINDOW_SIZE-1)*width + WINDOW_SIZE ) + WINDOW_SIZE -1 ) ) {
	 /* Sliding Window should not go beyond the boundary */
         if ( x_index < ( width - (WINDOW_SIZE-1) ) && y_index < ( height - (WINDOW_SIZE-1) ) ){
             int sum[60]={0};
			#pragma HLS array_partition variable=sum complete dim=0
        	 //classifier0

             //5-9
             sum[0]=0;
             sum[0] = sum[0] + II_1[2][6] * (12288);
             sum[0] = sum[0] + -II_1[2][18] * (12288);



             //classifier1

             //5-9
             sum[1]=0;



             //classifier2

             //5-9
             sum[2]=0;
             sum[2] = sum[2] + II_1[4][3] * (-4096);
             sum[2] = sum[2] + -II_1[4][21] * (-4096);



             //classifier3

             //5-9
             sum[3]=0;



             //classifier4

             //5-9
             sum[4]=0;
             sum[4] = sum[4] + II_1[0][3] * (-4096);
             sum[4] = sum[4] + -II_1[0][7] * (-4096);
             sum[4] = sum[4] + II_1[0][5] * (8192);
             sum[4] = sum[4] + -II_1[0][7] * (8192);



             //classifier5

             //5-9
             sum[5]=0;
             sum[5] = sum[5] + II_1[0][6] * (-4096);
             sum[5] = sum[5] + -II_1[0][18] * (-4096);



             //classifier6

             //5-9
             sum[6]=0;
             sum[6] = sum[6] + II_1[3][5] * (-4096);
             sum[6] = sum[6] + -II_1[3][17] * (-4096);



             //classifier7

             //5-9
             sum[7]=0;



             //classifier8

             //5-9
             sum[8]=0;
             sum[8] = sum[8] + -II_1[1][4] * (-4096);
             sum[8] = sum[8] + +II_1[1][11] * (-4096);
             sum[8] = sum[8] + -II_1[1][4] * (8192);
             sum[8] = sum[8] + +II_1[1][11] * (8192);



             //classifier9

             //5-9
             sum[9]=0;
             sum[9] = sum[9] + II_1[1][6] * (-4096);
             sum[9] = sum[9] + -II_1[1][18] * (-4096);
             sum[9] = sum[9] + II_1[3][6] * (12288);
             sum[9] = sum[9] + -II_1[3][18] * (12288);



             //classifier10

             //5-9
             sum[10]=0;



             //classifier11

             //5-9
             sum[11]=0;
             sum[11] = sum[11] + II_1[3][1] * (-4096);
             sum[11] = sum[11] + -II_1[3][20] * (-4096);



             //classifier12

             //5-9
             sum[12]=0;
             sum[12] = sum[12] + -II_1[0][0] * (-4096);
             sum[12] = sum[12] + +II_1[0][24] * (-4096);
             sum[12] = sum[12] + -II_1[0][8] * (12288);
             sum[12] = sum[12] + +II_1[0][16] * (12288);



             //classifier13

             //5-9
             sum[13]=0;
             sum[13] = sum[13] + II_1[4][9] * (-4096);
             sum[13] = sum[13] + -II_1[4][15] * (-4096);



             //classifier14

             //5-9
             sum[14]=0;
             sum[14] = sum[14] + II_1[1][5] * (-4096);
             sum[14] = sum[14] + -II_1[1][19] * (-4096);



             //classifier15

             //5-9
             sum[15]=0;
             sum[15] = sum[15] + -II_1[4][5] * (-4096);
             sum[15] = sum[15] + +II_1[4][19] * (-4096);
             sum[15] = sum[15] + -II_1[1][5] * (12288);
             sum[15] = sum[15] + +II_1[1][19] * (12288);



             //classifier16

             //5-9
             sum[16]=0;



             //classifier17

             //5-9
             sum[17]=0;
             sum[17] = sum[17] + II_1[0][7] * (-4096);
             sum[17] = sum[17] + -II_1[0][13] * (-4096);
             sum[17] = sum[17] + II_1[0][9] * (12288);
             sum[17] = sum[17] + -II_1[0][11] * (12288);



             //classifier18

             //5-9
             sum[18]=0;
             sum[18] = sum[18] + II_1[3][10] * (-4096);
             sum[18] = sum[18] + -II_1[3][16] * (-4096);
             sum[18] = sum[18] + II_1[3][12] * (12288);
             sum[18] = sum[18] + -II_1[3][14] * (12288);



             //classifier19

             //5-9
             sum[19]=0;
             sum[19] = sum[19] + II_1[0][2] * (-4096);
             sum[19] = sum[19] + -II_1[0][6] * (-4096);
             sum[19] = sum[19] + II_1[0][4] * (8192);
             sum[19] = sum[19] + -II_1[0][6] * (8192);



             //classifier20

             //5-9
             sum[20]=0;



             //classifier21

             //5-9
             sum[21]=0;
             sum[21] = sum[21] + II_1[1][0] * (-4096);
             sum[21] = sum[21] + -II_1[1][24] * (-4096);
             sum[21] = sum[21] + II_1[1][8] * (12288);
             sum[21] = sum[21] + -II_1[1][16] * (12288);



             //classifier22

             //5-9
             sum[22]=0;
             sum[22] = sum[22] + II_1[1][9] * (-4096);
             sum[22] = sum[22] + -II_1[1][15] * (-4096);
             sum[22] = sum[22] + II_1[1][11] * (12288);
             sum[22] = sum[22] + -II_1[1][13] * (12288);



             //classifier23

             //5-9
             sum[23]=0;



             //classifier24

             //5-9
             sum[24]=0;
             sum[24] = sum[24] + II_1[2][5] * (-4096);
             sum[24] = sum[24] + -II_1[2][19] * (-4096);



             //classifier25

             //5-9
             sum[25]=0;
             sum[25] = sum[25] + -II_1[1][0] * (-4096);
             sum[25] = sum[25] + +II_1[1][24] * (-4096);
             sum[25] = sum[25] + -II_1[1][8] * (12288);
             sum[25] = sum[25] + +II_1[1][16] * (12288);



             //classifier26

             //5-9
             sum[26]=0;
             sum[26] = sum[26] + II_1[3][5] * (-4096);
             sum[26] = sum[26] + -II_1[3][20] * (-4096);



             //classifier27

             //5-9
             sum[27]=0;
             sum[27] = sum[27] + II_1[1][9] * (-4096);
             sum[27] = sum[27] + -II_1[1][14] * (-4096);



             //classifier28

             //5-9
             sum[28]=0;
             sum[28] = sum[28] + II_1[0][9] * (-4096);
             sum[28] = sum[28] + -II_1[0][15] * (-4096);
             sum[28] = sum[28] + II_1[0][11] * (12288);
             sum[28] = sum[28] + -II_1[0][13] * (12288);



             //classifier29

             //5-9
             sum[29]=0;
             sum[29] = sum[29] + II_1[1][6] * (-4096);
             sum[29] = sum[29] + -II_1[1][9] * (-4096);



             //classifier30

             //5-9
             sum[30]=0;



             //classifier31

             //5-9
             sum[31]=0;
             sum[31] = sum[31] + II_1[1][5] * (-4096);
             sum[31] = sum[31] + -II_1[1][18] * (-4096);
             sum[31] = sum[31] + II_1[3][5] * (12288);
             sum[31] = sum[31] + -II_1[3][18] * (12288);



             //classifier32

             //5-9
             sum[32]=0;



             //classifier33

             //5-9
             sum[33]=0;



             //classifier34

             //5-9
             sum[34]=0;
             sum[34] = sum[34] + II_1[3][0] * (-4096);
             sum[34] = sum[34] + -II_1[3][24] * (-4096);
             sum[34] = sum[34] + II_1[3][8] * (12288);
             sum[34] = sum[34] + -II_1[3][16] * (12288);



             //classifier35

             //5-9
             sum[35]=0;
             sum[35] = sum[35] + II_1[1][5] * (-4096);
             sum[35] = sum[35] + -II_1[1][19] * (-4096);
             sum[35] = sum[35] + II_1[1][5] * (8192);
             sum[35] = sum[35] + -II_1[1][12] * (8192);



             //classifier36

             //5-9
             sum[36]=0;



             //classifier37

             //5-9
             sum[37]=0;



             //classifier38

             //5-9
             sum[38]=0;



             //classifier39

             //5-9
             sum[39]=0;



             //classifier40

             //5-9
             sum[40]=0;



             //classifier41

             //5-9
             sum[41]=0;
             sum[41] = sum[41] + II_1[0][0] * (-4096);
             sum[41] = sum[41] + -II_1[0][22] * (-4096);
             sum[41] = sum[41] + II_1[0][11] * (8192);
             sum[41] = sum[41] + -II_1[0][22] * (8192);



             //classifier42

             //5-9
             sum[42]=0;



             //classifier43

             //5-9
             sum[43]=0;



             //classifier44

             //5-9
             sum[44]=0;



             //classifier45

             //5-9
             sum[45]=0;
             sum[45] = sum[45] + II_1[1][0] * (-4096);
             sum[45] = sum[45] + -II_1[1][19] * (-4096);
             sum[45] = sum[45] + -II_1[4][0] * (-4096);
             sum[45] = sum[45] + +II_1[4][19] * (-4096);
             sum[45] = sum[45] + II_1[2][0] * (12288);
             sum[45] = sum[45] + -II_1[2][19] * (12288);
             sum[45] = sum[45] + -II_1[3][0] * (12288);
             sum[45] = sum[45] + +II_1[3][19] * (12288);



             //classifier46

             //5-9
             sum[46]=0;



             //classifier47

             //5-9
             sum[47]=0;



             //classifier48

             //5-9
             sum[48]=0;
             sum[48] = sum[48] + II_1[0][5] * (-4096);
             sum[48] = sum[48] + -II_1[0][19] * (-4096);
             sum[48] = sum[48] + II_1[0][12] * (8192);
             sum[48] = sum[48] + -II_1[0][19] * (8192);



             //classifier49

             //5-9
             sum[49]=0;



             //classifier50

             //5-9
             sum[50]=0;



             //classifier51

             //5-9
             sum[51]=0;
             sum[51] = sum[51] + II_1[2][0] * (12288);
             sum[51] = sum[51] + -II_1[2][6] * (12288);



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



