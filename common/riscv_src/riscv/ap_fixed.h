/*
* Company: IC group, University of Pennsylvania
* Engineer: Yuanlong Xiao
*
* Create Date: 02/02/2021
* Design Name: ap_fixed
* Project Name:
* Versions: 1.0
* Description:
*   This is a manual implementation of ap_fixed to replace ap_fixed.h from Xilinx
*
* Dependencies:
*
* Revision:
* Revision 0.01 - File Created
* Revision 0.02 - add << overloading function
* Revision 0.03 - rename the input argument (data) to din for member function data_to_array. 
*                 avoid shadow variables with data[]. This may help potential deadlock
* Revision 0.04 - Disable floating point operations to accelerate dotProduct in Spam Filter
* Revision 0.05 - Overload / operators with unsigned int to compensate the average operations
*                 in optical flow gradient_xyz page
* Revision 0.06 - Use BYTE_SIZE(X) to define the array, as optical flow gradient_xyz
*                 define ap_fix<17, 9> datatype.
* Revision 0.07 - overloading operation ap_fixed<_AP_W, _AP_I> / ap_fixed<_AP_W, _AP_I>
*                 This may benefit flow_calc page for Optical Flow benchmark
* Additional Comments:
*/


#ifndef __ap_fixed_H__
#define __ap_fixed_H__


enum debug_val {UNDEF=0, MUL=1, TO_FLOAT=2, DIV=3, ADD=4};
extern debug_val db_flag;


#include "stdio.h"
#define BYTE_SIZE(X)  ((X>>3)+((X&0x7) ? 1 : 0))

template <int _AP_W, int _AP_I>
class ap_fixed{

	// With the proxy struct, the bitwise operations can be overloaded.
	// ap_uint<32> tmp;
	// tmp(7,0) = 0;
	struct Proxy{
		ap_fixed<_AP_W, _AP_I>* parent = nullptr;
		unsigned char hi, lo;

		// When ap_unit is rhs
		Proxy& operator =(unsigned long long u) { parent->set(hi, lo, u); return *this;}

		Proxy& operator =(Proxy u) {parent->set(hi, lo, u); return *this;}

		// When ap_unit is lhs
		operator unsigned int () {return parent->range(hi, lo);}
	};

	public:
		// Define the local variable to store the value
		// Currently, the unit is bytes. If the users define a ap_fixed<17, 10> variable,
		// the real data size is 3 bytes.
		unsigned char data[BYTE_SIZE(_AP_W)];

		// constructor
		ap_fixed<_AP_W, _AP_I>(){
			for(int i=0; i<BYTE_SIZE(_AP_W); i++){
				data[i] = 0;
			}
		}

		// constructor
		//ap_fixed<_AP_W, _AP_I>(unsigned int u) {data = u;}
		ap_fixed<_AP_W, _AP_I>(double f) {
			unsigned char is_minus; // the sign of the input f
			long long i_part; // Integer part of the intput f
			double d_part; // Decimal parts of the intput f
			unsigned char i;
			unsigned char byte_num;;
			unsigned char bit_num;


			// Initialize the data values
			for(i=0; i<BYTE_SIZE(_AP_W); i++){ data[i] = 0; }

			// Extract the sign, integer part and decimal part
			is_minus = (f<0) ? 1 : 0;
			i_part = is_minus ? (unsigned int) (-f) : (unsigned int) f;
			d_part = is_minus ? -f - i_part : f-i_part;


			// process the integer parts of the double variables
			for(i=0; i<(_AP_I); i++){
				byte_num = (_AP_W-_AP_I+i)>>3;
				bit_num = (_AP_W-_AP_I+i)- (byte_num<<3);
				if(i_part & 0x01){
					data[byte_num] = set_bit(data[byte_num], bit_num);
				}else{
					data[byte_num] = clr_bit(data[byte_num], bit_num);
				}
				i_part = i_part >> 1;
			}

			// process the decimal parts of the double variables
			for(i=0; i<(_AP_W-_AP_I); i++){
				d_part = d_part * 2;
				byte_num = (_AP_W-_AP_I-i-1)>>3;
				bit_num = (_AP_W-_AP_I-i-1)- (byte_num<<3);

				if(d_part >= 1){
					data[byte_num] = set_bit(data[byte_num], bit_num);
					d_part = d_part - 1;
				}else{
					data[byte_num] = clr_bit(data[byte_num], bit_num);
				}
				// The rounding scheme for last bit. If there is residue, round up for minus number, round down for positive number
				if((i==(_AP_W-_AP_I-1)) && (d_part > 0) && is_minus){ array_add1(data, BYTE_SIZE(_AP_W)); }
			}

			// if the variable is a negative double, convert it to 2'complementary value
			if(is_minus){
				array_inv(data, BYTE_SIZE(_AP_W));
				array_add1(data, BYTE_SIZE(_AP_W));
			}

			// if _AP_W is not the multiples of 8, set the residue value to the correct number
			if(_AP_W < (BYTE_SIZE(_AP_W)<<3)){
				for(i=_AP_W; i<(BYTE_SIZE(_AP_W)<<3); i++){
					byte_num = i >> 3;
					bit_num = i & 0x7;
					if(is_minus){
						data[byte_num] = set_bit(data[byte_num], bit_num);
					}else{
						data[byte_num] = clr_bit(data[byte_num], bit_num);
					}
				}
			}
		}

