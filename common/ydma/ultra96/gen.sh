
xclbinutil --add-section DEBUG_IP_LAYOUT:JSON:/home/ylxiao/ws_211/rosetta_vitis/ydma/hw/_x/link/int/debug_ip_layout.rtd \
           --add-section BITSTREAM:RAW:$1\
           --force --target hw --key-value SYS:dfx_enable:true \
           --add-section :JSON:/home/ylxiao/ws_211/rosetta_vitis/ydma/hw/_x/link/int/ydma.rtd \
           --append-section :JSON:/home/ylxiao/ws_211/rosetta_vitis/ydma/hw/_x/link/int/appendSection.rtd \
           --add-section CLOCK_FREQ_TOPOLOGY:JSON:/home/ylxiao/ws_211/rosetta_vitis/ydma/hw/_x/link/int/ydma_xml.rtd \
           --add-section BUILD_METADATA:JSON:/home/ylxiao/ws_211/rosetta_vitis/ydma/hw/_x/link/int/ydma_build.rtd \
           --add-section EMBEDDED_METADATA:RAW:/home/ylxiao/ws_211/rosetta_vitis/ydma/hw/_x/link/int/ydma.xml \
           --add-section SYSTEM_METADATA:RAW:/home/ylxiao/ws_211/rosetta_vitis/ydma/hw/_x/link/int/systemDiagramModelSlrBaseAddress.json \
           --key-value SYS:PlatformVBNV:xilinx_u50_gen3x16_xdma_201920_3 \
           --output $2 
           #--add-section BITSTREAM:RAW:/home/ylxiao/ws_211/rosetta_vitis/ydma/hw/_x/link/int/partial.bit \
           #--output /home/ylxiao/ws_211/rosetta_vitis/ydma/hw/ydma.xclbin
