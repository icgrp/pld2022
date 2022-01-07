#include "../host/typedefs.h"

// filter hidden pixels
void zculling_bot (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Input_2,
		hls::stream<ap_uint<32> > & Output_1
	  )
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1

  #pragma HLS INLINE off
  CandidatePixel fragment;
  static bit16 counter=0;
  int i, j;
  Pixel pixels[500];
  bit16 size;
  bit32 in_tmp;
  bit32 out_tmp;
  static bit1 odd_even = 0;
  if(odd_even == 0){
	  size = Input_1.read();
	  //printf("%08x\n", (unsigned int) size);
#ifdef PROFILE
		zculling_bot_in_1++;
#endif
  }
  else {
	  size = Input_2.read();
#ifdef PROFILE
		zculling_bot_in_2++;
#endif
  }


  // initilize the z-buffer in rendering first triangle for an image
  static bit8 z_buffer[MAX_X/2][MAX_Y];
  if (counter == 0)
  {
    ZCULLING_INIT_ROW: for ( bit16 i = 0; i < MAX_X/2; i++)
    {
      #pragma HLS PIPELINE II=1
      ZCULLING_INIT_COL: for ( bit16 j = 0; j < MAX_Y; j++)
      {
        z_buffer[i][j] = 255;
      }
    }
  }


  // pixel counter
  bit16 pixel_cntr = 0;

  // update z-buffer and pixels
  ZCULLING: for ( bit16 n = 0; n < size; n++ )
  {
#pragma HLS PIPELINE II=1
	if (odd_even == 0){
		in_tmp = Input_1.read();
		//printf("%08x\n", (unsigned int) size);
#ifdef PROFILE
		zculling_bot_in_1++;
#endif
	}
	else{
		in_tmp = Input_2.read();
#ifdef PROFILE
		zculling_bot_in_2++;
#endif
	}
	fragment.x(7, 0) = in_tmp(7, 0);
	fragment.y(7, 0) = in_tmp(15, 8);
	fragment.z(7, 0) = in_tmp(23, 16);
	fragment.color(7, 0) = in_tmp(31, 24);
    if( fragment.z < z_buffer[fragment.y][fragment.x] )
    {

      pixels[pixel_cntr].x     = fragment.x;
      pixels[pixel_cntr].y     = fragment.y;
      pixels[pixel_cntr].color = fragment.color;
      pixel_cntr++;
      z_buffer[fragment.y][fragment.x] = fragment.z;
    }
  }

  Output_1.write(pixel_cntr);
#ifdef PROFILE
		zculling_bot_out_1++;
#endif
  for(j=0; j<pixel_cntr; j++){
#pragma HLS PIPELINE II=1
	  out_tmp(7,  0) = pixels[j].x;
      out_tmp(15, 8) = pixels[j].y;
      out_tmp(23, 16) = pixels[j].color;
	  out_tmp(31, 24) = 0;
	  Output_1.write(out_tmp);
#ifdef PROFILE
		zculling_bot_out_1++;
#endif
  }


  counter++;
  odd_even = ~odd_even;
  if(counter==NUM_3D_TRI){counter=0;}
  return;
}