		// constructor
		template <int _AP_W_2, int _AP_I_2>
		ap_fixed<_AP_W, _AP_I>(ap_fixed<_AP_W_2, _AP_I_2> op2){
			FIXED2FIXED (data, _AP_W, _AP_I, op2);
		}

		template <int _AP_W_2, int _AP_I_2>
		void FIXED2FIXED (unsigned char *din, int ap_w, int ap_i, ap_fixed<_AP_W_2, _AP_I_2> op2){
			unsigned char bits_array[ap_w];  // String array for the target ap_fixed variable
			unsigned char bits_array2[_AP_W_2]; // String array for the input ap_fixed variable
			unsigned char _AP_F, _AP_F_2; // Decimal bits number
			int i;

			_AP_F =ap_w-ap_i;
			_AP_F_2 = _AP_W_2-_AP_I_2;;

			// Initialize the string array for the target ap_fixed variable
			for(i=0; i<ap_w; i++){	bits_array[i] = 0; }
			for(i=0; i<BYTE_SIZE(ap_w); i++){ din[i] = 0; }

			// convert input op to string array2
			for(i=0; i<_AP_W_2; i++){
				unsigned int byte_num;
				unsigned int shift_num;
				byte_num = i >> 3;
				shift_num = i - (byte_num<<3);
				bits_array2[i] = (op2.data[byte_num] >> shift_num) & 0x01;
			}


			if(ap_i < _AP_I_2){
				for(i=0; i<ap_i; i++){ bits_array[i+_AP_F] = bits_array2[i+_AP_F_2];}
			}else{
				for(i=0; i<_AP_I_2; i++){ bits_array[i+_AP_F] = bits_array2[i+_AP_F_2];}
				// Copy the sign bit to fill out the rest bits.
				for(i=0; i<ap_i-_AP_I_2; i++){ bits_array[_AP_I_2+_AP_F+i] = bits_array2[_AP_W_2-1]; }
			}

			if(_AP_F < _AP_F_2){
				for(i=0; i<_AP_F; i++){ bits_array[_AP_F-1-i] = bits_array2[_AP_F_2-1-i];}
			}else{
				for(i=0; i<_AP_F_2; i++){ bits_array[_AP_F-1-i] = bits_array2[_AP_F_2-1-i];}
			}

			for(i=0; i<ap_w; i++){
				unsigned int byte_num, bit_num;
				byte_num = i >> 3;
				bit_num = i - (byte_num<<3);
				if(bits_array[i]){
					din[byte_num] = set_bit(din[byte_num], bit_num);
				}else{
					din[byte_num] = clr_bit(din[byte_num], bit_num);
				}
			}

			// if ap_w is not the multiples of 8, set the residue value to the correct number
			if(ap_w < (BYTE_SIZE(ap_w)<<3)){
				unsigned int byte_num;
				unsigned int bit_num;
				for(i=ap_w; i<(BYTE_SIZE(ap_w)<<3); i++){
					byte_num = i >> 3;
					bit_num = i & 0x7;
					if(bits_array2[_AP_W_2-1]){
						din[byte_num] = set_bit(din[byte_num], bit_num);
					}else{
						din[byte_num] = clr_bit(din[byte_num], bit_num);
					}
				}

			}
		}

