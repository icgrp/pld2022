#include "../host/typedefs.h"




static int check_clockwise( Triangle_2D triangle_2d )
{
  int cw;

  cw = (triangle_2d.x2 - triangle_2d.x0) * (triangle_2d.y1 - triangle_2d.y0)
       - (triangle_2d.y2 - triangle_2d.y0) * (triangle_2d.x1 - triangle_2d.x0);

  return cw;

}

// swap (x0, y0) (x1, y1) of a Triangle_2D
static void clockwise_vertices( Triangle_2D *triangle_2d )
{

  bit8 tmp_x, tmp_y;

  tmp_x = triangle_2d->x0;
  tmp_y = triangle_2d->y0;

  triangle_2d->x0 = triangle_2d->x1;
  triangle_2d->y0 = triangle_2d->y1;

  triangle_2d->x1 = tmp_x;
  triangle_2d->y1 = tmp_y;

}



// find the min from 3 integers
static bit8 find_min( bit8 in0, bit8 in1, bit8 in2 )
{
  if (in0 < in1)
  {
    if (in0 < in2)
      return in0;
    else
      return in2;
  }
  else
  {
    if (in1 < in2)
      return in1;
    else
      return in2;
  }
}


// find the max from 3 integers
static bit8 find_max( bit8 in0, bit8 in1, bit8 in2 )
{
  if (in0 > in1)
  {
    if (in0 > in2)
      return in0;
    else
      return in2;
  }
  else
  {
    if (in1 > in2)
      return in1;
    else
      return in2;
  }
}


// project a 3D triangle to a 2D triangle
void projection(
		bit32 input_lo,
		bit32 input_mi,
		bit32 input_hi,
		Triangle_2D *triangle_2d
		)
{
  #pragma HLS INLINE off
  Triangle_3D triangle_3d;
  // Setting camera to (0,0,-1), the canvas at z=0 plane
  // The 3D model lies in z>0 space
  // The coordinate on canvas is proportional to the corresponding coordinate
  // on space

    bit2 angle = 0;
    triangle_3d.x0 = bit8(input_lo( 7,  0));
    triangle_3d.y0 = bit8(input_lo(15,  8));
    triangle_3d.z0 = bit8(input_lo(23, 16));
    triangle_3d.x1 = bit8(input_lo(31, 24));
    triangle_3d.y1 = bit8(input_mi( 7,  0));
    triangle_3d.z1 = bit8(input_mi(15,  8));
    triangle_3d.x2 = bit8(input_mi(23, 16));
    triangle_3d.y2 = bit8(input_mi(31, 24));
    triangle_3d.z2 = bit8(input_hi( 7,  0));

  if(angle == 0)
  {
    triangle_2d->x0 = triangle_3d.x0;
    triangle_2d->y0 = triangle_3d.y0;
    triangle_2d->x1 = triangle_3d.x1;
    triangle_2d->y1 = triangle_3d.y1;
    triangle_2d->x2 = triangle_3d.x2;
    triangle_2d->y2 = triangle_3d.y2;
    triangle_2d->z  = triangle_3d.z0 / 3 + triangle_3d.z1 / 3 + triangle_3d.z2 / 3;
  }

  else if(angle == 1)
  {
    triangle_2d->x0 = triangle_3d.x0;
    triangle_2d->y0 = triangle_3d.z0;
    triangle_2d->x1 = triangle_3d.x1;
    triangle_2d->y1 = triangle_3d.z1;
    triangle_2d->x2 = triangle_3d.x2;
    triangle_2d->y2 = triangle_3d.z2;
    triangle_2d->z  = triangle_3d.y0 / 3 + triangle_3d.y1 / 3 + triangle_3d.y2 / 3;
  }

  else if(angle == 2)
  {
    triangle_2d->x0 = triangle_3d.z0;
    triangle_2d->y0 = triangle_3d.y0;
    triangle_2d->x1 = triangle_3d.z1;
    triangle_2d->y1 = triangle_3d.y1;
    triangle_2d->x2 = triangle_3d.z2;
    triangle_2d->y2 = triangle_3d.y2;
    triangle_2d->z  = triangle_3d.x0 / 3 + triangle_3d.x1 / 3 + triangle_3d.x2 / 3;
  }

}




void data_redir_m (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1
		)
{
#pragma HLS INTERFACE axis register both port=Input_1
#pragma HLS INTERFACE axis register both port=Output_1

  bit32 input_lo;
  bit32 input_mi;
  bit32 input_hi;
  static int cnt = 0;
  bit32 out_tmp;

  hls::stream<ap_uint<32> > Output_1_1;
  hls::stream<ap_uint<32> > Output_2_2;
  Triangle_2D triangle_2ds_1;


  input_lo = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }
  //printf("0x%08x,\n", input_lo.to_int() );
  input_mi = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }
  //printf("0x%08x,\n", input_mi.to_int() );
  input_hi = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }
  //printf("0x%08x,\n", input_hi.to_int() );
  //Output_3.write(cnt);
  //cnt++;
  //Output_3.write(input_lo);
#ifdef RISCV1
  //unsigned int data;
  //data = input_lo;
  //print_hex(data, 8);
  //print_str(": ");
  print_dec(cnt);
  print_str("\n");
  cnt++;
#else
  //printf("in: %08x\n", (unsigned int)input_lo);
  //printf("in: %08x\n", (unsigned int)input_mi);
  unsigned int data;
  data = input_lo;
  //printf("cnt = %08x\n", input_lo.to_int());
  cnt++;
#endif


#ifdef PROFILE
  data_redir_m_in_1+=3;
#endif

  projection (input_lo,input_mi,input_hi,&triangle_2ds_1);
  out_tmp(7,   0) = triangle_2ds_1.x0;
  out_tmp(15,  8) = triangle_2ds_1.y0;
  out_tmp(23, 16) = triangle_2ds_1.x1;
  out_tmp(31, 24) = triangle_2ds_1.y1;
  Output_1.write(out_tmp);

  out_tmp(7,   0) = triangle_2ds_1.x2;
  out_tmp(15,  8) = triangle_2ds_1.y2;
  out_tmp(23, 16) = triangle_2ds_1.z;
  out_tmp(31, 24) = 0;
  Output_1.write(out_tmp);

}

