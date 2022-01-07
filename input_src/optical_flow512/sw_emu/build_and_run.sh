#!/bin/bash
source /opt/Xilinx/Vitis/2021.1/settings64.sh
source /opt/xilinx/xrt/setup.sh
# Exit when any command fails
set -e

# Make sure everything is up to date
make all 

# Run the application in HW emulation mode
XCL_EMULATION_MODE=sw_emu ./app.exe  ydma.xclbin