		// set one bit for a 32-bits integer number
		unsigned int set_bit(unsigned int din, unsigned char bit_num){
			return (din | (1<<bit_num));
		}

		// clear one bit for a byte number
		unsigned int clr_bit(unsigned int din, unsigned char bit_num){
			return (din & (~(1<<bit_num)));
		}

		// reverse the all bits of all the elements in the array
		void array_inv(unsigned char *din, unsigned char len){
			unsigned char i;
			for(i=0; i<len; i++){
				din[i] = ~din[i];
			}
		}

		// assume the array as value
		// eg. data[3], data[2], data[1], data[0]
		//    +                                1
		//---------------------------------------
		//     data[3], data[2], data[1], data[0]
		void array_add1(unsigned char *din, unsigned len){
			unsigned char i;
			unsigned char carry = 1;
			for(i=0; i<len; i++){
				din[i] = din[i] + carry;
				if(din[i] == 0x00){
					// If the carry bit is 1, continue to add.
					carry = 1;
				}else{
					// If the carry bit is 0, end up the addition early.
					carry = 0;
					return;
				}
			}
		}

		// assume the array as value
		// eg. data[3], data[2], data[1], data[0]
		//    -                                1
		//---------------------------------------
		//     data[3], data[2], data[1], data[0]
		void array_sub1(unsigned char *din, unsigned len){
			unsigned char i;
			unsigned char carry = 1;
			for(i=0; i<len; i++){
				din[i] = din[i] - carry;
				if(din[i] == 0xff){
					// If the carry bit is 1, continue to add.
					carry = 1;
				}else{
					// If the carry bit is 0, end up the subtraction early.
					carry = 0;
					return;
				}
			}
		}

		double div_2_power(unsigned char power){
			double out_tmp = 1;
			for(unsigned char i=0; i<power; i++){ out_tmp = out_tmp / 2; }
			return out_tmp;
		}

//#ifdef FLOAT_ENABLE
		double to_float(){
	    	unsigned char bits_array[_AP_W]; // String array for the floating point
	    	unsigned char tmp_data[BYTE_SIZE(_AP_W)]; // local data array to copy the real data
	    	unsigned char is_minus = 0; // Define the sign the of the target float number
	    	double i_part=0; // Define the integer part of the target float number
	    	double d_part=0; // Define the decimal part of the target float number
	    	int i=0;

	    	// Copy the data into local tmp data array
	    	for(i=0; i<BYTE_SIZE(_AP_W); i++){ tmp_data[i] = data[i]; }

	    	// Detect the sign number
	    	is_minus = (tmp_data[BYTE_SIZE(_AP_W)-1] >> (_AP_W-((BYTE_SIZE(_AP_W)-1)<<3)-1)) & 0x01;

	    	// If it is a minus number, convert the 2'complementary number back to original number
	    	if(is_minus){
	    		array_sub1(tmp_data, BYTE_SIZE(_AP_W));
	    		array_inv(tmp_data,  BYTE_SIZE(_AP_W));
	    	}

	    	// Convert data_tmp to string bit array
	    	for(i=0; i<_AP_W; i++){
	    		unsigned int byte_num, shift_num;
	    		byte_num = i >> 3;
	    		shift_num = i - (byte_num<<3);
	    		bits_array[i] = (tmp_data[byte_num] >> shift_num) & 0x01;
	    	}

	    	//calculate integer part
	    	for(i=_AP_W-_AP_I; i<_AP_W; i++){
	    		i_part += (1<<(i-_AP_W+_AP_I))*bits_array[i];
	    	}

	    	//calculate fraction part
	    	for(i=0; i<(_AP_W-_AP_I); i++){
	    		d_part += (double)bits_array[i]*(div_2_power((_AP_W-_AP_I)-i));
	    	}

	    	// reverse the bits if the sign flag is minus
	    	return is_minus == 1 ? (-i_part-d_part) : (i_part+d_part);
	    }
//#endif
		// slice the bit[b:a] out and return the sliced data
		unsigned int range(unsigned char b, unsigned char a){
			unsigned int out_tmp = 0;
			unsigned char byte_num;
			unsigned char bit_num;
			for(unsigned char i=0; i<(b-a+1); i++){
				byte_num = (a+i) >> 3;
				bit_num = (a+i) - (byte_num << 3);
				if((data[byte_num]>>bit_num) & 0x01){ out_tmp = set_bit(out_tmp, i); }
			}
			return out_tmp;
		}

