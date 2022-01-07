/*===============================================================*/
/*                                                               */
/*                          digitrec.h                           */
/*                                                               */
/*             Hardware function for digit recognition           */
/*                                                               */
/*===============================================================*/

#include "../host/typedefs.h"

//#pragma SDS data mem_attribute(global_training_set:PHYSICAL_CONTIGUOUS, global_test_set:PHYSICAL_CONTIGUOUS, global_results:PHYSICAL_CONTIGUOUS)
//#pragma SDS data data_mover(global_training_set:AXIDMA_SIMPLE, global_test_set:AXIDMA_SIMPLE, global_results:AXIDMA_SIMPLE)
//void DigitRec(WholeDigitType global_training_set[NUM_TRAINING / 2], WholeDigitType global_test_set[NUM_TEST], LabelType global_results[NUM_TEST], int run);

void top(hls::stream<ap_uint<512> > & Input_1, hls::stream<ap_uint<32> > & Output_1);

void top_top (bit512 * input2, bit512 * output2);
