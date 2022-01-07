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
static void projection(
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
static void rasterization1 (
		Triangle_2D triangle_2d,
		bit32 *out1,
		bit32 *out2
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
		out1[0] = tmp1;
		out1[1] = tmp2;
		out1[2] = tmp3;
		out1[3] = tmp4;
		//printf("0x%08x,\n", (unsigned int)tmp1);
		//printf("0x%08x,\n", (unsigned int)tmp2);
		//printf("0x%08x,\n", (unsigned int)tmp3);
		//printf("0x%08x,\n", (unsigned int)tmp4);
		parity = 1;
	}else{
		out2[0] = tmp1;
		out2[1] = tmp2;
		out2[2] = tmp3;
		out2[3] = tmp4;
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
	out1[0] = tmp1;
	out1[1] = tmp2;
	out1[2] = tmp3;
	out1[3] = tmp4;
	//printf("0x%08x,\n", (unsigned int)tmp1);
	//printf("0x%08x,\n", (unsigned int)tmp2);
	//printf("0x%08x,\n", (unsigned int)tmp3);
	//printf("0x%08x,\n", (unsigned int)tmp4);
	parity = 1;
  }else{
	out2[0] = tmp1;
	out2[1] = tmp2;
	out2[2] = tmp3;
	out2[3] = tmp4;
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



static bit1 pixel_in_triangle( bit8 x, bit8 y, Triangle_2D triangle_2d )
{

  int pi0, pi1, pi2;

  pi0 = (x - triangle_2d.x0) * (triangle_2d.y1 - triangle_2d.y0) - (y - triangle_2d.y0) * (triangle_2d.x1 - triangle_2d.x0);
  pi1 = (x - triangle_2d.x1) * (triangle_2d.y2 - triangle_2d.y1) - (y - triangle_2d.y1) * (triangle_2d.x2 - triangle_2d.x1);
  pi2 = (x - triangle_2d.x2) * (triangle_2d.y0 - triangle_2d.y2) - (y - triangle_2d.y2) * (triangle_2d.x0 - triangle_2d.x2);

  return (pi0 >= 0 && pi1 >= 0 && pi2 >= 0);
}


// find pixels in the triangles from the bounding box
static void rasterization2_odd (
		bit32 *in1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2
		)
{
  #pragma HLS INLINE off
	bit16 i = 0;
	bit16 i_top = 0;
	bit16 i_bot = 0;
	int y_tmp;
	int j;
	Triangle_2D triangle_2d_same;
	bit2 flag;
	bit8 max_min[5];
	bit16 max_index[1];
	bit32 out_tmp;
	static CandidatePixel fragment[500];
	static int in_cnt=0;
	static int out1_cnt=0;
	static int out2_cnt=0;

	bit32 tmp;
	tmp = in1[0];
	flag = (bit2) tmp(1,0);
	in_cnt++;
	//printf("in1 %d\n", in_cnt);

	triangle_2d_same.x0=bit8(tmp(15,8));
	triangle_2d_same.y0=bit8(tmp(23,16));
	triangle_2d_same.x1=bit8(tmp(31,24));


	tmp = in1[1];
	in_cnt++;
	//printf("in1 %d\n", in_cnt);
	triangle_2d_same.y1=bit8(tmp(7,0));
	triangle_2d_same.x2=bit8(tmp(15,8));
	triangle_2d_same.y2=bit8(tmp(23,16));
	triangle_2d_same.z=bit8(tmp(31,24));


	tmp = in1[2];
	in_cnt++;
	//printf("in1 %d\n", in_cnt);
	max_index[0]= bit16(tmp(15,0));
	max_min[0]=bit8(tmp(23,16));
	max_min[1]=bit8(tmp(31,24));

	tmp = in1[3];
	in_cnt++;
	//printf("in1 %d\n", in_cnt);
	max_min[2]=bit8(tmp(7,0));
	max_min[3]=bit8(tmp(15,8));
	max_min[4]=bit8(tmp(23, 16));
#ifdef PROFILE
	rasterization2_m_in_1+=4;
#endif

  // clockwise the vertices of input 2d triangle
  if ( flag )
  {
	  Output_1.write(bit32(i_top));
	  out1_cnt++;
	  //printf("out1 %d\n", out1_cnt);
	  Output_2.write(bit32(i_bot));
	  out2_cnt++;
	  //printf("out2 %d\n", out2_cnt);
#ifdef PROFILE
		rasterization2_m_out_1++;
		rasterization2_m_out_2++;
#endif
    return;
  }
  bit8 color = 100;



  RAST2: for ( bit16 k = 0; k < max_index[0]; k++ )
  {
    #pragma HLS PIPELINE II=1
    bit8 x;
    x = max_min[0] + k%max_min[4];
    bit8 y;
    y = max_min[2] + k/max_min[4];

    if( pixel_in_triangle( x, y, triangle_2d_same ) )
    {
      fragment[i].x = x;
      fragment[i].y = y;
      fragment[i].z = triangle_2d_same.z;
      fragment[i].color = color;
      i++;
      if(y>127) i_top++;
      else i_bot++;
    }
  }

  Output_1.write(bit32(i_top));
  out1_cnt++;
  //printf("out1 %d\n", out1_cnt);
  Output_2.write(bit32(i_bot));
  out2_cnt++;
  //printf("out2 %d\n", out2_cnt);
#ifdef PROFILE
		rasterization2_m_out_1++;
		rasterization2_m_out_2++;
#endif
  for(j=0; j<i; j++){
#pragma HLS PIPELINE II=1
	  out_tmp(7, 0) = fragment[j].x;
	  out_tmp(15, 8) = fragment[j].y;
	  y_tmp = (int) out_tmp(15, 8);
	  out_tmp(23, 16) = fragment[j].z;
	  out_tmp(31, 24) = fragment[j].color;
	  if( y_tmp > 127){
		  Output_1.write(out_tmp);
		  out1_cnt++;
		  //printf("out1 %d\n", out1_cnt);
#ifdef PROFILE
		rasterization2_m_out_1++;
#endif
	  }
	  else
	  {
		  Output_2.write(out_tmp);
		  out2_cnt++;
		  //printf("out2 %d\n", out2_cnt);
#ifdef PROFILE
		rasterization2_m_out_2++;
#endif
	  }
  }

  return;
}


// find pixels in the triangles from the bounding box
static void rasterization2_even (
		bit32 *in1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2
		)
{
  #pragma HLS INLINE off
	bit16 i = 0;
	bit16 i_top = 0;
	bit16 i_bot = 0;
	int y_tmp;
	int j;
	Triangle_2D triangle_2d_same;
	bit2 flag;
	bit8 max_min[5];
	bit16 max_index[1];
	bit32 out_tmp;
	static CandidatePixel fragment[500];
	static int in2_cnt = 0;
	static int out3_cnt = 0;
	static int out4_cnt = 0;

	bit32 tmp = in1[0];
	in2_cnt++;
	//printf("in2 %d\n", in2_cnt);
	flag = (bit2) tmp(1,0);
	triangle_2d_same.x0=bit8(tmp(15, 8));
	triangle_2d_same.y0=bit8(tmp(23,16));
	triangle_2d_same.x1=bit8(tmp(31,24));

	tmp = in1[1];
	in2_cnt++;
	//printf("in2 %d\n", in2_cnt);
	triangle_2d_same.y1=bit8(tmp(7,0));
	triangle_2d_same.x2=bit8(tmp(15,8));
	triangle_2d_same.y2=bit8(tmp(23,16));
	triangle_2d_same.z=bit8(tmp(31,24));


	tmp = in1[2];
	in2_cnt++;
	//printf("in2 %d\n", in2_cnt);
	max_index[0]= bit16(tmp(15,0));
	max_min[0]= bit8(tmp(23,16));
	max_min[1]= bit8(tmp(31,24));

	tmp = in1[3];
	in2_cnt++;
	//printf("in2 %d\n", in2_cnt);
	max_min[2]= bit8(tmp(7,0));
	max_min[3]= bit8(tmp(15,8));
	max_min[4]=bit8(tmp(23, 16));
#ifdef PROFILE
		rasterization2_m_in_2+=4;
#endif

  // clockwise the vertices of input 2d triangle
  if ( flag )
  {
	  unsigned int out_tmp = i_top;
	  Output_1.write(out_tmp);
	  out3_cnt++;
	  //printf("out3 %d\n", out3_cnt);
	  out_tmp = i_bot;
	  Output_2.write(out_tmp);
	  out4_cnt++;
	  //printf("out4 %d\n", out4_cnt);
#ifdef PROFILE
		rasterization2_m_out_3++;
		rasterization2_m_out_4++;
#endif
    return;
  }
  bit8 color = 100;


  RAST2: for ( int k = 0; k < max_index[0]; k++ )
  {

    #pragma HLS PIPELINE II=1
    bit8 x;
    x = max_min[0] + k%max_min[4];
    bit8 y;

    y = max_min[2] + k/max_min[4];

    if( pixel_in_triangle( x, y, triangle_2d_same ) )
    {
      fragment[i].x = x;
      fragment[i].y = y;
      fragment[i].z = triangle_2d_same.z;
      fragment[i].color = color;
      i++;
      if(y>127) i_top++;
      else i_bot++;
    }

  }

  Output_1.write(bit32(i_top));
  out3_cnt++;
  //printf("out3 %d\n", out3_cnt);
  Output_2.write(bit32(i_bot));
  out4_cnt++;
  //printf("out4 %d\n", out4_cnt);
#ifdef PROFILE
		rasterization2_m_out_3++;
		rasterization2_m_out_4++;
#endif
  for(j=0; j<i; j++){
#pragma HLS PIPELINE II=1
	  out_tmp(7, 0) = fragment[j].x;
	  out_tmp(15, 8) = fragment[j].y;
	  y_tmp = (int) out_tmp(15, 8);
	  out_tmp(23, 16) = fragment[j].z;
	  out_tmp(31, 24) = fragment[j].color;
	  if(y_tmp > 127)
	  {
		  Output_1.write(out_tmp);
		  out3_cnt++;
		 //printf("out3 %d\n", out3_cnt);
#ifdef PROFILE
		rasterization2_m_out_3++;
#endif
	  }
	  else
	  {
		  Output_2.write(out_tmp);
		  out4_cnt++;
		  //printf("out4 %d\n", out4_cnt);
#ifdef PROFILE
		rasterization2_m_out_4++;
#endif
	  }
  }

  return;
}




static void rasterization2_m (
		bit32 *in1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2,
		bit32 *in2,
		hls::stream<ap_uint<32> > & Output_3,
		hls::stream<ap_uint<32> > & Output_4
		)
{

	rasterization2_odd(
			in1,
			Output_1,
			Output_2);

	rasterization2_even(
			in2,
			Output_3,
			Output_4);


}


void data_redir_m (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2,
		hls::stream<ap_uint<32> > & Output_3,
		hls::stream<ap_uint<32> > & Output_4
		)
{
#pragma HLS INTERFACE axis register both port=Input_1
#pragma HLS INTERFACE axis register both port=Output_1
#pragma HLS INTERFACE axis register both port=Output_2
#pragma HLS INTERFACE axis register both port=Output_3
#pragma HLS INTERFACE axis register both port=Output_4

  bit32 input_lo;
  bit32 input_mi;
  bit32 input_hi;
  static int cnt = 0;

  hls::stream<ap_uint<32> > Output_1_1;
  hls::stream<ap_uint<32> > Output_2_2;
  Triangle_2D triangle_2ds_1;
  Triangle_2D triangle_2ds_2;

  bit32 raster1_out1[4];
  bit32 raster1_out2[4];


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
  input_lo = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }
  //printf("0x%08x,\n", input_lo.to_int() );
  input_mi = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }
  //printf("0x%08x,\n", input_mi.to_int() );
  input_hi = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }

  projection (input_lo,input_mi,input_hi,&triangle_2ds_1);
  rasterization1 (triangle_2ds_1, raster1_out1, raster1_out2);

  input_lo = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }
  //printf("0x%08x,\n", input_lo.to_int() );
  input_mi = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }
  //printf("0x%08x,\n", input_mi.to_int() );
  input_hi = Input_1.read();
  for(int i=0; i<15; i++){ Input_1.read(); }

  projection (input_lo,input_mi,input_hi,&triangle_2ds_1);
  rasterization1 (triangle_2ds_1, raster1_out1, raster1_out2);
  rasterization2_m(raster1_out1, Output_1, Output_2, raster1_out2, Output_3, Output_4);

}