		// Whenever need () operator, call out the Proxy struct
		Proxy operator() (unsigned char Hi, unsigned char Lo) {
			return {this, Hi, Lo};
		}

		// manually set bit[b:a] = rhs
		void set(int b, int a, unsigned long long rhs){
			unsigned char i;
			unsigned long long rhs_tmp = rhs;
			unsigned char byte_num;
			unsigned char bit_num;
			for(i=0; i<b-a+1; i++){
				byte_num = (a+i) >> 3;
				bit_num = (a+i) - (byte_num << 3);
				if(rhs_tmp & 1){
					data[byte_num] = set_bit(data[byte_num], bit_num);
				} else {
					data[byte_num] = clr_bit(data[byte_num], bit_num);
				}
				rhs_tmp =  rhs_tmp >> 1;
			}
		}

//#ifdef FLOAT_ENABLE
		//  enable arithmetic operator
		operator double() { return this->to_float(); }
//#endif

	    void cp_array(unsigned char *d_dest, unsigned char *d_src, unsigned char len){
	    	for(unsigned char i=0; i<len; i++){
	    		d_dest[i] = d_src[i];
	    	}
	    }


	    // convert an array to a long long
		unsigned long long array_to_data (unsigned char *din, unsigned char len){
			unsigned long long tmp_data = 0;
			unsigned char len_local;
			len_local = len > 8 ? 8 : len;

			for(unsigned char i=0; i<len_local; i++){
				tmp_data += (din[i] << (i<<3));
			}

			return tmp_data;
		}

		 // convert a long long to an array
		void data_to_array (unsigned char *dout, unsigned char len, unsigned long long din){
			unsigned long long tmp_data = din;
			unsigned char len_local;
			len_local = len > 8 ? 8 : len;

			for(unsigned char i=0; i<len_local; i++){
				dout[i] = tmp_data & 0xff;
				tmp_data = tmp_data >> 8;
			}
		}

		// shift the array to the left by 1 byte
		void array_lsh(unsigned char *din, unsigned len){
			for(int i=len-1; i>0; i--){
				din[i] = din[i-1];
			}
			din[0] = 0;
		}

		void clr_array(unsigned char *din, unsigned len){
			for(unsigned char i=0; i<len; i++){
				din[i] = 0;
			}
		}
#ifdef FLOAT_ENABLE
		double operator * (int op){
			double tmp;
			tmp = to_float();
			tmp = tmp * (double) op;
			return tmp;
		}
#endif

		// compare din1 and din2 number size.
		// if din1 > din2, return 1;
		// else            return 0;
		int greater_than(unsigned char *din1, unsigned char *din2, int len){
			for(int i=0; i<len; i++){
				if(din1[len-1-i] > din2[len-1-i]){
					return 1;
				}else if(din1[len-1-i] < din2[len-1-i]){
					return 0;
				}
			}
			return 0;
		}


		void array_sub(unsigned char *din1, unsigned char *din2, int len, char one_more){
			int carry = 0;
			int sub = 0;
			for(int i=0; i<len; i++){
				sub = din1[i] - din2[i] - carry;
				if(sub < 0){
					din1[i] = sub + 256;
					carry = 1;
				}else{
					din1[i] = sub;
					carry = 0;
				}
			}
			if(one_more == 1 && carry == 1){ din1[len]--; }

		}

		void array_lshin(unsigned char *din1, unsigned char din2, int len){
			for(int i=0; i<len-1; i++){
				din1[len-1-i] = din1[len-1-i-1];
			}
			din1[0] = din2;
		}

		void array_acc(unsigned char *din1, unsigned char *din2, int len){
			int carry = 0;
			int sum = 0;
			for(int i=0; i<len-1; i++){
				sum = din1[i] + din2[i] + carry;
				if(sum > 255){
					carry = 1;
					din1[i] = sum-256;
				}else{
					carry = 0;
					din1[i] = sum;
				}
			}
			if (carry == 1) { din1[len]++; }
		}


