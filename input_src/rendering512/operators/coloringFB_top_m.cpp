#include "../host/typedefs.h"

// color the frame buffer
void coloringFB_top_m(
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<128> > & Input_2,
		hls::stream<ap_uint<512> > & Output_1)

{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1
  #pragma HLS INLINE off
  int i,j;
  static bit8 frame_buffer[MAX_X][MAX_Y/2];
  Pixel pixels;
  static bit16 counter=0;
  bit16 size_pixels;
  bit32 in_tmp;
  size_pixels=Input_1.read();
#ifdef PROFILE
  coloringFB_top_m_in_1++;
#endif
  bit512 out_FB = 0;

  if ( counter == 0 )
  {
    // initilize the framebuffer for a new image
    COLORING_FB_INIT_ROW: for ( bit16 i = 0; i < MAX_X; i++)
    {
#pragma HLS PIPELINE II=1
      COLORING_FB_INIT_COL: for ( bit16 j = 0; j < MAX_Y/2; j++)
        frame_buffer[i][j] = 0;
    }
  }

  // update the framebuffer
  COLORING_FB: for ( bit16 i = 0; i < size_pixels; i++)
  {
    #pragma HLS PIPELINE II=1
	 in_tmp = Input_1.read();
	 pixels.x(7, 0)=in_tmp(7, 0);
	 pixels.y(7, 0)=in_tmp(15, 8);
	 pixels.color(7, 0)=in_tmp(23, 16);
    frame_buffer[ pixels.x ][ pixels.y-128 ] = pixels.color;
  }

  counter++;
  if(counter==NUM_3D_TRI){
	  for (i=0; i<MAX_X; i++){
		  RECV: for(int k=0; k<MAX_Y/8; k+=16){
			  bit512 out_tmp;
			  bit128 tmp;
#pragma HLS PIPELINE II=1
			  for(int l=0; l<4; l++){
				  tmp = Input_2.read();
				  for(int out_i=0; out_i<4; out_i++){
					  out_tmp(l*128+out_i*32+31, l*128+out_i*32) = tmp(out_i*32+31, out_i*32);
				  }
			  }
			  Output_1.write(out_tmp);
		  }

    SEND: for(j=0; j<MAX_Y/2; j+=64){
#pragma HLS PIPELINE II=1
        	for (int k=0; k<64; k++){
				  out_FB( k*8+7,  k*8) = frame_buffer[i][j+k];
			  }
			  Output_1.write(out_FB);
		  }
	  }
	  counter=0;
  }
}

