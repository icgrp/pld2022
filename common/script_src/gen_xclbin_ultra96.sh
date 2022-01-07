#!/bin/bash -e
# source /opt/Xilinx/Vivado/2018.2/Settings64.sh 
bitstream=$1
xmlfile=$2
xclbin=$3

xclbinutil --add-section DEBUG_IP_LAYOUT:JSON:../F001_overlay/ydma/ultra96/_x/link/int/debug_ip_layout.rtd \
           --add-section BITSTREAM:RAW:${bitstream} \
           --force --target hw --key-value SYS:dfx_enable:true \
           --add-section :JSON:../F001_overlay/ydma/ultra96/_x/link/int/ydma.rtd \
           --add-section CLOCK_FREQ_TOPOLOGY:JSON:../F001_overlay/ydma/ultra96/_x/link/int/ydma_xml.rtd \
           --add-section BUILD_METADATA:JSON:../F001_overlay/ydma/ultra96/_x/link/int/ydma_build.rtd \
           --add-section EMBEDDED_METADATA:RAW:${xmlfile} \
           --add-section SYSTEM_METADATA:RAW:../F001_overlay/ydma/ultra96/_x/link/int/systemDiagramModelSlrBaseAddress.json \
           --key-value SYS:PlatformVBNV:xilinx_ultra96_dynamic_0_0 \
           --output ./${xclbin}

