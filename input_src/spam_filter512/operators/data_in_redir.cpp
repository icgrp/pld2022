#include "../host/typedefs.h"
//data_input_redirection
void data_in_redir( hls::stream<ap_uint<512> > & Input_1,
			hls::stream<ap_uint<64> > & Output_1,
			hls::stream<ap_uint<64> > & Output_2
			)
{
#pragma HLS INTERFACE axis register port=Input_1
#pragma HLS INTERFACE axis register port=Output_1
#pragma HLS INTERFACE axis register port=Output_2
	bit32 tmp_data;
  // intermediate variables
  // local buffer of labels
  static LabelType   label_local[4600];
  #pragma HLS array_partition variable=label_local cyclic factor=8
  // array for storing one training instance
  static DataType training_instance[NUM_FEATURES];
  static int epoch = 0;
  bit128 dump = 0;
  bit32 tmp_label;
  bit512 in_tmp;
  bit64 out_tmp;

  if (epoch == 0)
  {
    // copy in labels
	//LABEL_CP: for (int i = 0; i < NUM_TRAINING / L_VECTOR_SIZE; i ++ )
	LABEL_CP: for (int i = 0; i < 71; i ++ )
	{
#pragma HLS PIPELINE II=1
          in_tmp = Input_1.read();
          for(int j=0; j<64; j++){
            label_local[i*64+j](LTYPE_WIDTH-1, 0) = in_tmp(j*8+7, j*8);
          }
	}
  }

  // main loop
  // in each epoch, go through each training instance in sequence
  TRAINING_INST: for( int training_id = 0; training_id < NUM_TRAINING; training_id ++ )
  {
    // get the label
    LabelType training_label;
    training_label(LTYPE_WIDTH-1, 0)= label_local[training_id].range(LTYPE_WIDTH-1, 0);
    // first reads in the training instance
    out_tmp(7,0) = training_label.range(7, 0);
    Output_1.write(out_tmp);
    READ_TRAINING_DATA_top: for (int i = 0; i < NUM_FEATURES / D_VECTOR_SIZE / 16; i ++ )
    {
#pragma HLS PIPELINE II=2
      in_tmp = Input_1.read(); 
      for(int j=0; j<8; j++){
        out_tmp(31, 0) = in_tmp(64*j+31, 64*j+0 );
        out_tmp(63,32) = in_tmp(64*j+63, 64*j+32);
        Output_1.write(out_tmp);
      }
    }
    out_tmp(7,0) = training_label.range(7, 0);
    Output_2.write(out_tmp);
    READ_TRAINING_DATA_bot: for (int i = 0; i < NUM_FEATURES / D_VECTOR_SIZE / 16; i ++ )
    {
#pragma HLS PIPELINE II=2
      in_tmp = Input_1.read(); 
      for(int j=0; j<8; j++){
        out_tmp(31, 0) = in_tmp(64*j+31, 64*j+0 );
        out_tmp(63,32) = in_tmp(64*j+63, 64*j+32);
        Output_2.write(out_tmp);
      }
    }

  }
  epoch = epoch+1;
}

