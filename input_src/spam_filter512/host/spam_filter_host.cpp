/*===============================================================*/
/*                                                               */
/*                        spam_filter.cpp                        */
/*                                                               */
/*      Main host function for the Spam Filter application.      */
/*                                                               */
/*===============================================================*/

// standard C/C++ headers
#include <cstdio>
#include <cstdlib>
#include <getopt.h>
#include <string>
#include <time.h>
#include <sys/time.h>
#include <hls_stream.h>
#define SDSOC


#ifdef SDSOC
  // sdsoc headers
  //#include "sds_lib.h"
  // hardware function declaration
  #include "./top.h"
#endif


// other headers
#include "utils.h"
#include "typedefs.h"
#include "check_result.h"

  VectorDataType data_points_for_accel[NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE];
  VectorLabelType labels_for_accel[NUM_TRAINING / L_VECTOR_SIZE];
  VectorFeatureType param_for_accel[NUM_FEATURES / F_VECTOR_SIZE];

void add_1(hls::stream<ap_uint<32> > &in, hls::stream<ap_uint<32> > &out)  {
	int data_in;
	int data_out;
	int i;
	for (i = 0; i<8; i++)
	{
		data_in = in.read();
		data_out = data_in + 1;
		out.write(data_out);
	}


}

int main1(int argc, char *argv[])
{
	hls::stream<ap_uint<32> > in;
	hls::stream<ap_uint<32> > out;
	VectorDataType a; //64
	VectorLabelType b; //32
	VectorFeatureType c; //32

    int i;
    a.range(63, 32) = 255;
    a.range(31, 0) = 5;

    printf("a = %016x\n",  (long long)(a.range(63, 32)));

    return 0;



}

