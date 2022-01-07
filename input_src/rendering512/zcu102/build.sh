#!/bin/bash

source /opt/Xilinx/Vitis/2021.1/settings64.sh
export PLATFORM_REPO_PATHS=/opt/xilinx/platforms/xilinx_zcu102_base_dfx_202110_1
export ROOTFS=/opt/xilinx/platforms/xilinx_zcu102_base_dfx_202110_1/sw/xilinx_zcu102_base_dfx_202110_1/xrt/filesystem


source /opt/xilinx/xrt/setup.sh
unset LD_LIBRARY_PATH

source /opt/xilinx-zynqmp-common-v2021.1/ir/environment-setup-cortexa72-cortexa53-xilinx-linux

# Make sure everything is up to date
make app.exe 
