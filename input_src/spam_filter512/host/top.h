/*===============================================================*/
/*                                                               */
/*                            sgd.h                              */
/*                                                               */
/*          Top-level hardware function declaration              */
/*                                                               */
/*===============================================================*/

#include "../host/typedefs.h"
#include <hls_stream.h>

// top-level function declaration
void top( hls::stream<ap_uint<512> > & Input_1,
			hls::stream<ap_uint<512> > & Output_1
			);

