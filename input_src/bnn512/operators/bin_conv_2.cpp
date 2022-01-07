#include "../host/typedefs.h"

template<typename T>
static void load_kh(T& comp, const Word kh_mem[KH_WORDS], Address idx) {
  //printf("kh_mem %d\n", (unsigned int)idx/KH_PER_WORD);
  Word kh_word = kh_mem[idx/KH_PER_WORD];
  IdxType off = idx % KH_PER_WORD;
  if (off == 0)
    comp(15,0) = kh_word(15, 0);
  else if (off == 1)
    comp(15,0) = kh_word(31,16);
  else if (off == 2)
    comp(15,0) = kh_word(47,32);
  else
    comp(15,0) = kh_word(63,48);
}


static TwoBit encode_bit(Bit b) {
#pragma HLS INLINE
  return (b == 0) ? TwoBit(1) : TwoBit(-1);
}

static ConvOut conv3x3b(
    TwoBit line_buffer_m[CONV_BANKS][CONV_ROWS][CONV_COLS],
    Bit conv_params_m[K][K],
    ap_uint<4> bank,
    IdxType cc
) {
#pragma HLS INLINE
  ConvOut sum = 0;
  for (ap_uint<2> kr = 0; kr < K; kr++) {
    for (ap_uint<2> kc = 0; kc < K; kc++) {
      TwoBit data = line_buffer_m[bank][kr][cc+kc];
      Bit wt;
      wt = conv_params_m[2-kr][2-kc];
      data(1, 1) = (wt & data(0, 0)) ^ data(1, 1);
      sum = sum + data;
    }
  }
  return sum;
}

static void conv_word(
    TwoBit line_buffer_m[CONV_BANKS][CONV_ROWS][CONV_COLS],
    Bit conv_params_m[K][K],
    ConvOut conv_out_buffer_m[WORD_SIZE]
) {
#pragma HLS PIPELINE
  //                               8
  for (ap_uint<4> bank = 0; bank < CONV_BANKS; bank++) {
	//                           8
    for (ap_uint<4> cc = 0; cc < BANK_WIDTH; cc++) {
      conv_out_buffer_m[bank*BANK_WIDTH+cc] = conv3x3b( line_buffer_m, conv_params_m, bank, cc );
    }
  }
}

