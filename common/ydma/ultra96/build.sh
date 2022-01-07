#!/bin/bash
cd ../../
root_dir=$(pwd)
cd -


export PLATFORM_REPO_PATHS=
export ROOTFS=
export kl_name=ydma
export MaxJobNum=$(nproc)
export PLATFORM=
#export MaxJobNum=10

Xilinx_dir
unset LD_LIBRARY_PATH

sdk_dir

# Make sure everything is up to date
# make app.exe
# make clean
make all
# make $1 
# make ${kl_name}.xo



# Exit when any command fails
#set -e
#if [[ -z "$ROOTFS" ]]; then
#   echo "Error: make sure to set the ROOTFS environment variable"
#   exit
#fi
#if [[ -z "$SYSROOT" ]]; then
#   echo "Error: make sure to set the SYSROOT environment variable"
#   exit
#fi
#if [[ -z "$PLATFORM_REPO_PATHS" ]]; then
#   echo "Error: make sure to set the PLATFORM_REPO_PATHS environment variable"
#   exit
#fi


