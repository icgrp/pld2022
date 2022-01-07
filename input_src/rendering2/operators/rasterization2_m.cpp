#include "../host/typedefs.h"


// filter hidden pixels
void zculling_top (
		bit16 size,
		CandidatePixel *fragments,
		hls::stream<ap_uint<32> > & Output_1
	  )
{
  #pragma HLS INLINE off

  static bit16 counter=0;
  int i, j;
  Pixel pixels[500];
  bit32 in_tmp;
  bit32 out_tmp;
  static bit8 frame_buffer[MAX_X][MAX_Y];
  Pixel pixel;
  bit32 out_FB = 0;



  // initilize the z-buffer in rendering first triangle for an image
  static bit8 z_buffer[MAX_X][MAX_Y];
  if (counter == 0)
  {
    ZCULLING_INIT_ROW: for ( bit16 i = 0; i < MAX_X; i++)
    {
      ZCULLING_INIT_COL: for ( bit16 j = 0; j < MAX_Y; j++)
      {
		#pragma HLS PIPELINE II=1
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
    if( fragments[n].z < z_buffer[fragments[n].y][fragments[n].x] )
    {

      pixels[pixel_cntr].x     = fragments[n].x;
      pixels[pixel_cntr].y     = fragments[n].y;
      pixels[pixel_cntr].color = fragments[n].color;
      pixel_cntr++;
      z_buffer[fragments[n].y][fragments[n].x] = fragments[n].z;
    }
  }

  if ( counter == 0 )
  {
    // initilize the framebuffer for a new image
    COLORING_FB_INIT_ROW: for ( bit16 i = 0; i < MAX_X; i++)
    {
      COLORING_FB_INIT_COL: for ( bit16 j = 0; j < MAX_Y; j++) {
		#pragma HLS PIPELINE II=1
        frame_buffer[i][j] = 0;
      }
    }
  }

  // update the framebuffer
  COLORING_FB: for ( bit16 i = 0; i < pixel_cntr; i++)
  {
    #pragma HLS PIPELINE II=1
    pixel.x=pixels[i].x;
    pixel.y=pixels[i].y;
    pixel.color=pixels[i].color;
    frame_buffer[ pixel.x ][ pixel.y ] = pixel.color;
  }

  counter++;
  if(counter==NUM_3D_TRI){
    for (i=0; i<MAX_X; i++){
      for(j=0; j<MAX_Y; j+=4){
        for (int k=0; k<4; k++){
         #pragma HLS PIPELINE II=1
           out_FB( k*8+7,  k*8) = frame_buffer[i][j+k];
        }
	Output_1.write(out_FB);
      }
    }
    counter=0;
  }

  return;
}


static bit1 pixel_in_triangle( bit8 x, bit8 y, Triangle_2D triangle_2d )
{

  int pi0, pi1, pi2;

  pi0 = (x - triangle_2d.x0) * (triangle_2d.y1 - triangle_2d.y0) - (y - triangle_2d.y0) * (triangle_2d.x1 - triangle_2d.x0);
  pi1 = (x - triangle_2d.x1) * (triangle_2d.y2 - triangle_2d.y1) - (y - triangle_2d.y1) * (triangle_2d.x2 - triangle_2d.x1);
  pi2 = (x - triangle_2d.x2) * (triangle_2d.y0 - triangle_2d.y2) - (y - triangle_2d.y2) * (triangle_2d.x0 - triangle_2d.x2);

  return (pi0 >= 0 && pi1 >= 0 && pi2 >= 0);
}

// find pixels in the triangles from the bounding box
void rasterization2_m (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1
		)
{
#pragma HLS INTERFACE axis register both port=Input_1
#pragma HLS INTERFACE axis register both port=Output_1

  #pragma HLS INLINE off
	bit16 i = 0;
	bit16 i_top = 0;
	int y_tmp;
	int j;
	Triangle_2D triangle_2d_same;
	bit2 flag;
	bit8 max_min[5];
	bit16 max_index[1];
	bit32 out_tmp;
	static CandidatePixel fragment[500];

	bit32 tmp = Input_1.read();
        //printf("%08x\n", (unsigned int) tmp);
	flag = (bit2) tmp(1,0);
	triangle_2d_same.x0=tmp(15,8);
	triangle_2d_same.y0=tmp(23,16);
	triangle_2d_same.x1=tmp(31,24);

	tmp = Input_1.read();
        //printf("%08x\n", (unsigned int) tmp);
	triangle_2d_same.y1=tmp(7,0);
	triangle_2d_same.x2=tmp(15,8);
	triangle_2d_same.y2=tmp(23,16);
	triangle_2d_same.z=tmp(31,24);

	tmp = Input_1.read();
        //printf("%08x\n", (unsigned int) tmp);
	max_index[0]=tmp(15,0);
	max_min[0]=tmp(23,16);
	max_min[1]=tmp(31,24);

	tmp = Input_1.read();
        //printf("%08x\n", (unsigned int) tmp);
	max_min[2]=tmp(7,0);
	max_min[3]=tmp(15,8);
	max_min[4]=tmp(23, 16);

  // clockwise the vertices of input 2d triangle
  if ( flag )
  {
	zculling_top (i_top, fragment, Output_1);
    return;
  }
  bit8 color = 100;


  RAST2: for ( bit16 k = 0; k < max_index[0]; k++ )
  {
    #pragma HLS PIPELINE II=1
    bit8 x = max_min[0] + k%max_min[4];
    bit8 y = max_min[2] + k/max_min[4];

    if( pixel_in_triangle( x, y, triangle_2d_same ) )
    {
      fragment[i].x = x;
      fragment[i].y = y;
      fragment[i].z = triangle_2d_same.z;
      fragment[i].color = color;
      i++;
      i_top++;
    }
  }

  zculling_top (i_top, fragment, Output_1);
  return;
}



