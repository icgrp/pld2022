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
//#define SDSOC


// other headers
#include "typedefs.h"

#include "top.h"
// data
#include "image0_320_240.h"

#define MYDEBUG

char* strrev(char* str)
{
  char *p1, *p2;
  if (!str || !*str)
  	return str;
  for (p1 = str, p2 = str + strlen(str) - 1; p2 > p1; ++p1, --p2)
  {
  	*p1 ^= *p2;
  	*p2 ^= *p1;
  	*p1 ^= *p2;
  }
  return str;
}

void itochar(int x, char* szBuffer, int radix)
{
  int i = 0, n, xx;
  n = x;
  while (n > 0)
  {
  	xx = n%radix;
  	n = n/radix;
  	szBuffer[i++] = '0' + xx;
  }
  szBuffer[i] = '\0';
  strrev(szBuffer);
}

/* Writes a Pgm file using the hex image */
int writePgm(const char *fileName, unsigned char Data[IMAGE_HEIGHT][IMAGE_WIDTH] )
{
  char parameters_str[5];
  int i;
  const char *format = "P5";
  FILE *fp = fopen(fileName, "w");

  if (!fp){
    printf("Unable to open file %s\n", fileName);
    return -1;
  }

  fputs(format, fp);
  fputc('\n', fp);

  itochar(IMAGE_WIDTH, parameters_str, 10);
  fputs(parameters_str, fp);
  parameters_str[0] = 0;
  fputc(' ', fp);

  itochar(IMAGE_HEIGHT, parameters_str, 10);
  fputs(parameters_str, fp);
  parameters_str[0] = 0;
  fputc('\n', fp);

  itochar(IMAGE_MAXGREY, parameters_str, 10);
  fputs(parameters_str, fp);
  fputc('\n', fp);

  for (i = 0; i < IMAGE_HEIGHT; i++)
    for (int j = 0; j < IMAGE_WIDTH ; j++)
       fputc(Data[i][j], fp);

  fclose(fp);
  return 0;
}

/* draw white bounding boxes around detected faces */
void drawRectangle(unsigned char Data[IMAGE_HEIGHT][IMAGE_WIDTH], MyRect r)
{
  int i;
  int col = IMAGE_WIDTH;

  for (i = 0; i < r.width; i++)
    Data[r.y][r.x + i] = 255;
  for (i = 0; i < r.height; i++)
    Data[r.y+i][r.x + r.width] = 255;
  for (i = 0; i < r.width; i++)
    Data[r.y + r.height][r.x + r.width - i] = 255;
  for (i = 0; i < r.height; i++)
    Data[r.y + r.height - i][r.x] = 255;
}


void check_results(int &result_size,
                   int result_x[RESULT_SIZE],
                   int result_y[RESULT_SIZE],
                   int result_w[RESULT_SIZE],
                   int result_h[RESULT_SIZE],
                   unsigned char Data[IMAGE_HEIGHT][IMAGE_WIDTH],
                   std::string outFile)
{
  printf("\nresult_size = %d", result_size);

  MyRect result[RESULT_SIZE];

  for (int j = 0; j < RESULT_SIZE; j++){
    result[j].x = result_x[j];
    result[j].y = result_y[j];
    result[j].width = result_w[j];
    result[j].height = result_h[j];
  }

  for( int i=0 ; i < result_size ; i++ )
    printf("\n [Test Bench (main) ] detected rects: %d %d %d %d",result[i].x,result[i].y,result[i].width,result[i].height);

  printf("\n-- saving output image [Start] --\r\n");

  // Draw the rectangles onto the images and save the outputs.
  for(int i = 0; i < result_size ; i++ )
  {
    MyRect r = result[i];
    drawRectangle(Data, r);
  }

  int flag = writePgm(outFile.c_str(), Data);

  printf("\n-- saving output image [Done] --\r\n");

}




int main(int argc, char ** argv)
{
  printf("Face Detection Application\n");

  std::string outFile("");


  // for this benchmark, input data is included in array Data
  // these are outputs
  int result_x[RESULT_SIZE];
  int result_y[RESULT_SIZE];
  int result_w[RESULT_SIZE];
  int result_h[RESULT_SIZE];
  int res_size = 0;

  // timers
  struct timeval start, end;


	hls::stream<ap_uint<512> > Input_1("main_in");
	hls::stream<ap_uint<512> > Output_1("main_out");
	int i, j, k;

	data_gen(Input_1);
    top(Input_1, Output_1);
    // printf("we should receive %d values\n", (unsigned int) Output_1.read());
    OUT: for ( i = 0; i < RESULT_SIZE/4; i++){
    	bit512 Output_tmp = Output_1.read();
    	for(int j=0; j<4; j++){
			result_x[i*4+j]=Output_tmp(j*128+31,  j*128+0);
			result_y[i*4+j]=Output_tmp(j*128+63,  j*128+32);
			result_w[i*4+j]=Output_tmp(j*128+95,  j*128+64);
			result_h[i*4+j]=Output_tmp(j*128+127, j*128+96);
    	}
    }
    res_size = Output_1.read();



  // check results
  printf("Checking results:\n");
  check_results(res_size, result_x, result_y, result_w, result_h, Data, outFile);

  return EXIT_SUCCESS;

}




