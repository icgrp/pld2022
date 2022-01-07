// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

// A simple Sieve of Eratosthenes

#include "firmware.h"

#define STREAMOUT1  0x10000008
#define STREAMOUT2  0x10000010
#define STREAMOUT3  0x10000018
#define STREAMOUT4  0x10000020
#define STREAMOUT5  0x10000028
#define STREAMIN1   0x10000004
#define STREAMIN2   0x1000000c
#define STREAMIN3   0x10000014
#define STREAMIN4   0x1000001c
#define STREAMIN5   0x10000024

int main(void)
{
  char const *s = "Hello world!\n";
  print_str(s);
  int i = 0;
  //stream operator instance;
  return 0;

}  
