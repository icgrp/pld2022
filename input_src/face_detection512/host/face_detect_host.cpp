/*===============================================================*/
/*                                                               */
/*                       face_detect.cpp                         */
/*                                                               */
/*     Main host function for the Face Detection application.    */
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

#include "./top_sim.h"



// other headers
#include "utils.h"
#include "typedefs.h"
#include "check_result.h"

// data
#include "image0_320_240.h"

int main(int argc, char ** argv)
{
  printf("Face Detection Application\n");

  std::string outFile("");

  parse_sdsoc_command_line_args(argc, argv, outFile);

  // for this benchmark, input data is included in array Data
  // these are outputs
  int result_x[RESULT_SIZE];
  int result_y[RESULT_SIZE];
  int result_w[RESULT_SIZE];
  int result_h[RESULT_SIZE];
  int res_size = 0;

  // timers
  struct timeval start, end;

  // sdsoc host code
  #ifdef SDSOC
    // As the SDSoC generated data motion network does not support sending 320 X 240 images at once
    // We needed to send all the 240 rows using 240 iterations. The last invokation of detectFaces() does the actual face detection
    //for ( int i = 0; i < IMAGE_HEIGHT-1; i ++ )
      //face_detect(Data[i], result_x, result_y, result_w, result_h, &res_size);

    //gettimeofday(&start, 0);
    //unsigned long long clock = sds_clock_counter();

	hls::stream<ap_uint<32> > Input_1("main_in");
	hls::stream<ap_uint<32> > Output_1("main_out");
	int i, j, k;

	data_gen(Input_1);
    top_sim(Input_1, Output_1);
    printf("we should receive %d values\n", (unsigned int) Output_1.read());
    res_size = Output_1.read();
    res_size = Output_1.read();
    res_size = Output_1.read();
    res_size = Output_1.read();
    res_size = Output_1.read();
    res_size = Output_1.read();
    res_size = Output_1.read();
    OUT: for ( i = 0; i < RESULT_SIZE; i++){
    	bit128 Output_tmp;
    	Output_tmp(31,0)= Output_1.read();
    	Output_tmp(63,32)= Output_1.read();
    	Output_tmp(95,64)= Output_1.read();
    	Output_tmp(127,96)= Output_1.read();
    	result_x[i]=Output_tmp(31, 0);
    	result_y[i]=Output_tmp(63, 32);
    	result_w[i]=Output_tmp(95, 64);
    	result_h[i]=Output_tmp(127, 96);
    }
    //clock = sds_clock_counter() - clock;
    //gettimeofday(&end, 0);
  #endif



  // check results
  printf("Checking results:\n");
  check_results(res_size, result_x, result_y, result_w, result_h, Data, outFile);

  // print time
  //long long elapsed = (end.tv_sec - start.tv_sec) * 1000000LL + end.tv_usec - start.tv_usec;
  //long long elapsed = clock / 1199880;

  //printf("elapsed time: %lld ms\n", elapsed);


  return EXIT_SUCCESS;

}





