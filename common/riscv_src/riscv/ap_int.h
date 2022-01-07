/*
* Company: IC group, University of Pennsylvania
* Engineer: Yuanlong Xiao
*
* Create Date: 02/01/2021
* Design Name: ap_uint
* Project Name:
* Versions: 1.0
* Description:
*   This is a manual implementation of ap_uint to replace ap_uinit.h from Xilinx
*
* Dependencies:
*
* Revision:
* Revision 0.01 - File Created
* Revision 0.02 - add overloading ^. Fix this bug for digit recognition
* Revision 0.03 - add #define BYTE_SIZE(X) to define the minimum bytes number
* Revision 0.04 - remove some warnings. The subscript of an array should be 'int' not 'char' 
*                 This helps to remove some deadlock bugs
* Revision 0.05 - define constructor to make sure ap_uint<T1> = ap_unit<T2> can be compatible
*
* Additional Comments:
* TODO: add subscript read function for ap_int. Digit Recognition cnt = cnt + x(i,i); => cnt = cnt + x[i];
*/


#ifndef __AP_UINT_H__
#define __AP_UINT_H__

#include "stdio.h"
#define BYTE_SIZE(X)  ((X>>3)+((X&0x7) ? 1 : 0))

template <int T=32>
class ap_uint{

	// With the proxy struct, the bitwise operations can be overloaded.
	// ap_uint<32> tmp;
	// tmp(7,0) = 0;
	struct Proxy{
		ap_uint<T>* parent = nullptr;
		int hi, lo;

		// When ap_unit is rhs
		Proxy& operator =(unsigned u) {parent->set(hi, lo, u); return *this;}

		Proxy& operator =(Proxy u) {parent->set(hi, lo, u); return *this;}


		// When ap_unit is lhs
		operator unsigned int () {return parent->range(hi, lo);}
	};

	public:
		// Define the local variable to store the value
		// Currently, the bitwidth only support multiples of 8 bits.
		unsigned char data[BYTE_SIZE(T)];

		// constructor
		ap_uint<T>(unsigned int u) {
			unsigned int tmp;
			tmp = u;
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				data[i] = tmp & 0xff;
				tmp = tmp >> 8;
			}
		}

		// constructor
                template <int T1=32>
		ap_uint<T>(ap_uint<T1> u) {
                    	unsigned int tmp;
                        tmp = u.to_int();
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				data[i] = tmp & 0xff;
				tmp = tmp >> 8;
			}
		}


		// constructor
		ap_uint<T>(){
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				data[i] = 0;
			}
		}


		// set the bit to 1 according to bit number
		unsigned int set_bit(unsigned int din, unsigned char bit_num){
			return (din | (1<<bit_num));
		}

		// clear the bit to 0 according to bit number
		unsigned int clr_bit(unsigned int din, unsigned char bit_num){
			return (din & (~(1<<bit_num)));
		}

		// slice the bit[b:a] out and return the sliced data
		unsigned int range(unsigned int b, unsigned int a){
			unsigned int out_tmp = 0;
			unsigned int byte_num;
			unsigned int bit_num;
			for(unsigned char i=0; i<(b-a+1); i++){
				byte_num = (a+i) >> 3;
				bit_num = (a+i) - (byte_num << 3);
				if((data[byte_num]>>bit_num) & 0x01){ out_tmp = set_bit(out_tmp, i); }
			}
			return out_tmp;
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

		// Whenever need () operator, call out the Proxy struct
		Proxy operator() (int Hi, int Lo) {
			return {this, Hi, Lo};
		}

		//Proxy operator = (Proxy op2){
		//	this->data = op2;
		//}


		// enable arithmetic operator
		operator unsigned int() {
			unsigned int tmp;
			tmp = to_int();
			return tmp;
		}

		unsigned int to_int(){
			unsigned int tmp;
			tmp = 0;

			for(int i=BYTE_SIZE(T)-1; i>=0; i--){
				tmp = tmp << 8;
				tmp += data[i];
			}
			return tmp;
		}

		void operator ++(int op){
			unsigned int tmp;
			tmp = 0;
			tmp = to_int();
			tmp = tmp + 1;
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				data[i] = tmp & 0xff;
				tmp = tmp >> 8;
			}
		}

		// overload the logic function of xor
		ap_uint<T>  operator ^ (ap_uint<T> op){
			ap_uint<T> out;
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				out.data[i] = data[i] ^ op.data[i];
			}
			return out;
		}


		void print_raw(){
			//printf("\n\n\n\nT1 = %d\n", (T>>3)+((T&0x7) ? 1 : 0));
			//printf("T2 = %d\n", (T>>3)-1);
			for(char i=BYTE_SIZE(T)-1; i>=0; i--){
				printf("%02x", data[i]);
			}
			printf("\n");
		}


};

