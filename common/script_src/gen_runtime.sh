#!/bin/bash -e
Xilinx_dir
xrt_dir
g++ -Wall -g -std=c++11 host.cpp  -o app.exe -I${XILINX_XRT}/include/ -I${XILINX_VIVADO}/include/ -L${XILINX_XRT}/lib/ -lOpenCL -lpthread -lrt -lstdc++
