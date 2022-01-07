// standard C/C++ headers
#include <cstdio>
#include <cstdlib>
#include <getopt.h>
#include <string>
#include <time.h>
#include <sys/time.h>

// benchmark headers
#include "typedefs.h"
#include "label.h"
#include "top.h"

#define INPUT_SIZE (IMAGE_NUM*2048/16)
#define OUTPUT_SIZE (IMAGE_NUM)


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
 
  // The input and output variables for top kernel 
  hls::stream< bit512 > Input_1("kernel_in");
  hls::stream< bit512 > Output_1("kernel_out");
 
  // Prepare the input data 
  std::string path_to_data("/home/ylxiao/ws_211/prflow_riscv/input_src/bnn512/host");

  // allocate space
  // for software verification

  // read in dataset
  std::string str_points_filepath = path_to_data + "/data.dat";
  FILE* data_file;
  data_file = fopen(str_points_filepath.c_str(), "r");
  if (!data_file) {
    printf("Failed to open data file %s!\n", str_points_filepath.c_str());
    return EXIT_FAILURE;
  }

  for (int i = 0; i < INPUT_SIZE; i ++ )
  {
    for(int j=0; j<16; j++){
      bit32 tmp;
      fscanf(data_file, "%x", &tmp);
      in(32*j+31, 32*j) = tmp;
    }
    Input_1.write(in);
  }
  fclose(data_file);


 
  // run the kernel 
  gettimeofday(&start, NULL);
  top(Input_1, Output_1);
  gettimeofday(&end, NULL);

  // grab the data from output stream
  for(int i=0; i<OUTPUT_SIZE; i++){
    out[i] = Output_1.read();
  }

  // Check the output results
  bool match = true;
  int error_cnt = 0; 
    
  for(int i=0; i<IMAGE_NUM; i++){
      int result = (unsigned int) out[i](31, 0); 
      if(result != y[i]){
        printf("Pred/Label: %d/%d [Fail]\n", result, y[i]);
        error_cnt++;
      } else {
        printf("Pred/Label: %d/%d [ OK ]\n", result, y[i]);
      }
  }
  printf("We got error rate %d/%d\n", error_cnt, IMAGE_NUM);
  std::cout << "TEST " << (match ? "PASSED" : "FAILED") << std::endl;
  return (match ? EXIT_SUCCESS : EXIT_FAILURE);

  // print time
  long long elapsed = (end.tv_sec - start.tv_sec) * 1000000LL + end.tv_usec - start.tv_usec;   
  printf("elapsed time: %lld us\n", elapsed);
  return 0;
}


