// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#ifndef FIRMWARE_H
#define FIRMWARE_H

#include <stdint.h>
#include <stdbool.h>
#include "typedefs.h"

// irq.c
uint32_t *irq(uint32_t *regs, uint32_t irqs);

// print.c
void print_chr(char ch);
void print_str(const char *p);
void print_dec(unsigned int val);
void print_hex(unsigned int val, int digits);
void print_float(float din);
uint32_t  read_word1(void);
void write_word1(uint32_t out_value);
uint32_t  read_word2(void);
void write_word2(uint32_t out_value);
uint32_t  read_word3(void);
void write_word3(uint32_t out_value);
uint32_t  read_word4(void);
void write_word4(uint32_t out_value);


// stream.c
void stream(void);

// stats.c
void stats(void);

// operator
#endif