int main(int argc, char *argv[])
{
	hls::stream<ap_uint<32> > Input_1("sbb0");; //64
	VectorLabelType b; //32
	hls::stream<ap_uint<32> > Output_1("sbb1");; //64

  setbuf(stdout, NULL);


  // parse command line arguments
  std::string path_to_data("/home/ylxiao/rosetta/spam-filter/data");
  // sdaccel version and sdsoc/sw version have different command line options
  #ifdef OCL
    std::string kernelFile("");
    parse_sdaccel_command_line_args(argc, argv, kernelFile, path_to_data);
  #else
    parse_sdsoc_command_line_args(argc, argv, path_to_data);
  #endif

  // allocate space
  // for software verification
  DataType*    data_points  = new DataType[DATA_SET_SIZE];
  LabelType*   labels       = new LabelType  [NUM_SAMPLES];
  FeatureType* param_vector = new FeatureType[NUM_FEATURES];

  // read in dataset
  std::string str_points_filepath = path_to_data + "/shuffledfeats.dat";
  std::string str_labels_filepath = path_to_data + "/shuffledlabels.dat";


  FILE* data_file;
  FILE* label_file;

  data_file = fopen(str_points_filepath.c_str(), "r");


  if (!data_file)
  {
    printf("Failed to open data file %s!\n", str_points_filepath.c_str());
    return EXIT_FAILURE;
  }


  for (int i = 0; i < DATA_SET_SIZE; i ++ )
  {
    float tmp;
    fscanf(data_file, "%f", &tmp);
    data_points[i] = tmp;
  }
  fclose(data_file);

  label_file = fopen(str_labels_filepath.c_str(), "r");
  if (!label_file)
  {
    printf("Failed to open label file %s!\n", str_labels_filepath.c_str());
    return EXIT_FAILURE;
  }

  for (int i = 0; i < NUM_SAMPLES; i ++ )
  {
    int tmp;
    fscanf(label_file, "%d", &tmp);
    labels[i] = tmp;
  }
  fclose(label_file);

  // reset parameter vector
  for (size_t i = 0; i < NUM_FEATURES; i++)
    param_vector[i] = 0;

  // timers
  struct timeval start, end;

  // sdsoc version host code
  #ifdef SDSOC

    // allocate space for accelerator


    //VectorDataType data_points_for_accel[NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE];
    //VectorLabelType labels_for_accel[NUM_TRAINING / L_VECTOR_SIZE];
    //VectorFeatureType param_for_accel[NUM_FEATURES / F_VECTOR_SIZE];
 

    // reorganize data for the accelerator
    // data points

    for (int i = 0; i < NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE; i ++ )
      for (int j = 0; j < D_VECTOR_SIZE; j ++ )
        data_points_for_accel[i].range((j+1)*DTYPE_TWIDTH-1, j*DTYPE_TWIDTH) = data_points[i*D_VECTOR_SIZE+j].range(DTYPE_TWIDTH-1, 0);

    // labels
    for (int i = 0; i < NUM_TRAINING / L_VECTOR_SIZE; i ++ )
      for (int j = 0; j < L_VECTOR_SIZE; j ++ )
        labels_for_accel[i].range((j+1)*LTYPE_WIDTH-1, j*LTYPE_WIDTH) = labels[i*L_VECTOR_SIZE+j].range(LTYPE_WIDTH-1, 0);
  
    // parameter vector
    for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE; i ++ )
      for (int j = 0; j < F_VECTOR_SIZE; j ++ )
        param_for_accel[i].range((j+1)*FTYPE_TWIDTH-1, j*FTYPE_TWIDTH) = param_vector[i*F_VECTOR_SIZE+j].range(FTYPE_TWIDTH-1, 0);

    // run the accelerator
    gettimeofday(&start, NULL);


    // labels

    for (int epoch = 0; epoch < NUM_EPOCHS; epoch ++ )
    {
    	//Input_1.write(epoch);
    	if (epoch == 0){

      	    for (int i = 0; i < 486; i ++ ){
        	        Input_1.write(2);
        	        Input_1.write(2);
        	        Input_1.write(2);
        	        Input_1.write(2);
      	    }

    	    //for (int i = 0; i < NUM_TRAINING / L_VECTOR_SIZE; i ++ ){
      	    for (int i = 0; i < 282; i ++ ){
      	    	bit128 Input_tmp;
      	    	Input_tmp(31,0)   = labels_for_accel[4*i];
      	    	Input_tmp(63,32)  = labels_for_accel[4*i+1];
      	    	Input_tmp(95,64)  = labels_for_accel[4*i+2];
      	    	Input_tmp(127,96) = labels_for_accel[4*i+3];
    	    	Input_1.write(Input_tmp(31,0));
    	    	Input_1.write(Input_tmp(63,32));
    	    	Input_1.write(Input_tmp(95,64));
    	    	Input_1.write(Input_tmp(127,96));
    	    	//Input_1.write(1);
    	    	//printf("%08x\n", (int)(labels_for_accel[i]) );
    	    }


    	}

        for (int i = 0; i < NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE/2; i ++ )
        {
        	//printf("%08x\n", (int)(data_points_for_accel[i].range(31, 0)) );
        	//printf("%08x\n", (int)(data_points_for_accel[i].range(63, 31)) );
        	bit128 Input_tmp;
        	Input_tmp(31,0)   = data_points_for_accel[2*i].range(31, 0);
        	Input_tmp(63,32)  = data_points_for_accel[2*i].range(63, 32);
        	Input_tmp(95,64)  = data_points_for_accel[2*i+1].range(31, 0);
        	Input_tmp(127,96) = data_points_for_accel[2*i+1].range(63, 32);
        	Input_1.write(Input_tmp(31,0));
        	Input_1.write(Input_tmp(63,32));
        	Input_1.write(Input_tmp(95,64));
        	Input_1.write(Input_tmp(127,96));
        }

      printf("epoch %d...\n", epoch);
      top(Input_1, Output_1);
    }
    gettimeofday(&end, NULL);

    bit128 temp = Output_1.read();
    // parameter vector
    for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE / 2; i ++ )
    {
    	bit128 Output_tmp;
    	Output_tmp(31,0)= Output_1.read();
    	Output_tmp(63,32)= Output_1.read();
    	Output_tmp(95,64)= Output_1.read();
    	Output_tmp(127,96)= Output_1.read();
    	param_for_accel[2*i].range(31, 0) = Output_tmp(31, 0);
    	param_for_accel[2*i].range(63, 32) = Output_tmp(63, 32);
    	param_for_accel[2*i+1].range(31, 0) = Output_tmp(95, 64);
    	param_for_accel[2*i+1].range(63, 32) = Output_tmp(127, 96);
    }



    // reorganize the parameter vector
    for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE; i ++ )
      for (int j = 0; j < F_VECTOR_SIZE; j ++ )
        param_vector[i*F_VECTOR_SIZE+j].range(FTYPE_TWIDTH-1, 0) = param_for_accel[i].range((j+1)*FTYPE_TWIDTH-1, j*FTYPE_TWIDTH);

    #endif


  // check results
  printf("Checking results:\n");
  printf("We should get |   97.83   |    0.18   |     0.91    |  93.48   |   2.53   |    4.00    |\n");
  check_results( param_vector, data_points, labels );
    
  // print time
  long long elapsed = (end.tv_sec - start.tv_sec) * 1000000LL + end.tv_usec - start.tv_usec;   
  printf("elapsed time: %lld us\n", elapsed);



  delete []data_points;
  delete []labels;
  delete []param_vector;

  return EXIT_SUCCESS;
}




