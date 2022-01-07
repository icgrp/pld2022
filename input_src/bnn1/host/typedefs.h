#ifndef TYPEDEFS_H
#define TYPEDEFS_H
#include <hls_stream.h>
#include <ap_int.h>

#include "ap_fixed.h"



//#define USE_FLOAT

#ifdef USE_FLOAT

  typedef float InputFixed;

  // Types for weights
  typedef ap_int<1> Bit;
  typedef ap_int<2> TwoBit;

  typedef float KType;
  typedef float HType;

  typedef float NormOutput;
  typedef ap_int<14> ConvOutput;

#else

  // Quantized 32-bit input images in the range [-1,1]
  typedef ap_fixed<32,2> InputFixed;

  // Types for weights
  typedef ap_int<1> Bit;
  typedef ap_int<2> TwoBit;


  typedef ap_fixed<16,2> KType;
  typedef ap_fixed<16,4> HType;

  typedef ap_fixed<16,5> NormOutput;
  typedef ap_int<14> ConvOutput;

#define IMAGE_NUM 1
#endif



  const unsigned CONVOLVERS = 2;

  const unsigned WORD_SIZE = 64;
  const unsigned WT_SIZE = 9;
  const unsigned CONV_W_PER_WORD = 7;
  const unsigned CONV1_W_PER_WORD = 4;
  const unsigned KH_PER_WORD = 4;
  const unsigned BYTE_SIZE = 8;
  const unsigned K = 3;
  const unsigned WT_L         = 16*4*512; // parameter to control wt mem size
  const unsigned C_WT_WORDS   = ((WT_L+CONV_W_PER_WORD-1)/CONV_W_PER_WORD + CONVOLVERS-1) / CONVOLVERS;  // wt words per convolver
  const unsigned WT_WORDS     = C_WT_WORDS*CONVOLVERS;
  const unsigned KH_WORDS     = WT_L/128*16 / WORD_SIZE;

  const unsigned DMEM_WORDS   = 128*32*32 / WORD_SIZE;
  const unsigned C_DMEM_WORDS = DMEM_WORDS / CONVOLVERS;
  const unsigned DMEM_O_WORDS = 512*4*4 / WORD_SIZE;
  const unsigned DB_MEM_WORDS = 32*32;

  const unsigned PIX_PER_PHASE = 2*32*32;

  const unsigned MAX_WIDTH = WORD_SIZE;
  const unsigned BANK_WIDTH = 8;
  const unsigned LOG_BANK_WIDTH = 3;

  const unsigned CONV_ROWS = 3;
  const unsigned CONV_COLS = BANK_WIDTH+2;
  const unsigned CONV_BANKS = WORD_SIZE / BANK_WIDTH;


  enum LayerTypeEnum {LAYER_CONV1, LAYER_CONV, LAYER_DENSE, LAYER_LAST};

  typedef ap_int<WORD_SIZE> Word;
  typedef ap_int<WT_SIZE> WtType;
  typedef ap_uint<16> Address;
  typedef ap_int<12> ConvSum;
  typedef ap_int<5> ConvOut;
  typedef ap_uint<10> IdxType;
  typedef ap_fixed<16,4> C1Comp;
  typedef ap_int<16> NormComp;
  typedef ap_int<16> DenseSum;
  typedef ap_fixed<16,12> DenseNorm;

  // typedef ap_fixed<20,2, AP_RND> C1InputType;
  typedef ap_fixed<20,2> C1InputType;
  // typedef ap_fixed<24,6, AP_RND> C1ConvType;
  typedef ap_fixed<24,6> C1ConvType;

  typedef ap_int<WORD_SIZE> Word;

  // const static Word m1("0x5555555555555555", 16);
  // const static Word m2("0x3333333333333333", 16);
  // const static Word m4("0x0f0f0f0f0f0f0f0f", 16);
  // const static Word h01("0x0101010101010101", 16);

  typedef ap_uint< 512 > bit512;
  typedef ap_uint< 128 > DMA_Word;
  typedef ap_uint< 32 > bit32;
  typedef ap_uint< 64 > bit64;

#endif
