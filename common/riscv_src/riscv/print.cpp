// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "firmware.h"

#define OUTPORT     0x10000000

//#define INPORT  0x10000

void print_chr(char ch)
{
	*((volatile uint32_t*)OUTPORT) = ch;
}

void print_str(const char *p)
{
	while (*p != 0)
		*((volatile uint32_t*)OUTPORT) = *(p++);
}


void print_dec(unsigned int val)
{
	char buffer[10];
	char *p = buffer;
	while (val || p == buffer) {
		*(p++) = val % 10;
		val = val / 10;
	}
	while (p != buffer) {
		*((volatile uint32_t*)OUTPORT) = '0' + *(--p);
	}
}


void print_float(float din)
{
        unsigned int val;
        val = (unsigned int) (din * 100);
 
	char buffer[10];
	char *p = buffer;
        int len = 0;
	while (val || p == buffer) {
                len++;
		*(p++) = val % 10;
		val = val / 10;
	}
	while (p != buffer) {
                if(len==2)  *((volatile uint32_t*)OUTPORT) = '.';
		*((volatile uint32_t*)OUTPORT) = '0' + *(--p);
                len--;
	}
}

void print_hex(unsigned int val, int digits)
{
	for (int i = (4*digits)-4; i >= 0; i -= 4)
		*((volatile uint32_t*)OUTPORT) = "0123456789ABCDEF"[(val >> i) % 16];
}



