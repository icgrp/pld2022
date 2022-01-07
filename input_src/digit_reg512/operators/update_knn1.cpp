#include "../host/typedefs.h"

static int popcount(WholeDigitType x)
{
  // most straightforward implementation
  // actually not bad on FPGA
  int cnt = 0;
  for (int i = 0; i < 256; i ++ )
  {
#pragma HLS unroll
    cnt = cnt + x(i,i);
  }
  return cnt;
}

static void update_knn( WholeDigitType test_inst, WholeDigitType train_inst, int min_distances[K_CONST] )
{
  #pragma HLS inline
#pragma HLS array_partition variable=min_distances complete dim=0


  // Compute the difference using XOR
  WholeDigitType diff = test_inst ^ train_inst;

  int dist = 0;

  dist = popcount(diff);

  int max_dist = 0;
  int max_dist_id = 0;
  int k = 0;

  // Find the max distance
  FIND_MAX_DIST: for ( int k = 0; k < K_CONST; ++k )
  {
    if ( min_distances[k] > max_dist )
    {
      max_dist = min_distances[k];
      max_dist_id = k;
    }
  }

  // Replace the entry with the max distance
  if ( dist < max_dist )
    min_distances[max_dist_id] = dist;

  return;
}


static void knn_vote_small( int knn_set[2 * K_CONST],
		                  int min_distance_list[K_CONST],
						  int label_list[K_CONST],
						  LabelType label_in)
{
  #pragma HLS inline
#pragma HLS array_partition variable=knn_set complete dim=0
  // final K nearest neighbors
  #pragma HLS array_partition variable=min_distance_list complete dim=0
  // labels for the K nearest neighbors
  #pragma HLS array_partition variable=label_list complete dim=0


  int pos = 1000;



  // go through all the lanes
  // do an insertion sort to keep a sorted neighbor list
  LANES: for (int i = 0; i < 2; i ++ )
  {
    INSERTION_SORT_OUTER: for (int j = 0; j < K_CONST; j ++ )
    {
      #pragma HLS pipeline
      pos = 1000;
      INSERTION_SORT_INNER: for (int r = 0; r < K_CONST; r ++ )
      {
        #pragma HLS unroll
        pos = (
        		(knn_set[i*K_CONST+j] < min_distance_list[r])
				&&
				(pos > K_CONST)
			  ) ? r : pos;
        //printf("i=%d, j=%d, r=%d, pos=%d\n", i, j, r, pos);
      }

      INSERT: for (int r = K_CONST ;r > 0; r -- )
      {
        #pragma HLS unroll
        if(r-1 > pos)
        {
          min_distance_list[r-1] = min_distance_list[r-2];
          label_list[r-1] = label_list[r-2];
        }
        else if (r-1 == pos)
        {
          min_distance_list[r-1] = knn_set[i*K_CONST+j];
          label_list[r-1] = label_in;
        }
      }
      //printf("min_distance_list[%d]=%d, min_distance_list[%d]=%d, min_distance_list[%d]=%d\n",0,
    	//	  min_distance_list[0],
		//	  1,
		//	  min_distance_list[1],
		//	  2,
		//	  min_distance_list[2]);
     // printf("label_list[%d]=%d, label_list[%d]=%d, label_list[%d]=%d\n",
    		//  0,
			//  label_list[0],
		//	  1,
		//	  label_list[1],
		//	  2,
		//	  label_list[2]);

    }
  }
}



