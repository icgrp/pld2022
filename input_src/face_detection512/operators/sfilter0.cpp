#include "../host/typedefs.h"

void sfilter0

(
  hls::stream<ap_uint<32> > & Input_1,
  hls::stream<ap_uint<704> > & Output_1,
  hls::stream<ap_uint<64> > & Output_2
)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2

  static unsigned char data_in = 0;
  int u,v;
  int i,j,k;
  static unsigned char  factor=0;
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
  bit64 out_tmp;

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
  #pragma HLS array_partition variable=SII complete dim=1




  if(x==0 && y==0){

    SII[0][0] = 0;
    SII[0][1] = 0;

	Initailize0II:
	for ( j = 0; j < IMAGE_WIDTH ; j++){//IMAGE_WIDTH; x++ ){
#pragma HLS PIPELINE II=1
		for ( i = 0; i < 5; i++ ){
#pragma HLS unroll
			L_0[i][j] = 0;
		}


	}

	for (j=0; j< WINDOW_SIZE; j++){
#pragma HLS unroll
		for ( u = 0; u < 5; u++ ){
#pragma HLS unroll
			II_0[u][j] = 0;
		}
	}


	for (j=0; j < 2*WINDOW_SIZE; j++){
#pragma HLS unroll
		for ( i = 0; i < 5 ; i++ ){
#pragma HLS unroll
			I_0[i][j] = 0;
			SI_0[i][j] = 0;
		}
	}



	  //if( IMAGE_WIDTH/factor > WINDOW_SIZE && IMAGE_HEIGHT/factor > WINDOW_SIZE )
	  //{
		//winSize.width = myRound(winSize0.width*factor);
		//winSize.height= myRound(winSize0.height*factor);
		//MySize sz = { (int)( IMAGE_WIDTH/factor ), (int)( IMAGE_HEIGHT/factor ) };
		height = height_list[factor];
		width  = width_list[factor];
	  //}
  }


  /** Loop over each point in the Image ( scaled ) **/

	/* Updates for Integral Image Window Buffer (I) */
	/* Updates for Integral Image Window Buffer (I) */
	if(read_L == 0){
          out_tmp(12, 0 ) =  I_0[4][45](12, 0);
          out_tmp(52, 32) = SI_0[4][45](20, 0);
          Output_2.write(out_tmp);
          read_L = 1;
          return;
	}

	if(read_L == 1){
          data_in = Input_1.read();
          read_L = 2;
          return;
	}
	read_L = 0;

	Process0II:
	for ( v = 0; v < WINDOW_SIZE; v++ ){
#pragma HLS unroll
		for ( u = 0; u < 5; u++){
#pragma HLS unroll
			II_0[u][v] = II_0[u][v] + ( I_0[u][v+1] - I_0[u][0] );
		}
	}



      /* Updates for Square Image Window Buffer (SI) */
      SII[0][0] = SII[0][0] + ( SI_0[0][1] - SI_0[0][0] );
      SII[0][1] = SII[0][1] + ( SI_0[0][WINDOW_SIZE] - SI_0[0][0] );

      int stddev = SII[0][0] - SII[0][1];
      int mean = II_0[0][0] - II_0[0][24];


      // out_tmp(12, 0 ) =  I_0[4][45](12, 0);
      // out_tmp(52, 32) = SI_0[4][45](20, 0);
      // Output_2.write(out_tmp);

      Process0ISI:
      for( j = 0; j < 2*WINDOW_SIZE-1; j++){
#pragma HLS unroll
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
      Process0ISILast:
      for( i = 0; i < 5; i++ ){
      #pragma HLS unroll
        I_0[i][2*WINDOW_SIZE-1] = L_0[i][x];
        SI_0[i][2*WINDOW_SIZE-1] = L_0[i][x]*L_0[i][x];
      }

      Process0L:
      for( k = 0; k < 4; k++ ){
      #pragma HLS unroll
        L_0[k][x] = L_0[k+1][x];
      }
      //L_0[4][x] = L_1[0][x];
      L_0[4][x] = data_in;


      /* Pass the Integral Image Window buffer through Cascaded Classifier. Only pass
       * when the integral image window buffer has flushed out the initial garbage data */
      if ( element_counter >= ( ( (WINDOW_SIZE-1)*width + WINDOW_SIZE ) + WINDOW_SIZE -1 ) ) {
	 /* Sliding Window should not go beyond the boundary */
         if ( x_index < ( width - (WINDOW_SIZE-1) ) && y_index < ( height - (WINDOW_SIZE-1) ) ){

            //classifier0
        	//ap_int<32>  sum[52]={0};
        	int sum[60]={0};
			#pragma HLS array_partition variable=sum complete dim=0
            //0-4
            int sum_0_0=0;
            sum[0] = 0;
            sum[0] = sum[0] + II_0[4][6] * (-4096);
            sum[0] = sum[0] + -II_0[4][18] * (-4096);



            //classifier1

            //0-4
            sum[1] = 0;
            sum[1] = sum[1] + II_0[4][6] * (-4096);
            sum[1] = sum[1] + -II_0[4][18] * (-4096);
            sum[1] = sum[1] + II_0[4][10] * (12288);
            sum[1] = sum[1] + -II_0[4][14] * (12288);



            //classifier2

            //0-4
            sum[2]=0;



            //classifier3

            //0-4
            sum[3]=0;



            //classifier4

            //0-4
            sum[4]=0;



            //classifier5

            //0-4
            sum[5]=0;



            //classifier6

            //0-4
            sum[6]=0;



            //classifier7

            //0-4
            sum[7]=0;



            //classifier8

            //0-4
            sum[8] = 0;
            sum[8] = sum[8] + II_0[0][4] * (-4096);
            sum[8] = sum[8] + -II_0[0][11] * (-4096);
            sum[8] = sum[8] + II_0[3][4] * (8192);
            sum[8] = sum[8] + -II_0[3][11] * (8192);



            //classifier9

            //0-4
            sum[9]=0;



            //classifier10

            //0-4
            sum[10] = 0;
            sum[10] = sum[10] + II_0[4][6] * (-4096);
            sum[10] = sum[10] + -II_0[4][18] * (-4096);
            sum[10] = sum[10] + II_0[4][10] * (12288);
            sum[10] = sum[10] + -II_0[4][14] * (12288);



            //classifier11

            //0-4
            sum[11]=0;



            //classifier12

            //0-4
            sum[12] = 0;
            sum[12] = sum[12] + II_0[2][0] * (-4096);
            sum[12] = sum[12] + -II_0[2][24] * (-4096);
            sum[12] = sum[12] + II_0[2][8] * (12288);
            sum[12] = sum[12] + -II_0[2][16] * (12288);



            //classifier13

            //0-4
            sum[13]=0;



            //classifier14

            //0-4
            sum[14]=0;



            //classifier15

            //0-4
            sum[15] = 0;
            sum[15] = sum[15] + II_0[0][5] * (-4096);
            sum[15] = sum[15] + -II_0[0][19] * (-4096);
            sum[15] = sum[15] + II_0[3][5] * (12288);
            sum[15] = sum[15] + -II_0[3][19] * (12288);



            //classifier16

            //0-4
            sum[16]=0;



            //classifier17

            //0-4
            sum[17]=0;



            //classifier18

            //0-4
            sum[18]=0;



            //classifier19

            //0-4
            sum[19]=0;



            //classifier20

            //0-4
            sum[20] = 0;
            sum[20] = sum[20] + II_0[0][18] * (-4096);
            sum[20] = sum[20] + -II_0[0][24] * (-4096);
            sum[20] = sum[20] + II_0[0][20] * (12288);
            sum[20] = sum[20] + -II_0[0][22] * (12288);



            //classifier21

            //0-4
            sum[21]=0;



            //classifier22

            //0-4
            sum[22]=0;



            //classifier23

            //0-4
            sum[23]=0;



            //classifier24

            //0-4
            sum[24]=0;



            //classifier25

            //0-4
            sum[25] = 0;
            sum[25] = sum[25] + II_0[3][0] * (-4096);
            sum[25] = sum[25] + -II_0[3][24] * (-4096);
            sum[25] = sum[25] + II_0[3][8] * (12288);
            sum[25] = sum[25] + -II_0[3][16] * (12288);



            //classifier26

            //0-4
            sum[26]=0;



            //classifier27

            //0-4
            sum[27]=0;



            //classifier28

            //0-4
            sum[28]=0;



            //classifier29

            //0-4
            sum[29]=0;



            //classifier30

            //0-4
            sum[30]=0;



            //classifier31

            //0-4
            sum[31]=0;



            //classifier32

            //0-4
            sum[32] = 0;
            sum[32] = sum[32] + II_0[1][18] * (-4096);
            sum[32] = sum[32] + -II_0[1][24] * (-4096);
            sum[32] = sum[32] + II_0[1][18] * (8192);
            sum[32] = sum[32] + -II_0[1][21] * (8192);



            //classifier33

            //0-4
            sum[33] = 0;
            sum[33] = sum[33] + II_0[1][1] * (-4096);
            sum[33] = sum[33] + -II_0[1][7] * (-4096);
            sum[33] = sum[33] + II_0[1][4] * (8192);
            sum[33] = sum[33] + -II_0[1][7] * (8192);



            //classifier34

            //0-4
            sum[34]=0;



            //classifier35

            //0-4
            sum[35]=0;



            //classifier36

            //0-4
            sum[36]=0;



            //classifier37

            //0-4
            sum[37] = 0;
            sum[37] = sum[37] + II_0[1][8] * (-4096);
            sum[37] = sum[37] + -II_0[1][12] * (-4096);
            sum[37] = sum[37] + II_0[1][10] * (8192);
            sum[37] = sum[37] + -II_0[1][12] * (8192);



            //classifier38

            //0-4
            sum[38]=0;



            //classifier39

            //0-4
            sum[39] = 0;
            sum[39] = sum[39] + II_0[1][0] * (-4096);
            sum[39] = sum[39] + -II_0[1][6] * (-4096);
            sum[39] = sum[39] + II_0[1][2] * (12288);
            sum[39] = sum[39] + -II_0[1][4] * (12288);



            //classifier40

            //0-4
            sum[40] = 0;
            sum[40] = sum[40] + II_0[2][20] * (-4096);
            sum[40] = sum[40] + -II_0[2][24] * (-4096);
            sum[40] = sum[40] + II_0[2][20] * (8192);
            sum[40] = sum[40] + -II_0[2][22] * (8192);



            //classifier41

            //0-4
            sum[41]=0;



            //classifier42

            //0-4
            sum[42] = 0;
            sum[42] = sum[42] + II_0[4][18] * (-4096);
            sum[42] = sum[42] + -II_0[4][24] * (-4096);
            sum[42] = sum[42] + II_0[4][20] * (12288);
            sum[42] = sum[42] + -II_0[4][22] * (12288);



            //classifier43

            //0-4
            sum[43] = 0;
            sum[43] = sum[43] + II_0[3][0] * (-4096);
            sum[43] = sum[43] + -II_0[3][6] * (-4096);
            sum[43] = sum[43] + II_0[3][2] * (12288);
            sum[43] = sum[43] + -II_0[3][4] * (12288);



            //classifier44

            //0-4
            sum[44] = 0;
            sum[44] = sum[44] + II_0[1][12] * (-4096);
            sum[44] = sum[44] + -II_0[1][16] * (-4096);
            sum[44] = sum[44] + II_0[1][12] * (8192);
            sum[44] = sum[44] + -II_0[1][14] * (8192);



            //classifier45

            //0-4
            sum[45]=0;



            //classifier46

            //0-4
            sum[46] = 0;
            sum[46] = sum[46] + II_0[1][12] * (-4096);
            sum[46] = sum[46] + -II_0[1][16] * (-4096);
            sum[46] = sum[46] + II_0[1][12] * (8192);
            sum[46] = sum[46] + -II_0[1][14] * (8192);



            //classifier47

            //0-4
            sum[47] = 0;
            sum[47] = sum[47] + II_0[1][8] * (-4096);
            sum[47] = sum[47] + -II_0[1][12] * (-4096);
            sum[47] = sum[47] + II_0[1][10] * (8192);
            sum[47] = sum[47] + -II_0[1][12] * (8192);



            //classifier48

            //0-4
            sum[48]=0;



            //classifier49

            //0-4
            sum[49]=0;



            //classifier50

            //0-4
            sum[50]=0;



            //classifier51

            //0-4
            sum[51] = 0;
            sum[51] = sum[51] + II_0[4][0] * (-4096);
            sum[51] = sum[51] + -II_0[4][6] * (-4096);


            ap_uint<704> out_tmp;

             out_tmp(31,0) = (ap_int<32>) stddev;
             out_tmp(63,32) = (ap_int<32>) mean;

             for(i=0; i<52; i++){
#pragma HLS unroll
               out_tmp(i*12+75, i*12+64) = (ap_int<12>) (sum[i]/1048576);
             }
             Output_1.write(out_tmp);

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
     		  factor ++;
     		    if(factor == 12)
     		    {
     		  	  factor = 0;
     		    }
     	  }
       }

}


