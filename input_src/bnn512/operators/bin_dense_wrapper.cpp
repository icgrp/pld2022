#include "../host/typedefs.h"

void bin_dense(
    const Word wt_mem[CONVOLVERS][C_WT_WORDS],
    const Word kh_mem[KH_WORDS],
    Word dmem[2][CONVOLVERS][64]
) {
  static char ctrl_i = 0;
  ap_uint<2> layer_type;
  ap_uint<1> d_i_idx;
  ap_uint<1> d_o_idx;
  Address o_index;
  unsigned n_inputs;
  unsigned n_outputs;
  ap_uint<32> tmp1_list[] = {0x21000000,0x21002000,0x21004000,0x21006000,0x21008000,0x2100a000,0x2100c000,0x2100e000,
		                      0x21010000,0x21012000,0x21014000,0x21016000,0x21018000,0x2101a000,0x2101c000,0x2101e000,
						   	  0x21020000,0x21022000,0x21024000,0x21026000,0x21028000,0x2102a000,0x2102c000,0x2102e000,
							  0x21030000,0x21032000,0x21034000,0x21036000,0x21038000,0x2103a000,0x2103c000,0x2103e000,
							  0x20100000,0x20110000,0x20120000,0x20130000,0x31000000};


  ap_uint<32> tmp2_list[] = {0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,
		                      0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,
							  0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,
							  0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,0x20000020,
							  0x04000100,0x04000100,0x04000100,0x04000100,0x0400000a};

  layer_type(1,0)  = tmp1_list[ctrl_i](31,28);
  d_i_idx(0,0)     = tmp1_list[ctrl_i](27,24);
  d_o_idx(0,0)     = tmp1_list[ctrl_i](23,20);
  o_index(15,0)     = tmp1_list[ctrl_i](19, 8);

  n_inputs    = tmp2_list[ctrl_i](31,16);
  n_outputs   = tmp2_list[ctrl_i](15, 0);

  //assert(n_outputs % WORD_SIZE == 0);


  ctrl_i++;
  if(ctrl_i==37) ctrl_i=0;

  DenseSum sum_m[CONVOLVERS];
  // for last layer
  DenseNorm best_out = -1024;
  ap_int<8> prediction = -1;

  // read words from dmem and the wt store, dot them
  // o is the output bit, i is the input bit
  LOOP_DENSE_O:
  for (int o = 0; o < n_outputs; ++o) {
#pragma HLS LOOP_TRIPCOUNT min=1 max=1
    Address o_addr = (o_index+o)/WORD_SIZE;
    ap_uint<6> o_offset = (o_index+o) % WORD_SIZE;
    Word o_word = dmem[d_o_idx][o_addr%CONVOLVERS][o_addr/CONVOLVERS];
    //printf("i,%d, j,%d, k,%d\n", (unsigned int) d_o_idx, (unsigned int) (o_addr%CONVOLVERS), (unsigned int)(o_addr/CONVOLVERS));

    DenseSum sum = 0;

    LOOP_DENSE_I:
    for (int i = 0; i < n_inputs; i+=CONVOLVERS*WORD_SIZE) {
#pragma HLS PIPELINE
#pragma HLS LOOP_TRIPCOUNT min=1 max=64
      Address wt_addr = (o*n_inputs+i) / WORD_SIZE;

      for (int j = 0; j < CONVOLVERS; ++j) {
        // in_wrd addr = [(i/WORD_SIZE+j) % CONVOLVERS][(i/WORD_SIZE+j) / CONVOLVERS]
        // wt_wrd addr = [wt_addr % CONVOLVERS][wt_addr / CONVOLVERS]
        Word in_wrd = dmem[d_i_idx][j][i/WORD_SIZE/CONVOLVERS];
        //printf("i,%d, j,%d, k,%d\n", (unsigned int) d_i_idx, (unsigned int) (j), (unsigned int)(i/WORD_SIZE/CONVOLVERS));
        Word wt_wrd = wt_mem[j][wt_addr / CONVOLVERS];


        Word x = wt_wrd ^ in_wrd;

        // count_set bit for 64 bits, returns 2*cnt
	Word m1, m2, m4;
	m1(63, 32) = 0x55555555;
	m1(31,  0) = 0x55555555;
	m2(63, 32) = 0x33333333;
	m2(31,  0) = 0x33333333;
	m4(63, 32) = 0x0f0f0f0f;
	m4(31,  0) = 0x0f0f0f0f;
        x = x - ((x >> 1) & m1);
        x = (x & m2) + ((x >> 2) & m2);
        x = (x + (x >> 4)) & m4;
        x = x + (x >> 8);
        x = x + (x >> 16);
        x = x + (x >> 32);
        x = x & ((Word) 0x7f);
        sum_m[j] = WORD_SIZE - (DenseSum)(x<<1);
      }

      for (int j = 0; j < CONVOLVERS; ++j)
        sum = sum + sum_m[j];
    } // n_inputs

    // not last layer -> biniarize,
    // otherwise just store the value as a 64bit word
    if (layer_type == LAYER_DENSE) {
      Address kh_addr = o / KH_PER_WORD;
      Word kh_word = kh_mem[kh_addr];

      NormComp nc;
      IdxType kh_off = o % KH_PER_WORD;
      if (kh_off == 0)
        nc(15,0) = kh_word(15, 0);
      else if (kh_off == 1)
        nc(15,0) = kh_word(31,16);
      else if (kh_off == 2)
        nc(15,0) = kh_word(47,32);
      else
        nc(15,0) = kh_word(63,48);
      unsigned char tmp;
      tmp = o_offset;
      o_word(tmp, tmp) = (sum >= nc) ? 0 : 1;
    } else {
      Address kh_addr = o / (const unsigned)2;
      Word kh_word = kh_mem[kh_addr];

      KType ki;  HType hi;
      IdxType kh_off = o % 2;
      if (kh_off == 0) {
        ki(15,0) = kh_word(15, 0);
        hi(15,0) = kh_word(31,16);
      } else {
        ki(15,0) = kh_word(47,32);
        hi(15,0) = kh_word(63,48);
      }

      //printf (" >> %d * %f + %f\n", sum.to_int(), ki.to_float(), hi.to_float());
      ap_fixed<20,10> out = ap_fixed<20,10>(sum)*ki + hi;

      if (o == 0 || out > best_out) {
        prediction = o;
        best_out = out;
      }
    }

    dmem[d_o_idx][o_addr%CONVOLVERS][o_addr/CONVOLVERS] = o_word;
    //printf("i,%d, j,%d, k,%d\n", (unsigned int) d_o_idx, (unsigned int) (o_addr%CONVOLVERS), (unsigned int)(o_addr/CONVOLVERS));
  } // n_outputs

  // Here we are using o_index as a bit index, not a word index!
  if (layer_type == LAYER_LAST) {
    Word o_word;
    o_word(7,0) = prediction(7,0);
    o_word(WORD_SIZE-1, 8) = 0;
    dmem[d_o_idx][0][0] = o_word;
    //printf("i,%d, j,%d, k,%d\n", (unsigned int) d_o_idx, (unsigned int) (0), (unsigned int)(0));
  }
}

