#!/bin/bash

# Exit when any command fails
set -e
source /opt/Xilinx/Vitis/2021.1/settings64.sh
source /opt/xilinx/xrt/setup.sh
export PLATFORM_REPO_PATHS=/opt/xilinx/platforms/xilinx_u50_gen3x16_xdma_201920_3
# Make sure everything is up to date
make all 

