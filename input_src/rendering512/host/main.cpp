// standard C/C++ headers
#include <cstdio>
#include <cstdlib>
#include <getopt.h>
#include <string>
#include <time.h>
#include <sys/time.h>

// benchmark headers
#include "typedefs.h"
#include "input_data.h"
#include "top.h"

#define INPUT_SIZE (NUM_3D_TRI/4)
#define OUTPUT_SIZE (NUM_FB/16)

// Results checking function
void check_results(bit512* output);

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
  for ( int i = 0; i < INPUT_SIZE; i++)
  {
    for (int j=0; j<4; j++){
      in(128*j+7,  128*j+0)   = triangle_3ds[4*i+j].x0;
      in(128*j+15, 128*j+8)   = triangle_3ds[4*i+j].y0;
      in(128*j+23, 128*j+16)  = triangle_3ds[4*i+j].z0;
      in(128*j+31, 128*j+24)  = triangle_3ds[4*i+j].x1;
      in(128*j+39, 128*j+32)  = triangle_3ds[4*i+j].y1;
      in(128*j+47, 128*j+40)  = triangle_3ds[4*i+j].z1;
      in(128*j+55, 128*j+48)  = triangle_3ds[4*i+j].x2;
      in(128*j+63, 128*j+56)  = triangle_3ds[4*i+j].y2;
      in(128*j+71, 128*j+64)  = triangle_3ds[4*i+j].z2;
      in(128*j+127,128*j+72)  = 0;
    }
    Input_1.write(in);
  }
 
  // run the kernel 
  gettimeofday(&start, NULL);
  top(Input_1, Output_1);
  gettimeofday(&end, NULL);

  // grab the data from output stream
  for(int i=0; i<OUTPUT_SIZE; i++){
    out[i] = Output_1.read();
  }

  // Check the output results
  check_results(out); 

  // print time
  long long elapsed = (end.tv_sec - start.tv_sec) * 1000000LL + end.tv_usec - start.tv_usec;   
  printf("elapsed time: %lld us\n", elapsed);


  return 0;
}


void check_results(bit512* output)
{
    bit8 frame_buffer_print[MAX_X][MAX_Y];

    // read result from the 32-bit output buffer
    for (int i=0; i<NUM_FB/16; i++){
      for(int j=0; j<64; j++){
        int n=i*64+j;
        int row = n/256;
        int col = n%256;
        frame_buffer_print[row][col] = output[i](8*j+7, 8*j);
      }
    }

  // print result
  {
    for (int j = MAX_X - 1; j >= 0; j -- )
    {
      for (int i = 0; i < MAX_Y; i ++ )
      {
        int pix;
        pix = frame_buffer_print[i][j].to_int();
        if (pix){
          std::cout << "1";
        }else{
          std::cout << "0";
        }
      }
      std::cout << std::endl;
    }
  }

}