#define NUM1 1
void update_knn1(hls::stream<ap_uint<512> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Output_1

static WholeDigitType training_set [NUM_TRAINING / PAR_FACTOR_NEW];
#pragma HLS array_partition variable=training_set block factor=2 dim=0

static WholeDigitType test_instance;
bit32 tmp;

static int knn_set[K_CONST*2];
#pragma HLS array_partition variable=knn_set complete dim=0

static bit512 in_tmp;

WholeDigitType data_temp;
static int index = 0;

  if (index == 0)
  {
	  //Store the local training set
	  STORE_LOCAL: for(int i = 0; i < NUM_TRAINING / PAR_FACTOR_NEW / 2; i++)
	  {
#pragma HLS pipeline
                in_tmp = Input_1.read();
		training_set[2*i  ](255, 224) =in_tmp(31,    0);
		training_set[2*i  ](223, 192) =in_tmp(63,   32);
		training_set[2*i  ](191, 160) =in_tmp(95,   64);
		training_set[2*i  ](159, 128) =in_tmp(127,  96);
		training_set[2*i  ](127,  96) =in_tmp(159, 128);
		training_set[2*i  ](95,   64) =in_tmp(191, 160);
		training_set[2*i  ](63,   32) =in_tmp(223, 192);
		training_set[2*i  ](31,    0) =in_tmp(255, 224);
		training_set[2*i+1](255, 224) =in_tmp(287, 256);
		training_set[2*i+1](223, 192) =in_tmp(319, 288);
		training_set[2*i+1](191, 160) =in_tmp(351, 320);
		training_set[2*i+1](159, 128) =in_tmp(383, 352);
		training_set[2*i+1](127,  96) =in_tmp(415, 384);
		training_set[2*i+1](95,   64) =in_tmp(447, 416);
		training_set[2*i+1](63,   32) =in_tmp(479, 448);
		training_set[2*i+1](31,    0) =in_tmp(511, 480);
        
                //for (int j=0; j<8; j++){
                //  printf("#%d=%08x\n", i*8+j, (unsigned int) training_set[i]((7-j)*32+31, (7-j)*32));
                //}
	  }

	  //Transit the training sets for other pages
	  TRANSFER_LOOP: for(int i = 0; i < NUM_TRAINING / PAR_FACTOR_NEW * (PAR_FACTOR_NEW - NUM1)/2; i++)
	  {
#pragma HLS pipeline
                in_tmp = Input_1.read();
		tmp(31, 0) = in_tmp(31,    0); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(63,   32); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(95,   64); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(127,  96); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(159, 128); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(191, 160); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(223, 192); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(255, 224); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(287, 256); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(319, 288); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(351, 320); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(383, 352); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(415, 384); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(447, 416); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(479, 448); Output_1.write(tmp);
		tmp(31, 0) = in_tmp(511, 480); Output_1.write(tmp);
	  }
	  index = 1;
  }


  if(index%2 == 1){
    in_tmp = Input_1.read();
    test_instance(255, 224) = in_tmp(31,    0);
    test_instance(223, 192) = in_tmp(63,   32);
    test_instance(191, 160) = in_tmp(95,   64);
    test_instance(159, 128) = in_tmp(127,  96);
    test_instance(127,  96) = in_tmp(159, 128);
    test_instance(95,   64) = in_tmp(191, 160);
    test_instance(63,   32) = in_tmp(223, 192);
    test_instance(31,    0) = in_tmp(255, 224);
    tmp(31,0) = test_instance(255, 224);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(223, 192);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(191, 160);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(159, 128);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(127,  96);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(95,   64);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(63,   32);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(31,    0);
    Output_1.write(tmp);
  }else{
    test_instance(255, 224) = in_tmp(287,  256);
    test_instance(223, 192) = in_tmp(319,  288);
    test_instance(191, 160) = in_tmp(351,  320);
    test_instance(159, 128) = in_tmp(383, 352);
    test_instance(127,  96) = in_tmp(415, 384);
    test_instance(95,   64) = in_tmp(447, 416);
    test_instance(63,   32) = in_tmp(479, 448);
    test_instance(31,    0) = in_tmp(511, 480);
    tmp(31,0) = test_instance(255, 224);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(223, 192);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(191, 160);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(159, 128);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(127,  96);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(95,   64);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(63,   32);
    Output_1.write(tmp);
    tmp(31,0) = test_instance(31,    0);
    Output_1.write(tmp);
  }
  

  int min_distance_list[K_CONST];
#pragma HLS array_partition variable=min_distance_list complete dim=0

  int label_list[K_CONST];
#pragma HLS array_partition variable=label_list complete dim=0



  for(int i=0; i<K_CONST; i++)
  {
#pragma HLS unroll
	  min_distance_list[i] = 256;
	  label_list[i] = 0;
  }

  // Initialize the knn set
   SET_KNN_SET: for ( int i = 0; i < K_CONST * 2 ; ++i )
   {
#pragma HLS unroll
     // Note that the max distance is 256
     knn_set[i] = 256;
   }

   TRAINING_LOOP : for ( int i = 0; i < NUM_TRAINING / PAR_FACTOR; ++i )
   {
       #pragma HLS pipeline
       LANES : for ( int j = 0; j < 2; j++ )
       {
         #pragma HLS unroll
         WholeDigitType training_instance = training_set[j * NUM_TRAINING / PAR_FACTOR + i];
         update_knn( test_instance, training_instance, &knn_set[j * K_CONST] );
       }
   }

#ifdef DEBUG
   printf("knn_update1");
   for(int i=0; i<6; i++){
   	printf("knn_set[%d]=%d,", i, knn_set[i]);
   }
   printf("\n");
#endif

   //update min_distance_list and label_list according to the new knn_set
   LabelType label_in = 0;
   knn_vote_small(knn_set, min_distance_list, label_list, label_in);

   bit128 output_tmp1, output_tmp2;

   for(int i=0; i<K_CONST; i++)
   {
#pragma HLS unroll
	   output_tmp1(i*32+31, i*32) = min_distance_list[i];
	   output_tmp2(i*32+31, i*32) = label_list[i];
   }


   tmp(31,0) = output_tmp1(127,96);
   Output_1.write(tmp);
   tmp(31,0) = output_tmp1(95, 64);
   Output_1.write(tmp);
   tmp(31,0) = output_tmp1(63, 32);
   Output_1.write(tmp);
   tmp(31,0) = output_tmp1(31,  0);
   Output_1.write(tmp);
   tmp(31,0) = output_tmp2(127,96);
   Output_1.write(tmp);
   tmp(31,0) = output_tmp2(95, 64);
   Output_1.write(tmp);
   tmp(31,0) = output_tmp2(63, 32);
   Output_1.write(tmp);
   tmp(31,0) = output_tmp2(31,  0);
   Output_1.write(tmp);

  index++;
  return;
}
