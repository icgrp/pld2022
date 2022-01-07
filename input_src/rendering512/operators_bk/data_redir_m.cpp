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



// calculate bounding box for a 2D triangle
void rasterization1 (
		Triangle_2D triangle_2d,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2
		)
{
	Triangle_2D triangle_2d_same;
	static bit8 max_min[5]={0, 0, 0, 0, 0};
	static bit16 max_index[1]={0};
	bit32 tmp1, tmp2, tmp3, tmp4;
	static int parity = 0;
  #pragma HLS INLINE off
  // clockwise the vertices of input 2d triangle
  if ( check_clockwise( triangle_2d ) == 0 ){

	tmp1(7,0) = 1;
	tmp1(15, 8) = 0;
	tmp1(23,16) = 0;
	tmp1(31,24) = 0;

	tmp2(7,0) = 0;
	tmp2(15, 8) = 0;
	tmp2(23,16) = 0;
	tmp2(31,24) = 0;

	tmp3(15,0) = max_index[0];
	tmp3(23,16) = max_min[0];
	tmp3(31,24) = max_min[1];

	tmp4(7,0) = max_min[2];
	tmp4(15, 8) = max_min[3];
	tmp4(23,16) = max_min[4];
	tmp4(31,24) = 0;
	if(parity==0){
		Output_1.write(tmp1);
		Output_1.write(tmp2);
		Output_1.write(tmp3);
		Output_1.write(tmp4);
		//printf("0x%08x,\n", (unsigned int)tmp1);
		//printf("0x%08x,\n", (unsigned int)tmp2);
		//printf("0x%08x,\n", (unsigned int)tmp3);
		//printf("0x%08x,\n", (unsigned int)tmp4);
		parity = 1;
	}else{
		Output_2.write(tmp1);
		Output_2.write(tmp2);
		Output_2.write(tmp3);
		Output_2.write(tmp4);
		//printf("0x%08x,\n", (unsigned int)tmp1);
		//printf("0x%08x,\n", (unsigned int)tmp2);
		//printf("0x%08x,\n", (unsigned int)tmp3);
		//printf("0x%08x,\n", (unsigned int)tmp4);
		parity = 0;
	}
#ifdef PROFILE
  data_redir_m_out_1+=4;
#endif

    return;
  }
  if ( check_clockwise( triangle_2d ) < 0 )
    clockwise_vertices( &triangle_2d );




  // copy the same 2D triangle
  triangle_2d_same.x0 = triangle_2d.x0;
  triangle_2d_same.y0 = triangle_2d.y0;
  triangle_2d_same.x1 = triangle_2d.x1;
  triangle_2d_same.y1 = triangle_2d.y1;
  triangle_2d_same.x2 = triangle_2d.x2;
  triangle_2d_same.y2 = triangle_2d.y2;
  triangle_2d_same.z  = triangle_2d.z ;

  // find the rectangle bounds of 2D triangles
  max_min[0] = find_min( triangle_2d.x0, triangle_2d.x1, triangle_2d.x2 );
  max_min[1] = find_max( triangle_2d.x0, triangle_2d.x1, triangle_2d.x2 );
  max_min[2] = find_min( triangle_2d.y0, triangle_2d.y1, triangle_2d.y2 );
  max_min[3] = find_max( triangle_2d.y0, triangle_2d.y1, triangle_2d.y2 );
  max_min[4] = max_min[1] - max_min[0];

  // calculate index for searching pixels
  max_index[0] = (max_min[1] - max_min[0]) * (max_min[3] - max_min[2]);

  tmp1(7,0) = 0;
  tmp1(15,8) = triangle_2d_same.x0;
  tmp1(23,16) = triangle_2d_same.y0;
  tmp1(31,24) = triangle_2d_same.x1;

  tmp2(7,0) = triangle_2d_same.y1;
  tmp2(15,8) = triangle_2d_same.x2;
  tmp2(23,16) = triangle_2d_same.y2;
  tmp2(31,24) = triangle_2d_same.z;

  tmp3(15,0) = max_index[0];
  tmp3(23,16) = max_min[0];
  tmp3(31,24) = max_min[1];

  tmp4(7,0) = max_min[2];
  tmp4(15,8) = max_min[3];
  tmp4(23, 16) = max_min[4];
  tmp4(31, 24) = 0;

  if(parity==0){
	Output_1.write(tmp1);
	Output_1.write(tmp2);
	Output_1.write(tmp3);
	Output_1.write(tmp4);
	//printf("0x%08x,\n", (unsigned int)tmp1);
	//printf("0x%08x,\n", (unsigned int)tmp2);
	//printf("0x%08x,\n", (unsigned int)tmp3);
	//printf("0x%08x,\n", (unsigned int)tmp4);
	parity = 1;
  }else{
	Output_2.write(tmp1);
	Output_2.write(tmp2);
	Output_2.write(tmp3);
	Output_2.write(tmp4);
	//printf("0x%08x,\n", (unsigned int)tmp1);
	//printf("0x%08x,\n", (unsigned int)tmp2);
	//printf("0x%08x,\n", (unsigned int)tmp3);
	//printf("0x%08x,\n", (unsigned int)tmp4);
	parity = 0;
  }
#ifdef PROFILE
  data_redir_m_out_1+=4;
#endif
  return;
}


void data_redir_m (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2
		)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2

  bit32 input_lo;
  bit32 input_mi;
  bit32 input_hi;
  //bit128 input_tmp;
  static int cnt = 0;

  hls::stream<ap_uint<32> > Output_1_1;
  hls::stream<ap_uint<32> > Output_2_2;
  Triangle_2D triangle_2ds_1;
  Triangle_2D triangle_2ds_2;


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
  //printf("x0=%08x\n", (unsigned int) triangle_2ds_1.x0);
  //printf("x1=%08x\n", (unsigned int) triangle_2ds_1.x1);
  //printf("x2=%08x\n", (unsigned int) triangle_2ds_1.x2);
  //printf("y0=%08x\n", (unsigned int) triangle_2ds_1.y0);
  //printf("y1=%08x\n", (unsigned int) triangle_2ds_1.y1);
  //printf("y2=%08x\n", (unsigned int) triangle_2ds_1.y2);
  //printf("z=%08x\n", (unsigned int) triangle_2ds_1.z);
  rasterization1 (triangle_2ds_1, Output_1, Output_2);

}