static void process_word(
    const TwoBit      word_buffer_m[CONV_BANKS][CONV_COLS],
    const TwoBit  old_word_buffer_m[CONV_BANKS][CONV_COLS],
    const bool lb[CONV_BANKS],
    const bool rb[CONV_BANKS],
    TwoBit  line_buffer_m[CONV_BANKS][CONV_ROWS][CONV_COLS],
    Bit conv_params_m[K][K],
    ConvOut conv_out_buffer_m[WORD_SIZE],
    ap_uint<3> log_width,
    ap_uint<6> words_per_image,
    IdxType wrd
) {
#pragma HLS INLINE
  // slices_per_line = width / BANK_WIDTH
  ap_uint<5> slices_per_line = 1 << (log_width - LOG_BANK_WIDTH);
  const bool first_wrd = (wrd == 0);
  const bool last_wrd = (wrd == words_per_image);
  static int local_cnt = 0; // bin_conv = 0: (0, 2175)
  //printf("                process_word = %d\n", local_cnt);
  // Prologue
  // Update bottom row, slices are shifted left. Some slices copied from previous word (middle row)
  //                               8
  for (int bank = 0; bank < CONV_BANKS; bank++) {
    int s_idx = bank + slices_per_line - CONV_BANKS;
    //if(local_cnt < 2176){ printf("\ns_idx = %d\t = %d + %d - %d\n", (int) s_idx, (int) bank, (int) slices_per_line, CONV_BANKS); }
    if (s_idx < 0) {

      //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = old[%d][%d]\n", (int) bank, CONV_ROWS-1, 0, (int)(CONV_BANKS+s_idx), 0);}
      // set to zero or copy from old word (middle row)
      for (ap_uint<4> cc = 1; cc < CONV_COLS-1; cc++) {
    	//if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = old[%d][%d]\n", (int) bank, CONV_ROWS-1, (int)cc, (int)(CONV_BANKS+s_idx), (int) cc);}
        line_buffer_m[bank][CONV_ROWS-1][cc] = old_word_buffer_m[CONV_BANKS+s_idx][cc];
      }
      //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = old[%d][%d]\n", (int) bank, CONV_ROWS-1, CONV_COLS-1, (int)(CONV_BANKS+s_idx), CONV_COLS-1);}
      line_buffer_m[bank][CONV_ROWS-1][0          ] = lb[bank] ? TwoBit(0) : old_word_buffer_m[CONV_BANKS+s_idx][0];
      line_buffer_m[bank][CONV_ROWS-1][CONV_COLS-1] = rb[bank] ? TwoBit(0) : old_word_buffer_m[CONV_BANKS+s_idx][CONV_COLS-1];
    } else {
      //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = new[%d][%d]\n", (int) bank, CONV_ROWS-1, 0, (int)(s_idx), 0);}
      // fill from new word
      for (ap_uint<4> cc = 1; cc < CONV_COLS-1; cc++) {
      	//if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = new[%d][%d]\n", (int) bank, CONV_ROWS-1, (int)cc, (int)(s_idx), (int) cc);}
        line_buffer_m[bank][CONV_ROWS-1][cc] = (last_wrd) ? TwoBit(0) : word_buffer_m[s_idx][cc];
      }
      //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = new[%d][%d]\n", (int) bank, CONV_ROWS-1, CONV_COLS-1, (int)(s_idx), CONV_COLS-1);}
      line_buffer_m[bank][CONV_ROWS-1][0          ] = (last_wrd || lb[bank]) ? TwoBit(0) : word_buffer_m[s_idx][0];
      line_buffer_m[bank][CONV_ROWS-1][CONV_COLS-1] = (last_wrd || rb[bank]) ? TwoBit(0) : word_buffer_m[s_idx][CONV_COLS-1];
    }
  }



  // line_buffer[8][3][10] => conv_out_buffer[64] (8x8)
  // Convolution
  conv_word( line_buffer_m, conv_params_m, conv_out_buffer_m );

  // Update
  // Fill line buffer with lines from the new word
  for (ap_uint<4> bank = 0; bank < CONV_BANKS; bank++) {
    // --------------------------------------------------------------
    // Top row, slices are shifted right by slices_per_line
    int s_idx0 = bank - slices_per_line;
    //if(local_cnt < 2176){ printf("\ns_idx0 = %d\t = %d - %d\n", (int) s_idx0, (int) bank, (int) slices_per_line); }
    if (s_idx0 >= 0) {
      //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = old[%d][%d]\n", (int) bank, 0, 0, (int)(s_idx0), 0);}
      // slice from input word
      for (ap_uint<4> cc = 1; cc < CONV_COLS-1; cc++) {
      	//if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = old[%d][%d]\n", (int) bank, 0, (int)cc, (int)(s_idx0), (int) cc);}
        line_buffer_m[bank][0][cc] = word_buffer_m[s_idx0][cc];
      }
      //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = old[%d][%d]\n", (int) bank, 0, CONV_COLS-1, (int)(s_idx0), CONV_COLS-1);}
      line_buffer_m[bank][0][0          ] = lb[bank] ? TwoBit(0) : word_buffer_m[s_idx0][0];
      line_buffer_m[bank][0][CONV_COLS-1] = rb[bank] ? TwoBit(0) : word_buffer_m[s_idx0][CONV_COLS-1];
    } else {
      //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = new[%d][%d]\n", (int) bank, 0, 0, (int)(CONV_BANKS+s_idx0), 0);}
      // set to zero or copy from old word (middle row)
      for (ap_uint<4> cc = 1; cc < CONV_COLS-1; cc++) {
        //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = new[%d][%d]\n", (int) bank, 0, (int)cc, (int)(CONV_BANKS+s_idx0), (int) cc);}
        line_buffer_m[bank][0][cc] = (first_wrd) ? TwoBit(0) : old_word_buffer_m[CONV_BANKS+s_idx0][cc];
      }
      //if(local_cnt < 2176){ printf("line_buffer_m[%d][%d][%d] = new[%d][%d]\n", (int) bank, 0, CONV_COLS-1, (int)(CONV_BANKS+s_idx0), CONV_COLS-1);}
      line_buffer_m[bank][0][0          ] = (first_wrd || lb[bank]) ? TwoBit(0) : old_word_buffer_m[CONV_BANKS+s_idx0][0];
      line_buffer_m[bank][0][CONV_COLS-1] = (first_wrd || rb[bank]) ? TwoBit(0) : old_word_buffer_m[CONV_BANKS+s_idx0][CONV_COLS-1];
    }

    // --------------------------------------------------------------
    // Middle row, simply copy the word into the line buffer
    for (ap_uint<4> cc = 1; cc < CONV_COLS-1; cc++) {
      line_buffer_m[bank][1][cc] = word_buffer_m[bank][cc];
    }
    // Fill end buffer bits
    line_buffer_m[bank][1][0          ] = lb[bank] ? TwoBit(0) : word_buffer_m[bank][0];
    line_buffer_m[bank][1][CONV_COLS-1] = rb[bank] ? TwoBit(0) : word_buffer_m[bank][CONV_COLS-1];
  }

  local_cnt++;
}


