
#
# To run on the ZCU102 board, copy the packagge/sd_card directory onto the SD card, plug it into the board and power it up.
# When the Linux prompt appears, run this script by entering the following command:
#   source /mnt/sd-mmcblk0p1/run_app.sh 
#

xclbinutil --add-section DEBUG_IP_LAYOUT:JSON:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/debug_ip_layout.rtd \
--add-section BITSTREAM:RAW:./dynamic_region.bit \
--force --target hw --key-value SYS:dfx_enable:true \
--add-section :JSON:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/ydma.rtd \
--add-section CLOCK_FREQ_TOPOLOGY:JSON:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/ydma_xml.rtd \
--add-section BUILD_METADATA:JSON:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/ydma_build.rtd \
--add-section EMBEDDED_METADATA:RAW:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/ydma.xml \
--add-section SYSTEM_METADATA:RAW:/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/int/systemDiagramModelSlrBaseAddress.json \
--key-value SYS:PlatformVBNV:xilinx_zcu102_dynamic_1_0 \
--output dynamic_region.xclbin
