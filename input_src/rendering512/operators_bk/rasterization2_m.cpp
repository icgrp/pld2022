#include "../host/typedefs.h"

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
		hls::stream<ap_uint<32> > & Input_1,
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

	bit32 tmp = Input_1.read();
	flag = (bit2) tmp(1,0);
	in_cnt++;
	//printf("in1 %d\n", in_cnt);

	triangle_2d_same.x0=bit8(tmp(15,8));
	triangle_2d_same.y0=bit8(tmp(23,16));
	triangle_2d_same.x1=bit8(tmp(31,24));


	tmp = Input_1.read();
	in_cnt++;
	//printf("in1 %d\n", in_cnt);
	triangle_2d_same.y1=bit8(tmp(7,0));
	triangle_2d_same.x2=bit8(tmp(15,8));
	triangle_2d_same.y2=bit8(tmp(23,16));
	triangle_2d_same.z=bit8(tmp(31,24));


	tmp = Input_1.read();
	in_cnt++;
	//printf("in1 %d\n", in_cnt);
	max_index[0]= bit16(tmp(15,0));
	max_min[0]=bit8(tmp(23,16));
	max_min[1]=bit8(tmp(31,24));

	tmp = Input_1.read();
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
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2
		)
{
#pragma HLS INTERFACE ap_hs port=Input_1
#pragma HLS INTERFACE ap_hs port=Output_1
#pragma HLS INTERFACE ap_hs port=Output_2
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

	bit32 tmp = Input_1.read();
	in2_cnt++;
	//printf("in2 %d\n", in2_cnt);
	flag = (bit2) tmp(1,0);
	triangle_2d_same.x0=bit8(tmp(15, 8));
	triangle_2d_same.y0=bit8(tmp(23,16));
	triangle_2d_same.x1=bit8(tmp(31,24));

	tmp = Input_1.read();
	in2_cnt++;
	//printf("in2 %d\n", in2_cnt);
	triangle_2d_same.y1=bit8(tmp(7,0));
	triangle_2d_same.x2=bit8(tmp(15,8));
	triangle_2d_same.y2=bit8(tmp(23,16));
	triangle_2d_same.z=bit8(tmp(31,24));


	tmp = Input_1.read();
	in2_cnt++;
	//printf("in2 %d\n", in2_cnt);
	max_index[0]= bit16(tmp(15,0));
	max_min[0]= bit8(tmp(23,16));
	max_min[1]= bit8(tmp(31,24));

	tmp = Input_1.read();
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




void rasterization2_m (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2,

		hls::stream<ap_uint<32> > & Input_2,
		hls::stream<ap_uint<32> > & Output_3,
		hls::stream<ap_uint<32> > & Output_4
		)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2
#pragma HLS INTERFACE axis register port=Output_3
#pragma HLS INTERFACE axis register port=Output_4


	rasterization2_odd(
			Input_1,
			Output_1,
			Output_2);

	rasterization2_even(
			Input_2,
			Output_3,
			Output_4);


}
