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




for i in range(100):
  file_out = open(workspace+'/_x/link/vivado/vpl/prj/prj.runs/impl_1/abs_gen'+str(i)+'.tcl', 'w')
  file_out.write('open_checkpoint design_route.dcp\n')
  file_out.write('update_design -cell level0_i/ulp/ydma_1/page'+str(i)+'_inst -black_box\n')
  file_out.write('lock_design -level routing\n')
  file_out.write('write_abstract_shell -force -cell level0_i/ulp/ydma_1/page'+str(i)+'_inst p_'+str(i)+'\n')
  file_out.close()

