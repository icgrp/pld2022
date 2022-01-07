#!/usr/bin/env python
import argparse
import os


parser = argparse.ArgumentParser()
parser.add_argument('workspace')
parser.add_argument('-t', '--top', type=str, default="no_func", help="set top function name for out of context synthesis")
parser.add_argument('-f', '--file_name', type=str, default="no_func", help="set output file name prefix")


args = parser.parse_args()
workspace = args.workspace
top_name  = args.top
file_name = args.file_name





# prepare the tcl file to restore the top dcp file
file_in = open(workspace+'/_x/link/vivado/vpl/prj/prj.runs/impl_1/'+file_name+'.tcl', 'r')
file_out = open(workspace+'/_x/link/vivado/vpl/prj/prj.runs/impl_1/gen_pfm_dynamic.tcl', 'w')

copy_enable = True
for line in file_in:
  if copy_enable:
    if (line.replace('set rc [catch {', '') != line):
      file_out.write('# ' + line)
    elif (line.replace('hw_bb_locked.dcp', '') != line):
      file_out.write('# ' + line)
    elif (line.replace('xdc', '') != line):
      file_out.write('# ' + line)
    elif (line.replace('link_design', '') != line and line.replace('END', '') != line):
      file_out.write(line)
      copy_enable = False
    elif (line.replace('reconfig_partitions', '') != line):
      file_out.write('# ' + line)
      file_out.write('link_design -part xczu3eg-sbva484-1-i -top pfm_dynamic\n') 
      file_out.write('write_checkpoint -force pfm_dynamic.dcp\n')
    else:
      file_out.write(line)
      
file_in.close()
file_out.close()