		ap_fixed<_AP_W, _AP_I> operator / (int op){
			ap_fixed<_AP_W, _AP_I> fix_out;			// final results array for multiplication
			unsigned char is_minus_out;
			int i;
			int carry;
			cp_array(fix_out.data, this->data, BYTE_SIZE(_AP_W));
			is_minus_out = (data[BYTE_SIZE(_AP_W)-1] >> (_AP_W-((BYTE_SIZE(_AP_W)-1)<<3)-1)) & 0x01;

			// if it is a minus number, convert it back to original number
			if(is_minus_out){
				array_sub1(fix_out.data, BYTE_SIZE(_AP_W));
				array_inv(fix_out.data,  BYTE_SIZE(_AP_W));
			}

			// Do the division byte by byte
			carry = 0;
			for(i=(BYTE_SIZE(_AP_W))-1; i>=0; i--){
				carry =  (carry<<8)+fix_out.data[i];
				fix_out.data[i] = carry / op;
				carry =  carry % op;
			}

			// if the residue is bigger than 8, then round up.
			// Otherwise, round down
			fix_out.data[0] = (carry>8)? fix_out.data[0]+1 : fix_out.data[0];

			// if is a minus number, convert it back to 2'complementary number
			if(is_minus_out){
				array_inv(fix_out.data,  BYTE_SIZE(_AP_W));
				array_add1(fix_out.data, BYTE_SIZE(_AP_W));
			}
			return fix_out;
		}



		ap_fixed<_AP_W, _AP_I> operator / (ap_fixed<_AP_W, _AP_I> op){
			// fix_out = *this / op2;
			// fix_out =   op1 / op2;
			ap_fixed<_AP_W<<1, _AP_I<<1> op1;
			ap_fixed<_AP_W, _AP_I> op2;
			ap_fixed<_AP_W, _AP_I> fix_out;
			unsigned char residue[BYTE_SIZE(_AP_W)+1];
			unsigned char sub_operand[BYTE_SIZE(_AP_W)+1];
			unsigned char quotient[BYTE_SIZE(_AP_W)+1];
			unsigned char is_minus_op1, is_minus_op2, is_minus_out, trial_q;
			int i, carry;

			FIXED2FIXED (op1.data, _AP_W<<1, _AP_I<<1, *this);

			FIXED2FIXED (op2.data, _AP_W, _AP_I, op);

			is_minus_op1 = (op1.data[BYTE_SIZE(_AP_W<<1)-1] >> ((_AP_W<<1)-((BYTE_SIZE(_AP_W<<1)-1)<<3)-1)) & 0x01;
			is_minus_op2 = (op2.data[BYTE_SIZE(_AP_W)-1] >> ((_AP_W)-((BYTE_SIZE(_AP_W)-1)<<3)-1)) & 0x01;
			is_minus_out = is_minus_op1 ^ is_minus_op2;


			// if op1 is a minus number, convert it back to original number
			if(is_minus_op1){
				array_sub1(op1.data, BYTE_SIZE(_AP_W<<1));
				array_inv(op1.data,  BYTE_SIZE(_AP_W<<1));
			}


			// if op2 is a minus number, convert it back to original number
			if(is_minus_op2){
				array_sub1(op2.data, BYTE_SIZE(_AP_W));
				array_inv(op2.data,  BYTE_SIZE(_AP_W));
			}

			//this->print_array(op1.data, BYTE_SIZE(_AP_W<<1));
			//this->print_array(op2.data, BYTE_SIZE(_AP_W));

			for(i=0; i<BYTE_SIZE(_AP_W); i++){
				residue[BYTE_SIZE(_AP_W)-1-i] = op1.data[BYTE_SIZE(_AP_W<<1)-1-i];
				quotient[i] = 0;
			}
			residue[BYTE_SIZE(_AP_W)] = 0;
			quotient[BYTE_SIZE(_AP_W)] = 0;

			for(i=0; i<BYTE_SIZE(_AP_W)+1; i++){
				// clear sub_operand arrays
				for(int j=0; j<BYTE_SIZE(_AP_W)+1; j++){ sub_operand[j] = 0; }
				//try to find the quotient for hex digit
				for(trial_q=0; trial_q<256; trial_q++){
					//printf("i=%d, trial_q=%d\n", i, trial_q);
					//printf("    residue=");
					//this->print_array(residue, BYTE_SIZE(_AP_W)+1);
					//printf("sub_operand=");
					//this->print_array(sub_operand, BYTE_SIZE(_AP_W)+1);

					if(greater_than(sub_operand, residue, BYTE_SIZE(_AP_W)+1)){
						// if sub_operand >= residue;
						array_sub(sub_operand, op2.data, BYTE_SIZE(_AP_W), 1);
						//printf("0sub_operand=");
						//this->print_array(sub_operand, BYTE_SIZE(_AP_W)+1);
						array_sub(residue, sub_operand, BYTE_SIZE(_AP_W)+1, 0);
						//printf("1residue=");
						//this->print_array(residue, BYTE_SIZE(_AP_W)+1);
						if(i<BYTE_SIZE(_AP_W)) array_lshin(residue, op1.data[BYTE_SIZE(_AP_W)-1-i], BYTE_SIZE(_AP_W)+1);
						//printf("2residue=");
						//this->print_array(residue, BYTE_SIZE(_AP_W)+1);
						break;
					}else{
						// if sub_operand < residue;
						array_acc(sub_operand, op2.data, BYTE_SIZE(_AP_W)+1);
					}
				}
				quotient[BYTE_SIZE(_AP_W)-i] = trial_q-1;
				//printf("============================quotient=");
				//this->print_array(quotient, BYTE_SIZE(_AP_W)+1);
			}

			for(i=0; i<BYTE_SIZE(_AP_W); i++){
				fix_out.data[i] = quotient[i];
			}
			if(is_minus_out == 1){
				array_inv(fix_out.data,  BYTE_SIZE((_AP_W)));
				array_add1(fix_out.data, BYTE_SIZE((_AP_W)));
			}

			return fix_out;

		}






