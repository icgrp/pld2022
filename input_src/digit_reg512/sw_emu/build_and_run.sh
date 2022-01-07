#!/bin/bash

# Exit when any command fails
set -e
source /opt/Xilinx/Vitis/2021.1/settings64.sh
source /opt/xilinx/xrt/setup.sh

# Make sure everything is up to date
make all 

date
# Run the application in HW emulation mode
XCL_EMULATION_MODE=sw_emu ./app.exe ydma.xclbin 
date

