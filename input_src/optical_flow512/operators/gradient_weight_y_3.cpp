#include "../host/typedefs.h"
// average the gradient in y direction
void gradient_weight_y_3(
    hls::stream<databus_t> &Input_1,
    hls::stream<databus_t> &Output_1)
{
#pragma HLS interface axis register port=Input_1
#pragma HLS interface axis register port=Output_1
#ifdef RISCV
  hls::LineBuffer<7,MAX_WIDTH,pixel_t> buf;
#else
  xf::cv::LineBuffer<7,MAX_WIDTH,pixel_t> buf;
#endif


  const pixel_t GRAD_FILTER[] = {0.0755, 0.133, 0.1869, 0.2903, 0.1869, 0.133, 0.0755};
  GRAD_WEIGHT_Y_OUTER: for(int r=0; r<MAX_HEIGHT+3; r++)
  {
#ifdef RISCV
	  print_dec(r);
	  print_str("\n");
#endif
    GRAD_WEIGHT_Y_INNER: for(int c=0; c<MAX_WIDTH; c++)
    {
      #pragma HLS pipeline II=1
      #pragma HLS dependence variable=buf inter false

      if(r<MAX_HEIGHT)
      {
        buf.shift_pixels_up(c);
        pixel_t tmp = 0;
	databus_t temp;
	temp = Input_1.read();
	tmp(31,0) = temp(31,0);
        buf.insert_bottom_row(tmp,c);
      }
      else
      {
        buf.shift_pixels_up(c);
        pixel_t tmp;
        tmp = 0;
        buf.insert_bottom_row(tmp,c);
      }

      pixel_t acc;
      databus_t temp = 0;
      acc = 0;
      if(r >= 6 && r<MAX_HEIGHT)
      {
        GRAD_WEIGHT_Y_ACC: for(int i=0; i<7; i++)
        {
            pixel_t tmpa, tmpb;
            tmpb = GRAD_FILTER[i];
            acc =  acc + buf.getval(i,c)*tmpb;
        }
		temp(31,0) = acc.range(31,0);
		Output_1.write(temp);
      }
      else if(r>=3)
      {
		temp(31,0) = acc.range(31,0);
		Output_1.write(temp);
      }
    }
  }
}

