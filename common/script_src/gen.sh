#!/bin/bash -e
# source /opt/Xilinx/Vivado/2018.2/Settings64.sh 
bitstream=$1
xmlfile=$2
xclbin=$3


xclbinutil --add-section DEBUG_IP_LAYOUT:JSON:../F001_overlay/ydma/au50/_x/link/int/debug_ip_layout.rtd \
           --add-section BITSTREAM:RAW:${bitstream} \
           --force --target hw --key-value SYS:dfx_enable:true \
           --add-section :JSON:../F001_overlay/ydma/au50/_x/link/int/ydma.rtd \
           --append-section :JSON:../F001_overlay/ydma/au50/_x/link/int/appendSection.rtd \
           --add-section EMBEDDED_METADATA:RAW:${xmlfile} \
           --add-section CLOCK_FREQ_TOPOLOGY:JSON:../F001_overlay/ydma/au50/_x/link/int/ydma_xml.rtd \
           --add-section BUILD_METADATA:JSON:../F001_overlay/ydma/au50/_x/link/int/ydma_build.rtd \
           --add-section SYSTEM_METADATA:RAW:../F001_overlay/ydma/au50/_x/link/int/systemDiagramModelSlrBaseAddress.json \
           --key-value SYS:PlatformVBNV:xilinx_u50_gen3x16_xdma_201920_3 \
           --output ./${xclbin}
