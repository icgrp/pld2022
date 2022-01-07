// standard C/C++ headers
#include <cstdio>
#include <cstdlib>
#include <getopt.h>
#include <string>
#include <time.h>
#include <sys/time.h>

// benchmark headers
#include "typedefs.h"
#include "training_data.h"
#include "testing_data.h"
#include "top.h"

#define INPUT_SIZE ((NUM_TRAINING + NUM_TEST) * 8 / 16)
#define OUTPUT_SIZE (NUM_TEST / 16)

// Results checking function
void check_results(bit512* result, const LabelType* expected, int cnt);

// ------------------------------------------------------------------------------------
// Main program
// ------------------------------------------------------------------------------------
int main(int argc, char **argv)
{
  // Variables for time measurement
  struct timeval start, end;

  // Input and output temporary variables
  bit512 in;
  bit512 out[OUTPUT_SIZE];
  bit512 in2[INPUT_SIZE];
  bit512 out2[OUTPUT_SIZE];
 
  // The input and output variables for top kernel 
  hls::stream< bit512 > Input_1("kernel_in");
  hls::stream< bit512 > Output_1("kernel_out");
 
  // Prepare the input data 
  for (int i = 0; i < NUM_TRAINING; i ++ )
  {
    WholeDigitType tmp;
    WholeDigitType tmp_in;
    tmp.range(63 , 0  ) = training_data[i*DIGIT_WIDTH+0];
    tmp.range(127, 64 ) = training_data[i*DIGIT_WIDTH+1];
    tmp.range(191, 128) = training_data[i*DIGIT_WIDTH+2];
    tmp.range(255, 192) = training_data[i*DIGIT_WIDTH+3];
    for(int j=0; j<8; j++){
  	  tmp_in.range(j*32+31, j*32) = tmp.range((7-j)*32+31, (7-j)*32);
    }
    int offset = i % 2;
    in2[i/2](offset*256+255, offset*256) = tmp_in(255, 0);
  }

  for (int i = 0; i < NUM_TEST; i ++ )
  {
    WholeDigitType tmp;
    WholeDigitType tmp_in;
    tmp.range(63 , 0  ) = testing_data[i*DIGIT_WIDTH+0];
    tmp.range(127, 64 ) = testing_data[i*DIGIT_WIDTH+1];
    tmp.range(191, 128) = testing_data[i*DIGIT_WIDTH+2];
    tmp.range(255, 192) = testing_data[i*DIGIT_WIDTH+3];
    for(int j=0; j<8; j++){
  	  tmp_in.range(j*32+31, j*32) = tmp.range((7-j)*32+31, (7-j)*32);
    }
    int offset = i % 2;
    in2[i/2+NUM_TRAINING/2](offset*256+255, offset*256) = tmp_in(255, 0);
  }



 
  // run the kernel 
  gettimeofday(&start, NULL);
  top_top(in2, out2);
  gettimeofday(&end, NULL);

  // grab the data from output stream
  // for(int i=0; i<OUTPUT_SIZE; i++){
  //   out2[i] = Output_1.read();
  // }

  // Check the output results
  check_results(out2, expected, NUM_TEST );

  // print time
  long long elapsed = (end.tv_sec - start.tv_sec) * 1000000LL + end.tv_usec - start.tv_usec;   
  printf("elapsed time: %lld us\n", elapsed);


  return 0;
}


void check_results(bit512* result, const LabelType* expected, int cnt)
{
  int correct_cnt = 0;

  //std::ofstream ofile;
  //ofile.open("outputs.txt");
  //if (ofile.is_open())
  {
    for (int i = 0; i < cnt; i ++ )
    {
      LabelType tmp;
      int offset = i % 64;
      tmp = result[i/64](offset*8+7, offset*8);
      printf("result[%d](%d, %d) = %d\n",  i/64, offset*8+7, offset*8, (unsigned int) tmp);
      std::cout << "Test " << i << ": expected = " << int(expected[i]) << ", result = " << int(result[i/64]) << std::endl;
      if (tmp != expected[i])
        ;
        //std::cout << "Test " << i << ": expected = " << int(expected[i]) << ", result = " << int(result[i/16]) << std::endl;
      else
        correct_cnt ++;
    }

    std::cout << "\n\t " << correct_cnt << " / " << cnt << " correct!" << std::endl;
  }
  //else
  //{
  //  std::cout << "Failed to create output file!" << std::endl;
  //}


}
