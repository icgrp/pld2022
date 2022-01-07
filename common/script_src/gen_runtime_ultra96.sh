#!/bin/bash -e
Xilinx_dir
export PLATFORM_REPO_PATHS=
export ROOTFS=
export MaxJobNum=$(nproc)
#export MaxJobNum=10

unset LD_LIBRARY_PATH

sdk_dir

${CXX} -Wall -g -std=c++11 host.cpp -o ./sd_card/app.exe \
		-I/usr/include/xrt \
		-I${XILINX_VIVADO}/include \
		-lOpenCL \
		-lpthread \
		-lrt \
		-lstdc++


