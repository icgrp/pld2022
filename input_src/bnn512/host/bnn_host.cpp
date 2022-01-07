#include "stdio.h"
#include "label.h"
#include "typedefs.h"


#include "data_in_gen_0.h"
#include "data_in_gen_1.h"
#include "data_in_gen_2.h"
#include "data_in_gen_3.h"
#include "data_in_gen_4.h"
#include "top.h"


int main(int argc, char** argv) {
	hls::stream< Word > data_gen_out0("data_gen_out0");
	hls::stream< Word > data_gen_out1("data_gen_out1");
	hls::stream< Word > data_gen_out2("data_gen_out2");
	hls::stream< Word > data_gen_out3("data_gen_out3");
	hls::stream< bit32 > data_gen_out4("data_gen_out4");


	hls::stream< bit32 > bin_dense_out1("bin_dense_out1");

	Word dmem_o[8*2*64];
	int i, j;
	int err_cnt = 0;
	unsigned N_IMG;
	if (argc < 2) {
		printf ("We will use default N_IMG = 10\n");
		N_IMG  = 10;
	}else{
		N_IMG  = std::stoi(argv[1]);
	}

	printf("Hello world\n");


	data_in_gen_0(data_gen_out0);
	data_in_gen_1(data_gen_out0, data_gen_out1);
	data_in_gen_2(data_gen_out1, data_gen_out2);
	data_in_gen_3(data_gen_out2, data_gen_out3);
	data_in_gen_4(IMAGE_NUM, data_gen_out3, data_gen_out4);



    top(data_gen_out4, bin_dense_out1);


    // for(i=0; i<N_IMG; i++){
	for(i=0; i<IMAGE_NUM; i++){
	  //printf("We are processing %d images\n", i);

      for(j=0; j<256; j++){ dmem_o[j](31, 0) = bin_dense_out1.read(); }

      int recv_cnt = 0;
      recv_cnt = (int) dmem_o[0](31,0);

      printf("We will receive %d\n", recv_cnt);

      ap_int<8> p = 0;
      p(7,0) = dmem_o[1](7,0);

      int prediction = p.to_int();
      if(prediction == y[i]){
        printf("Pred/Label: %d/%d [ OK ]\n", prediction, y[i]);
      }else{
        printf("Pred/Label: %d/%d [FAIL]\n", prediction, y[i]);
        err_cnt++;
      }
	}

	printf("We got %d/%d errors\nDone\n", err_cnt, N_IMG);

	return 0;
}