		ap_fixed<(_AP_W<<1), (_AP_I<<1)> operator *(ap_fixed<_AP_W, _AP_I> op){
			ap_fixed<(_AP_W<<1), (_AP_I<<1)> fix_out;			// final results array for multiplication
			ap_fixed<(_AP_W<<1), (_AP_I<<1)> op_shift;			// shift array intermediate multiplication
			ap_fixed<(_AP_W<<1), (_AP_I<<1)> op_mul;			// results for intermediate multiplication

			unsigned char is_minus_a, is_minus_b, is_minus_out; // extract the sign for op1, op2 and output
			unsigned i,j;

			// Extract the op1 and op2's sign
			is_minus_a = (data[BYTE_SIZE(_AP_W)-1] >> (_AP_W-((BYTE_SIZE(_AP_W)-1)<<3)-1)) & 0x01;
			is_minus_b = (op.data[BYTE_SIZE(_AP_W)-1] >> (_AP_W-((BYTE_SIZE(_AP_W)-1)<<3)-1)) & 0x01;
			is_minus_out = is_minus_a ^ is_minus_b;

			// convert op1 to original number, if it is minus
	    	if(is_minus_a){ array_sub1(data, BYTE_SIZE(_AP_W)); array_inv(data,  BYTE_SIZE(_AP_W)); }

	    	// convert op2 to original number, if it is minus
	    	if(is_minus_b){ array_sub1(op.data, BYTE_SIZE(_AP_W)); array_inv(op.data,  BYTE_SIZE(_AP_W)); }

	    	// copy the op1 to another array for multiplication
	    	cp_array(op_shift.data, this->data, BYTE_SIZE(_AP_W));

	    	// The main loop for multiplication
			for(i=0; i<BYTE_SIZE(_AP_W); i++){
				unsigned char mul1 = op.data[i];
				unsigned int carry = 0;
				for(j=0; j<BYTE_SIZE((_AP_W<<1)); j++){
					carry = op_shift.data[j] * mul1 + carry;
					op_mul.data[j] = carry & 0xff;
					carry = carry >> 8;
				}
				fix_out = fix_out + op_mul;
				array_lsh(op_shift.data, BYTE_SIZE((_AP_W<<1)));
			}

			// Convert it back to 2'complementary number if it is minus
			if(is_minus_out){
				array_inv(fix_out.data,  BYTE_SIZE((_AP_W<<1)));
				array_add1(fix_out.data, BYTE_SIZE((_AP_W<<1)));
			}

			// Convert it back to 2'complementary number if it is minus
	    	if(is_minus_a){
	    		array_inv(data,  BYTE_SIZE(_AP_W));
	    		array_add1(data, BYTE_SIZE(_AP_W));
	    	}

	    	// Convert it back to 2'complementary number if it is minus
	    	if(is_minus_b){
	    		array_inv(op.data,  BYTE_SIZE(_AP_W));
	    		array_add1(op.data, BYTE_SIZE(_AP_W));
	    	}

			return fix_out;
		}