// -----------------------------------------------------------------------
// A single PE reads from all inputs and weights to generate a single
// output feature map.
// * Make sure this function gets inlined by VHLS, or cosim may fail!
// -----------------------------------------------------------------------
static void bin_conv(
	hls::stream< bit32 > & Input_1,
    Word wt_mem[CONVOLVERS][C_WT_WORDS],
    NormComp nc,
    Word dmem[2][CONVOLVERS][C_DMEM_WORDS],
    ap_uint<1> d_i_idx,
    ap_uint<1> d_o_idx,
    const unsigned   n_inputs,
    Address    o_index,
    ap_uint<1> new_batch,
    ap_uint<2> width_mode,  // 0=8'b, 1=16'b, 2=32'b
    ap_uint<2> norm_mode    // 0='do nothing', 1='do norm', 2='do pool'
) {
  ap_uint<3> log_width = width_mode + LOG_BANK_WIDTH;
  ap_uint<5> words_per_image = 1 << (2*width_mode);
  const unsigned n_phases = n_inputs / CONVOLVERS;
  const unsigned images_per_phase = PIX_PER_PHASE >> (2*log_width);
  const unsigned WORDS_PER_PHASE = PIX_PER_PHASE / WORD_SIZE;

  Word wt_word_buffer_list[2];

  static int local_cnt = 0;

  //if(local_cnt < 128){
	  //printf("bin_conv = %d\n", local_cnt);
  //}
  // ---------------------------------------------------------------------
  // buffers
  // ---------------------------------------------------------------------
  static TwoBit  line_buffer[CONVOLVERS][CONV_BANKS][CONV_ROWS][CONV_COLS];
#pragma HLS ARRAY_PARTITION variable=line_buffer complete dim=0
  Bit     conv_params[CONVOLVERS][K][K];
#pragma HLS ARRAY_PARTITION variable=conv_params complete dim=0

  //                   32               64
  ConvSum fixed_buffer[WORDS_PER_PHASE][WORD_SIZE];
#pragma HLS ARRAY_RESHAPE     variable=fixed_buffer cyclic factor=32 dim=2


//#pragma HLS ARRAY_PARTITION variable=fixed_buffer complete dim=2
  ConvSum fixed_temp[WORD_SIZE];
#pragma HLS ARRAY_PARTITION variable=fixed_temp complete dim=0
  // per-convolver buffers
  TwoBit  word_buffer[CONVOLVERS][CONV_BANKS][CONV_COLS];
#pragma HLS ARRAY_PARTITION variable=word_buffer complete dim=0
  TwoBit  old_word_buffer[CONVOLVERS][CONV_BANKS][CONV_COLS];
#pragma HLS ARRAY_PARTITION variable=old_word_buffer complete dim=0
  ConvOut conv_out_buffer[CONVOLVERS][WORD_SIZE];
#pragma HLS ARRAY_PARTITION variable=conv_out_buffer complete dim=0
  // edge padding flag bits
  bool lb[CONV_BANKS];
#pragma HLS ARRAY_PARTITION variable=lb complete dim=0
  bool rb[CONV_BANKS];
#pragma HLS ARRAY_PARTITION variable=rb complete dim=0

  static Address wt_addr = 0;           // address of weight word
  static ap_int<4> wt_offset = 0;      // offset 0..6 of param
  if (new_batch != 0) { wt_addr = 0; wt_offset = 0; }

  // ---------------------------------------------------------------------
  // Calculate edge padding flag bits
  ap_uint<4> log_slice = log_width - LOG_BANK_WIDTH;
  ap_uint<4> w_div_8 = (1 << log_width) >> 3;
  ap_uint<4> mask = 0xf;   // set mask to all 1s
  mask = mask >> (4-log_slice);

  // lb 10001000
  // rb 00010001

  // lb 10101010
  // rb 01010101

  // lb 11111111
  // rb 11111111
  //                               8
  for (ap_uint<4> bank = 0; bank < CONV_BANKS; bank++) {
    #pragma HLS unroll
    ap_uint<4> x = bank & mask;
    lb[bank] = (x == 0);          // (bank % w_div_8) == 0
    rb[bank] = (x+1 == w_div_8);  // (bank % w_div_8) == w_div_8-1
  }
  //printf("lb: ");
  //for(int i=0; i<8; i++){ printf("%d", (unsigned int) lb[i]); }
  //printf("\nrb: ");
  //for(int i=0; i<8; i++){ printf("%d", (unsigned int) rb[i]); };
  //printf("\n");


  // ---------------------------------------------------------------------
  // Reset conv buffer
                          //32
  for (IdxType i = 0; i < WORDS_PER_PHASE; i++) {
    for (IdxType j = 0; j < WORD_SIZE; j++) {
      #pragma HLS UNROLL
      fixed_buffer[i][j] = 0;
    }
  }


  //wt_word_buffer_list[0] = wt_mem[0][wt_addr];
  //wt_word_buffer_list[1] = wt_mem[1][wt_addr];
  wt_word_buffer_list[0](31,  0) = Input_1.read();
  wt_word_buffer_list[0](63, 32) = Input_1.read();
  //printf("0x%08x,\n", (unsigned int) wt_word_buffer_list[0](63, 32));

  //printf("0x%08x,\n", (unsigned int) wt_word_buffer_list[0](31,  0));
  wt_word_buffer_list[1](31,  0) = Input_1.read();
  wt_word_buffer_list[1](63, 32) = Input_1.read();
  //printf("0x%08x,\n", (unsigned int) wt_word_buffer_list[1](63, 32));

  //printf("0x%08x,\n", (unsigned int) wt_word_buffer_list[1](31,  0));
  //if(local_cnt < 128) { printf("input\ninput\n"); }
  //printf("0x%08x%08x,\n", (unsigned int)wt_word_buffer_list[0](63,32), (unsigned int)wt_word_buffer_list[0](31,0));
  //printf("0x%08x%08x,\n", (unsigned int)wt_word_buffer_list[1](63,32), (unsigned int)wt_word_buffer_list[1](31,0));
  // ---------------------------------------------------------------------
  // Compute in phases
  // Each phase processes CONVOLVERS * WORDS_PER_PHASE input words
  // ---------------------------------------------------------------------
  //if(local_cnt < 128){ printf("n_phases=%d, images_per_phase=%d\n", (int) n_phases, (int) images_per_phase); }
  LOOP_PHASES:
  for (ap_uint<10> p = 0; p < n_phases; p = p + images_per_phase) {
#pragma HLS LOOP_TRIPCOUNT min=1 max=512
    // wrd = which word in the current image
    // wrd_phase = which wrd in the current phase
    ap_uint<8> wrd = 0;
    ap_uint<8> wrd_phase = 0;

    // Load a word each iteration, and then process it
    // We load WORDS_PER_PHASE words per phase, however we also need 1 extra "empty"
    // iteration per image in the phase to do the loop epilogue, so the loop bound
    // is WORDS_PER_PHASE + images_per_phase
    //                                 32+2
    //                                 32+8
    //                                 32+32
    LOOP_WORDS_IN_PHASE:
    for (ap_uint<8> count = 0; count < WORDS_PER_PHASE+images_per_phase; count++) {
#pragma HLS DEPENDENCE variable=fixed_buffer inter false
#pragma HLS LOOP_TRIPCOUNT min=17 max=32
#pragma HLS PIPELINE
      // First word of an image
      if (wrd == 0) {
        Word wt_word_buffer[CONVOLVERS];

        // -------------------------------------------------------------------
        // Load param word
        // Each word contains CONV_W_PER_WORD weight filters, after we use
        // them all we should load the next word
        // -------------------------------------------------------------------
        LOOP_WT_WORDS:
        for (IdxType m = 0; m < CONVOLVERS; m++) {
          int shift_num = ((WT_SIZE*wt_offset)&0x3f);
          wt_word_buffer[m] = wt_word_buffer_list[m] >> shift_num;
        }
        if (wt_offset == CONV_W_PER_WORD-1) {
          wt_addr++;
          wt_word_buffer_list[0](31,  0) = Input_1.read();
          wt_word_buffer_list[0](63, 32) = Input_1.read();
          //printf("0x%08x,\n", (unsigned int) wt_word_buffer_list[0](63, 32));

          //printf("0x%08x,\n", (unsigned int) wt_word_buffer_list[0](31,  0));
          wt_word_buffer_list[1](31,  0) = Input_1.read();
          wt_word_buffer_list[1](63, 32) = Input_1.read();
          //printf("0x%08x,\n", (unsigned int) wt_word_buffer_list[1](63, 32));

          //printf("0x%08x,\n", (unsigned int) wt_word_buffer_list[1](31,  0));
          //if(local_cnt < 128) { printf("input\ninput\n"); }
          wt_offset = 0;
        } else {
          wt_offset++;
        }

        // -------------------------------------------------------------------
        // Load params
        // Each word contains CONV_W_PER_WORD weight filters packed into the first
        // 63 bits, the last bit is unused. Wts are stored in output-major order.
        // -------------------------------------------------------------------
        LOOP_LOAD_WTS:
        for (IdxType m = 0; m < CONVOLVERS; m++) {
          for (ap_uint<2> kr = 0; kr < K; kr++) {
            for (ap_uint<2> kc = 0; kc < K; kc++){
              conv_params[m][kr][kc](0, 0) = wt_word_buffer[m](kr*K+kc, kr*K+kc);
            }
          }
        }
      }

      // -------------------------------------------------------------------
      // Every word in an image
      // -------------------------------------------------------------------
      // Load word
      // (wrd_phase-wrd) is which wrd in the current phase, aligned to img boundary
      //if(local_cnt < 128) printf("wrd = %d, words_per_image = %d\n", (int) wrd, (int)words_per_image);
      if (wrd != words_per_image) {
        LOOP_CONVOLVER_LOAD:
        for (IdxType m = 0; m < CONVOLVERS; m++) {
          Word word = dmem[d_i_idx][m][p*words_per_image + wrd_phase];
          //if(local_cnt<128) printf("load word[%d][%d][%d]\n", (unsigned int)(d_i_idx), (unsigned int)(m), (unsigned int)(p*words_per_image + wrd_phase));
          //                            8
          for (IdxType bank = 0; bank < CONV_BANKS; bank++) {

            //if(local_cnt<128) {
            //	printf("\nbank = %d\n", (int) bank);
            //	printf("word_buffer[%d][%d][%d]=%d\n", (int) m, (int) bank, 0, (int) (bank*BANK_WIDTH-1));
            //}
            for (IdxType cc = 0; cc < CONV_COLS-2; cc++) {
              Bit in_tmp;
              in_tmp(0, 0) = word(bank*BANK_WIDTH+cc, bank*BANK_WIDTH+cc);
              word_buffer[m][bank][cc+1] = encode_bit(in_tmp);
              //if(local_cnt<128) { printf("word_buffer[%d][%d][%d]=%d\n", (int) m, (int) bank, (int) (cc+1), (int) (bank*BANK_WIDTH+cc));}
            }
            //if(local_cnt<128) { printf("word_buffer[%d][%d][%d]=%d\n", (int) m, (int) bank, CONV_COLS-1, (int) ((bank*BANK_WIDTH+BANK_WIDTH)));}
            Bit in_tmp1, in_tmp2;
            in_tmp1(0, 0) = word((bank*BANK_WIDTH-1)&0x3f, (bank*BANK_WIDTH-1)&0x3f);
            in_tmp2(0, 0) = word((bank*BANK_WIDTH+BANK_WIDTH)&0x3f, (bank*BANK_WIDTH+BANK_WIDTH)&0x3f);
            word_buffer[m][bank][0          ] = (bank==0)            ?
              TwoBit(0) : encode_bit(in_tmp1);
            word_buffer[m][bank][CONV_COLS-1] = (bank==CONV_BANKS-1) ?
              TwoBit(0) : encode_bit(in_tmp2);
          }
        }
      }

      // Compute
      // word_buffer[2][8][10] x 2 bits (-1, +1)
      // conv_params[2][3][3] x 1 bits
      LOOP_CONVOLVERS:
      for (int m = 0; m < CONVOLVERS; m++) {
        // Do the following for each word in an image
        process_word( word_buffer[m], old_word_buffer[m], lb, rb, line_buffer[m], conv_params[m],
            conv_out_buffer[m], log_width, words_per_image, wrd );
      } // CONVOLVERS

      for (IdxType m = 0; m < CONVOLVERS; m++) {
        for (IdxType bank = 0; bank < CONV_BANKS; bank++) {
          for (IdxType cc = 0; cc < CONV_COLS; cc++) {
            old_word_buffer[m][bank][cc] = word_buffer[m][bank][cc];
          }
        }
      }

      // -------------------------------------------------------------------
      // Sum results across convolvers
      // -------------------------------------------------------------------
      for (IdxType i = 0; i < WORD_SIZE; i++) {
        // Ignore conv results after processing the first word
        if (wrd > 0) {
          ConvSum s = 0;
          for (IdxType m = 0; m < CONVOLVERS; m++)
            s = s + conv_out_buffer[m][i];
          fixed_buffer[wrd_phase-1][i] = fixed_buffer[wrd_phase-1][i] + s;
        }
      }

      //if(local_cnt < 128){ printf("wrd_phase = %d\n", (int) wrd_phase); }
      // -------------------------------------------------------------------
      // Increment counters
      // -------------------------------------------------------------------
      if (wrd != words_per_image) {
        wrd++;
        wrd_phase++;
      } else {
        wrd = 0;
      }
    } // wrd_phase = 0 .. WORDS_PER_PHASE

  } // n_phases


  //if(local_cnt == 0) printf("words_per_image = %d, WORDS_PER_PHASE=%d\n", (int) words_per_image, WORDS_PER_PHASE);
  LOOP_ACC_PHASES:
  for (ap_uint<5> w = 0; w < words_per_image; w++) {
    #pragma HLS PIPELINE
    #pragma HLS LOOP_TRIPCOUNT min=1 max=1

	//if(local_cnt == 0){ printf("\n\n\nw=%d==========================\n", (int) w); }
    for (IdxType b = 0; b < WORD_SIZE; b++) {
      #pragma HLS unroll
      fixed_temp[b] = fixed_buffer[w][b];
      //if(local_cnt == 0){ printf("fixed_temp[%d] = fixed_buffer[%d][%d];\n", (int) b, (int) w, (int) b); }
    }
    //if(local_cnt == 0){ printf(";\n"); }

    LOOP_ACC_PHASES_I:
    for (ap_uint<8> i = words_per_image; i < WORDS_PER_PHASE; i = i + words_per_image) {
      #pragma HLS LOOP_TRIPCOUNT min=1 max=16
      for (IdxType b = 0; b < WORD_SIZE; b++) {
        fixed_temp[b] =fixed_temp[b] + fixed_buffer[w+i][b];
        //if(local_cnt == 0){ printf("fixed_temp[%d] += fixed_buffer[%d][%d];\n", (int) b, (int) (w+i), (int) b); }
      }
    }
    //if(local_cnt == 0){ printf(";\n"); }

    for (IdxType b = 0; b < WORD_SIZE; b++) {
      #pragma HLS unroll
      fixed_buffer[w][b] = fixed_temp[b];
      //if(local_cnt == 0){ printf("fixed_buffer[%d][%d] = fixed_temp[%d];\n", (int) b, (int) (w), (int) b); }
    }
    //if(local_cnt == 0){ printf(";\n"); }
  } // end of LOOP_ACC_PHASES: w < words_per_image

  const Address bank_idx = o_index % CONVOLVERS;
  Address bank_off = o_index / CONVOLVERS;
  ap_uint<5> pool_width = 1 << (log_width-1);

  static Word outword;
  Word poolword;
  LOOP_BATCH_NORM:
  for (ap_uint<6> w = 0; w < words_per_image; w++) {
#pragma HLS LOOP_TRIPCOUNT min=1 max=16
#pragma HLS PIPELINE
    Word binword;
    Address o_bank_idx = bank_idx;
    Address o_bank_offset = bank_off*words_per_image + w;
    ap_uint<6> out_offset = (w % 4) << 4;

    for (ap_uint<7> i = 0; i < WORD_SIZE; i++) {
      binword(i, i) = (fixed_buffer[w][i] >= nc) ? 0 : 1;
    }

    if (norm_mode == 1) {
      outword = binword;
    }
    else if (norm_mode == 2) {
      // horizontal pooling first
      ap_int<WORD_SIZE/2> poolword_h;
      for (ap_uint<6> i = 0; i < WORD_SIZE/2; i++) {
        poolword_h(i, i) = binword(2*i, 2*i) & binword(2*i+1, 2*i+1);
      }

      // vertical pooling
      for (ap_uint<6> i = 0; i < WORD_SIZE/4; i++) {
        // source indices
        ap_uint<5> i0 = i >> (log_width-1);
        i0 = (i0 << log_width) + i(log_width-2,0);
        ap_uint<5> i1 = i0 + pool_width;
        // dest index
        ap_uint<6> d0 = out_offset + i;
        poolword(d0, d0) = poolword_h(i0, i0) & poolword_h(i1, i1);
      }

      // For log_width > 3 we can just assign the word, but log_width = 3 means width = 8,
      // which means pooled width = 4, which is only 16 bits, which is less than 1 Word.
      // So each time we get here we only have 16 bits, meaning we have to accumulate four
      // of these 16-bit batches before writing a word out.
      if (log_width != LOG_BANK_WIDTH) {
        o_bank_offset = o_bank_offset / 4;
        outword = poolword;
      } else {
    	int shift_num = WORD_SIZE/4;
        outword = outword >> shift_num;
        outword(63,48) = poolword(15,0);
        o_bank_idx = (o_index/4)%CONVOLVERS;
        o_bank_offset = (o_index/4)/CONVOLVERS;
      }
    }

    //if(local_cnt <128){printf("dmem[%d][%d][%d] = outword;\n", (int) d_o_idx, (int) o_bank_idx, (int) o_bank_offset); }
    dmem[d_o_idx][o_bank_idx][o_bank_offset] = outword;
  }
  local_cnt++;
}





