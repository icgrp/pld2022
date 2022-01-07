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



// calculate bounding box for a 2D triangle
void rasterization1 (
		hls::stream<ap_uint<32> > & Input_1,
		hls::stream<ap_uint<32> > & Output_1,
		hls::stream<ap_uint<32> > & Output_2
		)
{
#pragma HLS INTERFACE axis register both port=Input_1
#pragma HLS INTERFACE axis register both port=Output_1
#pragma HLS INTERFACE axis register both port=Output_2
	Triangle_2D triangle_2d;
	Triangle_2D triangle_2d_same;
	static bit8 max_min[5]={0, 0, 0, 0, 0};
	static bit16 max_index[1]={0};
	bit32 tmp1, tmp2, tmp3, tmp4;
	static int parity = 0;
  #pragma HLS INLINE off


  bit32 in_tmp;

  in_tmp = Input_1.read();
  triangle_2d.x0 = (bit8) in_tmp(7,   0);
  triangle_2d.y0 = (bit8) in_tmp(15,  8);
  triangle_2d.x1 = (bit8) in_tmp(23, 16);
  triangle_2d.y1 = (bit8) in_tmp(31, 24);

  in_tmp = Input_1.read();
  triangle_2d.x2 = (bit8) in_tmp(7,   0);
  triangle_2d.y2 = (bit8) in_tmp(15,  8);
  triangle_2d.z  = (bit8) in_tmp(23, 16);


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