void bin_dense_wrapper(
	hls::stream< bit32 > & Input_1,
	hls::stream< bit32 > & Input_2,
	hls::stream< bit512 > & Output_1
) {
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Input_2
#pragma HLS INTERFACE axis register port=Output_1

	static Word dmem[2][CONVOLVERS][64];
#pragma HLS ARRAY_PARTITION variable=dmem complete dim=2
#pragma HLS ARRAY_PARTITION variable=dmem complete dim=1
	Word wt_mem[CONVOLVERS][C_WT_WORDS];
#pragma HLS ARRAY_PARTITION variable=wt_mem complete dim=1
	Word kh_mem[KH_WORDS];
	static char bin_dense_cnt = 0;

	//printf("bin_dense_cnt=%d\n", bin_dense_cnt);

    for(unsigned int wt_mem_i=0; wt_mem_i<CONVOLVERS; wt_mem_i++)
      for(unsigned int wt_mem_j=0; wt_mem_j<C_WT_WORDS; wt_mem_j++)
      {
#pragma HLS PIPELINE
    	wt_mem[wt_mem_i][wt_mem_j](31,  0) = Input_1.read();
    	wt_mem[wt_mem_i][wt_mem_j](63, 32) = Input_1.read();
    	//printf("%08x%08x,\n", (unsigned int) wt_mem[wt_mem_i][wt_mem_j](63,32), (unsigned int) wt_mem[wt_mem_i][wt_mem_j](31,0));
      }

    for(unsigned int kh_i=0; kh_i<KH_WORDS; kh_i++)
    {
    	kh_mem[kh_i](31,  0) = Input_1.read();
    	kh_mem[kh_i](63, 32) = Input_1.read();
    	//printf("%08x%08x,\n", (unsigned int) kh_mem[kh_i](63,32), (unsigned int) kh_mem[kh_i](31,0));
    }

	if(bin_dense_cnt == 0)
	{
		for(int i=0; i<2; i++)
		  for(int j=0; j<2; j++)

#pragma HLS PIPELINE
for(int k=0; k<64; k++){
				dmem[i][j][k](31,  0) = Input_2.read();
				dmem[i][j][k](63, 32) = Input_2.read();
				//printf("%08x%08x\n", (unsigned int) dmem[i][j][k](63,32), (unsigned int) dmem[i][j][k](63,32));
			}
	}



	bin_dense(
		wt_mem,
	    kh_mem,
	    dmem
	);


	if(bin_dense_cnt == 36)
	{
		//for(int i=0; i<2; i++)
		//for(int j=0; j<2; j++)
		//for(int k=0; k<64; k++){
		//#pragma HLS PIPELINE
		//Output_1.write(256*64);
		//DMA_Word out_tmp;
		//out_tmp(127,64) = 0;
		//out_tmp(63,0) = dmem[0][j][k];
                bit512  out_tmp;
                out_tmp(31, 0) = dmem[0][0][0](31, 0);
		Output_1.write(out_tmp);
                //printf("predict: %d\n",(unsigned int) dmem[0][0][0](31, 0));
		//}
	}
	bin_dense_cnt++;
	if(bin_dense_cnt==37) bin_dense_cnt=0;

}