void bin_conv_2(

	hls::stream< bit32 > & Input_1,
	hls::stream< bit32 > & Input_2,
	hls::stream< bit32 > & Output_1
) {
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1

	static unsigned int bin_conv_cnt = 0;
	static Word dmem[2][CONVOLVERS][C_DMEM_WORDS];
#pragma HLS ARRAY_PARTITION variable=dmem complete dim=2
#pragma HLS ARRAY_PARTITION variable=dmem complete dim=1
    Word wt_mem[CONVOLVERS][C_WT_WORDS];
#pragma HLS ARRAY_PARTITION variable=wt_mem complete dim=1
	Word kh_mem[KH_WORDS];

    ap_uint<1> d_i_idx_list[] =          {0,  0,  0,  0,  0,  0  };
    ap_uint<1> d_o_idx_list[]  =         {1,  1,  1,  1,  1,  1  };
    Address n_inputs_list[] =      {512,512,512,512,512,512};
    Address o_index_list[] =       {128,192,256,320,384,448};
    ap_uint<2> width_mode_list[] = {0,  0,  0,  0,  0,  0  };
    ap_uint<2> norm_mode_list[] =  {2,  2,  2,  2,  2,  2  };
    Address n_outputs_list[] =     {64,64,  64, 64, 64, 64 };

    Address o_index = o_index_list[bin_conv_cnt];
    Address n_outputs = n_outputs_list[bin_conv_cnt];
    Address kh_index = 0;

    //printf("bin_conv_cnt=%d\n", bin_conv_cnt);


    for(unsigned int kh_i=0; kh_i<KH_WORDS; kh_i++)
    {
#pragma HLS PIPELINE
    	kh_mem[kh_i](31,  0) = Input_1.read();
    	kh_mem[kh_i](63, 32) = Input_1.read();

    	//printf("0x%08x%08x,\n", (unsigned int) kh_mem[kh_i](63,32), (unsigned int) kh_mem[kh_i](31,0));
    }


    if(bin_conv_cnt == 0)
    {
		for(unsigned int dmem_i=0; dmem_i<2; dmem_i++)
		  for(unsigned int dmem_j=0; dmem_j<CONVOLVERS; dmem_j++)
			for(unsigned int dmem_k=0; dmem_k<C_DMEM_WORDS; dmem_k++)
			{
#pragma HLS PIPELINE
				dmem[dmem_i][dmem_j][dmem_k](31,  0) = Input_2.read();
				dmem[dmem_i][dmem_j][dmem_k](63, 32) = Input_2.read();
			}

    }


    LOOP_IMG_BATCH:
    for (int i = 0; i < n_outputs; ++i) {
      // Load the batch-norm parameters for this output
      NormComp nc;
      load_kh(nc, kh_mem, kh_index);

      bin_conv(
    	  Input_1,
          wt_mem,
          nc,
          dmem,
          d_i_idx_list[bin_conv_cnt],
		  d_o_idx_list[bin_conv_cnt],
          n_inputs_list[bin_conv_cnt],
          o_index,
          i == 0 ? 1 : 0,         // new_batch
          width_mode_list[bin_conv_cnt],
          norm_mode_list[bin_conv_cnt]
      );

      kh_index++;
      o_index++;
    }


    if(bin_conv_cnt == 5)
    {
		for(unsigned int dmem_i=0; dmem_i<2; dmem_i++)
		  for(unsigned int dmem_j=0; dmem_j<2; dmem_j++)
			for(unsigned int dmem_k=0; dmem_k<64; dmem_k++){
			  #pragma HLS PIPELINE
                          unsigned int out_tmp;
                          out_tmp = dmem[dmem_i][dmem_j][dmem_k](31,  0);
                          Output_1.write(out_tmp);
                          out_tmp = dmem[dmem_i][dmem_j][dmem_k](63, 32);
                          Output_1.write(out_tmp);
			}
    }

    bin_conv_cnt++;
    if(bin_conv_cnt==6) bin_conv_cnt = 0;

}







// -----------------------------------------------------------------------
// Module to do the first conv layer
// -----------------------------------------------------------------------
