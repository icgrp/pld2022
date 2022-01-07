#!/bin/bash

Xilinx_dir
xrt_dir
export PLATFORM_REPO_PATHS=
export kl_name=ydma
export MaxJobNum=$(nproc)
export PLATFORM=

# Make sure everything is up to date
make all
