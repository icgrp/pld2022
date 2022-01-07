/*===============================================================*/
/*                                                               */
/*                       face_detect.h                           */
/*                                                               */
/*     Hardware function for the Face Detection application.     */
/*                                                               */
/*===============================================================*/


#include "../host/typedefs.h"

void top

(
  hls::stream<ap_uint<512> > & Input_1,
  hls::stream<ap_uint<512> > & Output_1
);


void data_gen
(
  hls::stream<ap_uint<512> > & Output_1
);
