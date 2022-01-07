#!/usr/bin/env python
import argparse
import os


parser = argparse.ArgumentParser()
parser.add_argument('workspace')
parser.add_argument('-t', '--top',       type=str, default="no_func", help="set top function name for out of context synthesis")
parser.add_argument('-f', '--file_name', type=str, default="no_func", help="set output file name prefix")

args = parser.parse_args()
workspace = args.workspace
top_name  = args.top
file_name = args.file_name




# prepare the tcl file to restore the top dcp file
file_in = open(workspace+'/_x/link/vivado/vpl/prj/prj.runs/impl_1/'+file_name+'.tcl', 'r')
file_out = open(workspace+'/_x/link/vivado/vpl/prj/prj.runs/impl_1/'+file_name+'_mk_overlay.tcl', 'w')

copy_enable = True
for line in file_in:
  if copy_enable:
    if (line.replace('add_files', '') != line):
      file_out.write('# ' + line)
    elif (line.replace('write_checkpoint -force', '') != line):
      file_out.write('write_checkpoint -force design_route.dcp\n')
    elif (line.replace('write_bitstream -force', '') != line):
      file_out.write('\n')
      for p in range(2, 18):
        file_out.write('report_utilization -pblocks p_'+str(p)+' > ../../../../../../../../../utilization'+str(p)+'.rpt\n')
      file_out.write('pr_recombine -cell pfm_top_i/dynamic_region\n')
      file_out.write('write_bitstream -force -cell pfm_top_i/dynamic_region ./dynamic_region.bit\n')
    elif (line.replace('set_property SCOPED_TO_CELLS', '') != line):
      file_out.write('# ' + line)
      file_out.write('add_files ../../../../../../../zcu102_dfx_manual/checkpoint/hw_bb_divided.dcp\n')
      file_out.write('add_files ../../../../../../../zcu102_dfx_manual/checkpoint/page.dcp\n')
      file_out.write('add_files ../../../../../../../zcu102_dfx_manual/xdc/sub.xdc\n')
      file_out.write('set_property SCOPED_TO_CELLS { pfm_top_i/dynamic_region/ydma_1/page2_inst pfm_top_i/dynamic_region/ydma_1/page3_inst pfm_top_i/dynamic_region/ydma_1/page4_inst pfm_top_i/dynamic_region/ydma_1/page5_inst pfm_top_i/dynamic_region/ydma_1/page6_inst pfm_top_i/dynamic_region/ydma_1/page7_inst pfm_top_i/dynamic_region/ydma_1/page8_inst pfm_top_i/dynamic_region/ydma_1/page9_inst pfm_top_i/dynamic_region/ydma_1/page10_inst pfm_top_i/dynamic_region/ydma_1/page11_inst pfm_top_i/dynamic_region/ydma_1/page12_inst pfm_top_i/dynamic_region/ydma_1/page13_inst pfm_top_i/dynamic_region/ydma_1/page14_inst pfm_top_i/dynamic_region/ydma_1/page15_inst pfm_top_i/dynamic_region/ydma_1/page16_inst pfm_top_i/dynamic_region/ydma_1/page17_inst}  [get_files ../../../../../../../zcu102_dfx_manual/checkpoint/page.dcp] \n')
      file_out.write('set_property USED_IN {implementation} [get_files ../../../../../../../zcu102_dfx_manual/xdc/sub.xdc]\n')
      file_out.write('set_property PROCESSING_ORDER LATE [get_files ../../../../../../../zcu102_dfx_manual/xdc/sub.xdc]\n')
    elif (line.replace('reconfig_partitions', '') != line):
      file_out.write('# ' + line)
      file_out.write('link_design -mode default -part xczu9eg-ffvb1156-2-e -reconfig_partitions {pfm_top_i/dynamic_region/ydma_1/page2_inst pfm_top_i/dynamic_region/ydma_1/page3_inst pfm_top_i/dynamic_region/ydma_1/page4_inst pfm_top_i/dynamic_region/ydma_1/page5_inst pfm_top_i/dynamic_region/ydma_1/page6_inst pfm_top_i/dynamic_region/ydma_1/page7_inst pfm_top_i/dynamic_region/ydma_1/page8_inst pfm_top_i/dynamic_region/ydma_1/page9_inst pfm_top_i/dynamic_region/ydma_1/page10_inst pfm_top_i/dynamic_region/ydma_1/page11_inst pfm_top_i/dynamic_region/ydma_1/page12_inst pfm_top_i/dynamic_region/ydma_1/page13_inst pfm_top_i/dynamic_region/ydma_1/page14_inst pfm_top_i/dynamic_region/ydma_1/page15_inst pfm_top_i/dynamic_region/ydma_1/page16_inst pfm_top_i/dynamic_region/ydma_1/page17_inst } -top pfm_top_wrapper\n')
    else:
      file_out.write(line)
      
file_in.close()
file_out.close()

# file_in   = open(workspace+'/_x/link/vivado/vpl/.local/hw_platform/tcl_hooks/impl.xdc', 'r')
# file_out  = open(workspace+'/_x/link/vivado/vpl/.local/hw_platform/tcl_hooks/.impl.xdc', 'w')
# 
# for line in file_in:
#   if (line.replace('SLR', '') != line):
#     file_out.write('# ' + line)
#   else:
#     file_out.write(line)
# 
# file_in.close()
# file_out.close()
# os.system('mv '+workspace+'/_x/link/vivado/vpl/.local/hw_platform/tcl_hooks/.impl.xdc ' + workspace+'/_x/link/vivado/vpl/.local/hw_platform/tcl_hooks/impl.xdc')
#  
# file_in   = open(workspace+'/_x/link/vivado/vpl/.local/hw_platform/tcl_hooks/preopt.tcl', 'r')
# file_out  = open(workspace+'/_x/link/vivado/vpl/.local/hw_platform/tcl_hooks/.preopt.tcl', 'w')
# 
# for line in file_in:
#   if (line.replace('SLR', '') != line):
#     file_out.write('# ' + line)
#   else:
#     file_out.write(line)
# 
# file_in.close()
# file_out.close()
# os.system('mv '+ workspace+'/_x/link/vivado/vpl/.local/hw_platform/tcl_hooks/.preopt.tcl ' + workspace+'/_x/link/vivado/vpl/.local/hw_platform/tcl_hooks/preopt.tcl')
 












