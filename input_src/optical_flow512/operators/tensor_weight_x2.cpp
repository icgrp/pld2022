#include "../host/typedefs.h"
void tensor_weight_x2(hls::stream< ap_uint<160> > &Input_1,
		     hls::stream< ap_uint<160> > &Output_1,
		     hls::stream< ap_uint<160> > &Output_2)
{
#pragma HLS interface axis register port=Input_1
#pragma HLS interface axis register port=Output_1
#pragma HLS interface axis register port=Output_2
#ifdef RISCV
  hls::Window<1,3,tensor_half_t> buf;
#else
  xf::cv::Window<1,3,tensor_half_t> buf;
#endif


  const pixel_t TENSOR_FILTER[] = {0.3243, 0.3513, 0.3243};
  TENSOR_WEIGHT_X_OUTER: for(int r=0; r<MAX_HEIGHT; r++)
  {
#ifdef RISCV
	  print_str("r=");
	  print_dec(r);
	  print_str("\n");
#endif
    TENSOR_WEIGHT_X_INNER: for(int c=0; c<MAX_WIDTH+1; c++)
    {
      #pragma HLS pipeline II=1
      buf.shift_pixels_left();
      tensor_half_t tmp;
      if(c<MAX_WIDTH)
      {
       // widebus_t widetemp = Input_1.read();
    	  ap_uint<160> widetemp;
    	  widetemp = Input_1.read();
          tmp.val[0](31, 0) = widetemp(31,    0);
          tmp.val[0](47,32) = widetemp(47,   32);
          tmp.val[1](15, 0) = widetemp(63,   48);
          tmp.val[1](47,16) = widetemp(95,   64);
          tmp.val[2](31, 0) = widetemp(127,  96);
          tmp.val[2](47,32) = widetemp(143, 128);
      }
      else
      {
        TENSOR_WEIGHT_X_TMP_INIT: for(int i=0; i<3; i++)
          tmp.val[i] = 0;
      }
      buf.insert_pixel(tmp,0,2);

      tensor_half_t acc;
      TENSOR_WEIGHT_X_ACC_INIT: for(int k =0; k<3; k++)
        acc.val[k] = 0;
      if (c >= 2 && c < MAX_WIDTH)
      {
        TENSOR_WEIGHT_X_TMP_OUTER: for(int i=0; i<3; i++)
        {
          tmp = buf.getval(0,i);
          TENSOR_WEIGHT_X_TMP_INNER: for(int component=0; component<3; component++)
          {
            acc.val[component] = acc.val[component] + tmp.val[component]*TENSOR_FILTER[i];
          }
        }
      }
      if(c>=1)
      {
    	ap_uint<160> widetemp;
        widetemp(31,    0) = acc.val[0](31, 0);
        widetemp(47,   32) = acc.val[0](47,32);
        widetemp(63,   48) = acc.val[1](15, 0);
        widetemp(95,   64) = acc.val[1](47,16);
        widetemp(127,  96) = acc.val[2](31, 0);
        widetemp(143, 128) = acc.val[2](47,32);
        widetemp(159, 144) = 0;
        Output_1.write(widetemp);
        Output_2.write(widetemp);
      }
    }
  }
}

