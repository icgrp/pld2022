#include "../host/typedefs.h"


void gradient_xyz_calc(    
    hls::stream< ap_uint<64> > &Input_1,
    hls::stream< ap_uint<32> > &Output_1,
    hls::stream< ap_uint<32> > &Output_2,
    hls::stream< ap_uint<32> > &Output_3)
{
	#pragma HLS interface axis register port=Input_1
	#pragma HLS interface axis register port=Output_1
	#pragma HLS interface axis register port=Output_2
	#pragma HLS interface axis register port=Output_3

	// our own line buffer
	static pixel_t buf[5][MAX_WIDTH+2];
	#pragma HLS array_partition variable=buf complete dim=1

	// small buffer
	pixel_t smallbuf[5];
	#pragma HLS array_partition variable=smallbuf complete dim=0

	// window buffer
#ifdef RISCV
	hls::Window<5,5,input_t> window;
#else
	xf::cv::Window<5,5,input_t> window;
#endif


	ap_fixed<17, 9> GRAD_WEIGHTS[] =  {1,-8,0,8,-1};
	#ifdef RISCV
		hls::stream_local<databus_t> gradient_z;
	#else
		hls::stream<databus_t> gradient_z;
		#pragma HLS STREAM variable=gradient_z depth=3*MAX_WIDTH
	#endif


	// compute gradient
	pixel_t x_grad = 0;
	pixel_t y_grad = 0;
	databus_t grad_z;
	databus_t temp1 = 0;
	databus_t temp2 = 0;
	databus_t temp3 = 0;



	GRAD_XY_OUTER: for(int r=0; r<MAX_HEIGHT+2; r++){
		#ifdef RISCV
			print_str("r=");
			print_dec(r);
			print_str("\n");
		#endif

		GRAD_XY_INNER: for(int c=0; c<MAX_WIDTH+2; c++){
			#pragma HLS pipeline II=1
#ifdef RISCV1
	print_str("r=");
	print_dec(r);
	print_str("\n");
	print_str("c=");
	print_dec(c);
	print_str("\n");
#endif

			// read out values from current line buffer
			for (int i = 0; i < 4; i ++ ){ smallbuf[i] = buf[i+1][c]; }

			// the new value is either 0 or read from frame
			if (r<MAX_HEIGHT && c<MAX_WIDTH){
				databus_t pixel1, pixel2, pixel3, pixel4, pixel5;
				ap_uint<64> in_tmp;
				in_tmp= Input_1.read();
				pixel1 = 0;
				pixel2 = 0;
				pixel3 = 0;
				pixel4 = 0;
				pixel5 = 0;
				pixel1(7,0) = in_tmp(7,0);
				pixel2(7,0) = in_tmp(15,8);
				pixel3(7,0) = in_tmp(23,16);
				pixel4(7,0) = in_tmp(31,24);
				pixel5(7,0) = in_tmp(39,32);

				databus_t tmpread = pixel3;
				input_t tmpin = 0;
				tmpin(16,0) = tmpread(16,0);
				smallbuf[4] = (pixel_t)(tmpin);

				input_t frame1_tmp,frame2_tmp,frame3_tmp,frame4_tmp,frame5_tmp;
				frame1_tmp = 0;
				frame2_tmp = 0;
				frame3_tmp = 0;
				frame4_tmp = 0;
				frame5_tmp = 0;
				databus_t data = 0;
				pixel_t temp_z = 0;
				data = pixel1;
				frame1_tmp(16,0) = data(16,0);
				data = pixel2;;
				frame2_tmp(16,0) = data(16,0);
				data = pixel3;;
				frame3_tmp(16,0) = data(16,0);
				data = pixel4;
				frame4_tmp(16,0) = data(16,0);
				data = pixel5;
				frame5_tmp(16,0) = data(16,0);
				temp_z =((pixel_t)(frame1_tmp*GRAD_WEIGHTS[0]
				+ frame2_tmp*GRAD_WEIGHTS[1]
				+ frame3_tmp*GRAD_WEIGHTS[2]
				+ frame4_tmp*GRAD_WEIGHTS[3]
				+ frame5_tmp*GRAD_WEIGHTS[4]))/12;
				grad_z(31,0) = temp_z(31,0);
				gradient_z.write(grad_z);
			} else if (c < MAX_WIDTH)
				smallbuf[4] = 0;

			// update line buffer
			if(r<MAX_HEIGHT && c<MAX_WIDTH){
				for (int i = 0; i < 4; i ++ ) { buf[i][c] = smallbuf[i]; }
				buf[4][c] = smallbuf[4];
			}else if(c<MAX_WIDTH){
				for (int i = 0; i < 4; i ++ ) { buf[i][c] = smallbuf[i]; }
				buf[4][c] = smallbuf[4];
			}

			// manage window buffer
			if(r<MAX_HEIGHT && c<MAX_WIDTH){
				window.shift_pixels_left();

				for (int i = 0; i < 5; i ++ )
				window.insert_pixel(smallbuf[i],i,4);
			} else {
				window.shift_pixels_left();
				window.insert_pixel(0,0,4);
				window.insert_pixel(0,1,4);
				window.insert_pixel(0,2,4);
				window.insert_pixel(0,3,4);
				window.insert_pixel(0,4,4);
			}



			x_grad = 0;
			y_grad = 0;
			if(r>=4 && r<MAX_HEIGHT && c>=4 && c<MAX_WIDTH){
				GRAD_XY_XYGRAD: for(int i=0; i<5; i++){
					x_grad = x_grad + window.getval(2,i)*GRAD_WEIGHTS[i];
					y_grad = y_grad + window.getval(i,2)*GRAD_WEIGHTS[i];
				}
				x_grad = x_grad/12;
				temp1(31,0) = x_grad(31,0);
				Output_1.write(temp1);
				//printf("0x%08x,\n", temp1.to_int());
				y_grad = y_grad/12;
				temp2(31,0) = y_grad(31,0);
				Output_2.write(temp2);
				//printf("0x%08x,\n", temp2.to_int());
				temp3 = gradient_z.read();
				Output_3.write(temp3);
				//printf("0x%08x,\n", temp3.to_int());
			} else if(r>=2 && c>=2) {
				Output_1.write(0);
				//printf("0x%08x,\n", 0);
				Output_2.write(0);
				//printf("0x%08x,\n", 0);
				temp3 = gradient_z.read();
				Output_3.write(temp3);
				//printf("0x%08x,\n", temp3.to_int());
			}
		}
	}
}

