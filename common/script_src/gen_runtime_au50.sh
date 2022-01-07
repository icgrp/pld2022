#!/bin/bash -e
source Xilinx_dir
source xrt_dir
g++ -Wall -g -std=c++11 host.cpp  -o ../../app.exe -I${XILINX_XRT}/include/ -I${XILINX_VIVADO}/include/ -L${XILINX_XRT}/lib/ -lOpenCL -lpthread -lrt -lstdc++
cp ../../app.exe ../../sd_card
cp ../../sd_card/dynamic_region.xclbin ../../
