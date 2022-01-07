/*===============================================================*/
/*                                                               */
/*                          kernel.h                             */
/*                                                               */
/*        Defines types and constants for host function          */
/*                                                               */
/*===============================================================*/

#ifndef __TYPEDEFS_H__
#define __TYPEDEFS_H__
//#include "ap_fixed.h"
const int MAX_HEIGHT = 436;
const int MAX_WIDTH = 1024;
#include "ap_fixed.h"
#include "multimediaIps/xf_video_mem.hpp"
//#include "/opt/Xilinx/Vivado/2021.1/include/multimediaIps/xf_video_mem.hpp"
#include "hls_stream.h"
typedef ap_uint<32> databus_t;
typedef ap_uint<64> bit64;
typedef ap_uint<128> bit128;
typedef ap_uint<512> bit512;
typedef ap_uint<160> bit160;

typedef ap_uint<288> widebus_t;
// define these constants so they can be used in pragma
const int max_width = MAX_WIDTH;
const int default_depth = MAX_WIDTH;

#define SDSOC

// basic typedefs
#ifdef SDSOC
	//#include "/home/ylxiao/Xilinx/Vivado/2018.3/include/gmp.h"
    #include "./gmp.h"
	#include "ap_fixed.h"
	typedef ap_fixed<17,9> input_t;
	typedef ap_fixed<32,13> pixel_t;
	typedef ap_fixed<48,27> outer_pixel_t;
	typedef ap_fixed<96,56> calc_pixel_t;
	typedef ap_fixed<32,13> vel_pixel_t;
	//typedef ap_fixed<16,8> input_t;
        //typedef ap_fixed<32,13> pixel_t;
        //typedef float outer_pixel_t;
	//typedef float calc_pixel_t;
	//typedef float vel_pixel_t;
	
#endif
#ifdef OCL
	#include "ap_fixed.h"
	typedef ap_fixed<48,40> pixel_t;
#endif
#ifdef SW
	typedef float pixel_t;
#endif
typedef struct{
	pixel_t x;
	pixel_t y;
	pixel_t z;
}gradient_t;

typedef struct{
    outer_pixel_t val[6];
}outer_t; 

typedef struct{
    outer_pixel_t val[3];
}outer_half_t;

typedef struct{
    outer_pixel_t val[6];
}tensor_t;

typedef struct{
    outer_pixel_t val[3];
}tensor_half_t;

typedef struct{
    vel_pixel_t x;
    vel_pixel_t y;
}velocity_t;

  #include "ap_int.h"
  // for data packing
  typedef ap_uint<64> frames_t;
  typedef ap_uint<32> stdio_t;


#endif
