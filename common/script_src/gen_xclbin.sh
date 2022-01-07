#!/bin/bash -e
source /opt/Xilinx/Vivado/2018.2/Settings64.sh 
bitstream=$1
xmlfile=$2
xclbin=$3

xclbinutil --add-section DEBUG_IP_LAYOUT:JSON:/home/ylxiao/ws_202/rosetta_vitis/ydma/hw/_x/link/int/debug_ip_layout.rtd \
--add-section BITSTREAM:RAW:${bitstream} \
--force --target hw --key-value SYS:dfx_enable:true \
--add-section :JSON:/home/ylxiao/ws_202/rosetta_vitis/ydma/hw/_x/link/int/ydma.rtd \
--append-section :JSON:/home/ylxiao/ws_202/rosetta_vitis/ydma/hw/_x/link/int/appendSection.rtd \
--add-section CLOCK_FREQ_TOPOLOGY:JSON:/home/ylxiao/ws_202/rosetta_vitis/ydma/hw/_x/link/int/ydma_xml.rtd \
--add-section BUILD_METADATA:JSON:/home/ylxiao/ws_202/rosetta_vitis/ydma/hw/_x/link/int/ydma_build.rtd \
--add-section EMBEDDED_METADATA:RAW:${xmlfile} \
--add-section SYSTEM_METADATA:RAW:/home/ylxiao/ws_202/rosetta_vitis/ydma/hw/_x/link/int/systemDiagramModelSlrBaseAddress.json \
--key-value SYS:PlatformVBNV:xilinx_u50_gen3x16_xdma_201920_3 \
--output ${xclbin} 



xclbinutil --add-section DEBUG_IP_LAYOUT:JSON:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/debug_ip_layout.rtd 
--add-section BITSTREAM:RAW:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/partial.bit 
--force --target hw --key-value SYS:dfx_enable:true --add-section :JSON:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/ydma.rtd 
--add-section CLOCK_FREQ_TOPOLOGY:JSON:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/ydma_xml.rtd 
--add-section BUILD_METADATA:JSON:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/ydma_build.rtd 
--add-section EMBEDDED_METADATA:RAW:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/ydma.xml 
--add-section SYSTEM_METADATA:RAW:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/systemDiagramModelSlrBaseAddress.json 
--key-value SYS:PlatformVBNV: 
--output /home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/ydma.xclbin