template <int T=32>
class ap_int{

	// With the proxy struct, the bitwise operations can be overloaded.
	// ap_int<32> tmp;
	// tmp(7,0) = 0;
	struct Proxy{
		ap_int<T>* parent = nullptr;
		int hi, lo;

		// When ap_unit is rhs
		Proxy& operator =(unsigned u) {parent->set(hi, lo, u); return *this;}

		Proxy& operator =(Proxy u) {parent->set(hi, lo, u); return *this;}


		// When ap_unit is lhs
		operator unsigned int () {return parent->range(hi, lo);}
	};

	public:
		// Define the local variable to store the value
		// Currently, the bitwidth only support multiples of 8 bits.
		unsigned char data[BYTE_SIZE(T)];

		// constructor
		ap_int<T>(int u) {
			int tmp;
			tmp = u;
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				data[i] = tmp & 0xff;
				tmp = tmp >> 8;
			}
		}

		// constructor
        template <int T1=32>
		ap_int<T>(ap_int<T1> u) {
            unsigned int tmp;
            tmp = u.to_int();
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				data[i] = tmp & 0xff;
				tmp = tmp >> 8;
			}
		}


		// constructor
		ap_int<T>(){
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				data[i] = 0;
			}
		}


		// set the bit to 1 according to bit number
		unsigned int set_bit(unsigned int din, unsigned int bit_num){
			return (din | (1<<bit_num));
		}

		// clear the bit to 0 according to bit number
		unsigned int clr_bit(unsigned int din, unsigned int bit_num){
			return (din & (~(1<<bit_num)));
		}

		// slice the bit[b:a] out and return the sliced data
		unsigned int range(unsigned int b, unsigned int a){
			unsigned int out_tmp = 0;
			unsigned int byte_num;
			unsigned int bit_num;
			for(unsigned char i=0; i<(b-a+1); i++){
				byte_num = (a+i) >> 3;
				bit_num = (a+i) - (byte_num << 3);
				if((data[byte_num]>>bit_num) & 0x01){ out_tmp = set_bit(out_tmp, i); }
			}
			return out_tmp;
		}



		// manually set bit[b:a] = rhs
		void set(int b, int a, unsigned long long rhs){
			unsigned int i;
			unsigned long long rhs_tmp = rhs;
			unsigned int byte_num;
			unsigned int bit_num;
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

		// Whenever need () operator, call out the Proxy struct
		Proxy operator() (int Hi, int Lo) {
			return {this, Hi, Lo};
		}

		//Proxy operator = (Proxy op2){
		//	this->data = op2;
		//}


		// enable arithmetic operator
		operator int() {
			unsigned int tmp;
			tmp = to_int();
			return tmp;
		}


		int to_int(){
			int tmp;
			int i;
			unsigned int mask = 1;
			tmp = 0;
			unsigned int byte_index, bit_index;
			byte_index = BYTE_SIZE(T)-1;

			bit_index = T - (byte_index<<3)-1;
			unsigned int is_minus;


			is_minus = (data[BYTE_SIZE(T)-1] >> (T - (byte_index<<3)-1)) & 0x01;

			for(i=BYTE_SIZE(T)-1; i>=0; i--){
				tmp = tmp << 8;
				tmp += data[i];
			}

			for(i=1; i<T; i++){ mask = (mask << 1) + 1; }

			if(is_minus == 1){
				tmp -= 1;
				tmp = ~tmp;
				tmp = tmp & mask;
				tmp = -tmp;
			}else{
				tmp = tmp & mask;
			}


			//printf("==================%llx\n", tmp);
			return tmp;
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


		void operator ++(int op){
			unsigned int tmp;
			tmp = 0;
			tmp = to_int();
			tmp = tmp + 1;
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				data[i] = tmp & 0xff;
				tmp = tmp >> 8;
			}
		}


		// overload the logic function of xor
		ap_int<T>  operator ^ (ap_int<T> op){
			ap_int<T> out;
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				out.data[i] = data[i] ^ op.data[i];
			}
			return out;
		}

		// overload the logic function of xor
		ap_int<T>  operator & (ap_int<T> op){
			ap_int<T> out;
			for(unsigned int i=0; i<BYTE_SIZE(T); i++){
				out.data[i] = data[i] & op.data[i];
			}
			return out;
		}


		ap_int<T>  operator + (ap_int<T> op){
			ap_int<T> out;
			unsigned char i;
			unsigned int carry = 0;

			// main loop for addition
			// The basic unit is byte
			for(i=0; i<BYTE_SIZE(T); i++){
				carry = this->data[i] + op.data[i] + carry;
				out.data[i] = carry & 0xff;
				carry = carry >> 8;
			}

			return out;
		}

		ap_int<T>  operator - (ap_int<T> op){
			ap_int<T> out;
			unsigned char i;
			unsigned int carry = 0;

			// convert op to 2'complementary number, so that we only need to do addition
			array_inv(op.data,  BYTE_SIZE(T));
			array_add1(op.data, BYTE_SIZE(T));

			// main loop for addition
			// The basic unit is byte
			for(i=0; i<BYTE_SIZE(T); i++){
				carry = this->data[i] + op.data[i] + carry;
				out.data[i] = carry & 0xff;
				carry = carry >> 8;
			}
			return out;
		}




	    void cp_array(unsigned char *d_dest, unsigned char *d_src, unsigned char len){
	    	for(unsigned char i=0; i<len; i++){
	    		d_dest[i] = d_src[i];
	    	}
	    }

		ap_int<T>  operator << (int op){
			ap_int<T> out;
			unsigned char i;
			unsigned char shift_bytes = op >> 3;
			unsigned char shift_bits = op - ((op >> 3) << 3);

			// copy the local array to fix_out.data
			cp_array(out.data, this->data, BYTE_SIZE(T));

			// right shift the array by the unit of bytes
			for(i=0; i<BYTE_SIZE(T); i++){
				if(i<((BYTE_SIZE(T))-shift_bytes)){
					out.data[(BYTE_SIZE(T))-1-i] = out.data[(BYTE_SIZE(T))-1-i-shift_bytes];
				}else{
					out.data[(BYTE_SIZE(T))-1-i] = 0;
				}
			}

			// right shift the array by the unit of bits
			for(i=0; i<((BYTE_SIZE(T))-shift_bytes); i++){
				out.data[(BYTE_SIZE(T))-1-i] = (out.data[(BYTE_SIZE(T))-1-i] << shift_bits) | (out.data[(BYTE_SIZE(T))-1-i-1] >> (8-shift_bits));
			}
			return out;
		}

		ap_int<T>  operator >> (int op){
			ap_int<T> out;
			unsigned char i;
			unsigned char shift_bytes = op >> 3;
			unsigned char shift_bits = op - ((op >> 3) << 3);

			// copy the local array to fix_out.data
			cp_array(out.data, this->data, BYTE_SIZE(T));

			// right shift the array by the unit of bytes
			for(i=0; i<BYTE_SIZE(T); i++){
				if(i<((BYTE_SIZE(T))-shift_bytes)){
					out.data[i] = out.data[i+shift_bytes];
				}else{
					out.data[i] = 0;
				}
			}

			// right shift the array by the unit of bits
			for(i=0; i<((BYTE_SIZE(T))-shift_bytes); i++){
				out.data[i] = (out.data[i] >> shift_bits) | (out.data[i+1] << (8-shift_bits));
			}
			return out;
		}

		void print_raw(){
			//printf("\n\n\n\nT1 = %d\n", (T>>3)+((T&0x7) ? 1 : 0));
			//printf("T2 = %d\n", (T>>3)-1);
			for(char i=BYTE_SIZE(T)-1; i>=0; i--){
				printf("%02x", data[i]);
			}
			printf("\n");
		}


};


#endif

