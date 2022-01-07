#!/bin/bash -e
source /opt/Xilinx/Vivado/2021.1/settings64.sh # Xilinx_dir
export PLATFORM_REPO_PATHS=/home/ylxiao/ws_211/Vitis_Embedded_Platform_Source/Xilinx_Official_Platforms/xilinx_zcu102_base_dfx/platform_repo/xilinx_zcu102_base_dfx_202110_1/export/xilinx_zcu102_base_dfx_202110_1/
export ROOTFS=/home/ylxiao/ws_211/Vitis_Embedded_Platform_Source/Xilinx_Official_Platforms/xilinx_zcu102_base_dfx/sw/petalinux/images/linux/
export MaxJobNum=$(nproc)
#export MaxJobNum=10

source /opt/xilinx/xrt/setup.sh # xrt_dir
unset LD_LIBRARY_PATH

source /opt/xilinx/platforms/xilinx-zynqmp-common-v2021.1/ir/environment-setup-cortexa72-cortexa53-xilinx-linux # sdk_dir

${CXX} -Wall -g -std=c++11 host.cpp -o ./sd_card/app.exe \
		-I/usr/include/xrt \
		-I${XILINX_VIVADO}/include \
		-lOpenCL \
		-lpthread \
		-lrt \
		-lstdc++