		ap_fixed<_AP_W, _AP_I> operator +(ap_fixed<_AP_W, _AP_I> op){
			ap_fixed<_AP_W, _AP_I> fix_out;
			unsigned char i;
			unsigned int carry = 0;

			// main loop for addition
			// The basic unit is byte
			for(i=0; i<BYTE_SIZE(_AP_W); i++){
				carry = this->data[i] + op.data[i] + carry;
				fix_out.data[i] = carry & 0xff;
				carry = carry >> 8;
			}

			return fix_out;
		}



#ifdef FLOAT_ENABLE
		double operator +(double op){
			double tmp;
			tmp = to_float();
			tmp = tmp + op;
			return tmp;
		}
#endif
		



		ap_fixed<_AP_W, _AP_I> operator -(ap_fixed<_AP_W, _AP_I> op){
			ap_fixed<_AP_W, _AP_I> fix_out;
			unsigned char i;
			unsigned int carry = 0;

			// convert op to 2'complementary number, so that we only need to do addition
			array_inv(op.data,  BYTE_SIZE(_AP_W));
			array_add1(op.data, BYTE_SIZE(_AP_W));

			// main loop for addition
			// The basic unit is byte
			for(i=0; i<BYTE_SIZE(_AP_W); i++){
				carry = this->data[i] + op.data[i] + carry;
				fix_out.data[i] = carry & 0xff;
				carry = carry >> 8;
			}
			return fix_out;
		}

		ap_fixed<_AP_W, _AP_I> operator -(){
			ap_fixed<_AP_W, _AP_I> fix_out;
			cp_array(fix_out.data, this->data, BYTE_SIZE(_AP_W));
			array_inv(fix_out.data,  BYTE_SIZE(_AP_W));
			array_add1(fix_out.data, BYTE_SIZE(_AP_W));
			return fix_out;
		}


		ap_fixed<_AP_W, _AP_I> operator <<(unsigned int op){
			ap_fixed<_AP_W, _AP_I> fix_out;
			unsigned char i;
			unsigned char shift_bytes = op >> 3;
			unsigned char shift_bits = op - ((op >> 3) << 3);

			// copy the local array to fix_out.data
			cp_array(fix_out.data, this->data, BYTE_SIZE(_AP_W));

			// right shift the array by the unit of bytes
			for(i=0; i<BYTE_SIZE(_AP_W); i++){
				if(i<((BYTE_SIZE(_AP_W))-shift_bytes)){
					fix_out.data[(BYTE_SIZE(_AP_W))-1-i] = fix_out.data[(BYTE_SIZE(_AP_W))-1-i-shift_bytes];
				}else{
					fix_out.data[(BYTE_SIZE(_AP_W))-1-i] = 0;
				}
			}

			// right shift the array by the unit of bits
			for(i=0; i<((BYTE_SIZE(_AP_W))-shift_bytes); i++){
				fix_out.data[(BYTE_SIZE(_AP_W))-1-i] = (fix_out.data[(BYTE_SIZE(_AP_W))-1-i] << shift_bits) | (fix_out.data[(BYTE_SIZE(_AP_W))-1-i-1] >> (8-shift_bits));
			}
			return fix_out;
		}


#ifdef DEBUG
	    void print_raw() {
			for(int i=0; i<BYTE_SIZE(_AP_W); i++){
				printf("%02x", data[BYTE_SIZE(_AP_W)-i-1]);
			}
			printf("\n");
	    }

	    void print_array(unsigned char *din, int len) {
			for(int i=0; i<len; i++){
				printf("%02x", din[len-1-i]);
			}
			printf("\n");
		}
#endif

};

#endif


