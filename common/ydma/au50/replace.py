#!/usr/bin/env python
# -*- coding: utf-8 -*-   
#starting
import os  
import argparse

def file2list(file_dir):
  file_in = open(file_dir, 'r')
  out_list=[]
  for line in file_in: out_list.append(line.replace('\n', ''))
  file_in.close()
  return out_list

def del_elements(in_list, flag_str, element_num):
  for idx, element in enumerate(in_list):
    if(element.replace(flag_str, '') != element): 
      for i in range(idx, idx+element_num+1):
        in_list[i] = '// '+in_list[i]

def replace_element(in_list, flag_str, subs_str):
  for idx, element in enumerate(in_list):
    if(element.replace(flag_str, '') != element): 
      in_list[idx] = subs_str+'\n'+in_list[idx]
      
def list2file(file_dir, in_list):
  file_out = open(file_dir, 'w') 
  for line in in_list: file_out.write(line+'\n')
  file_out.close()

if __name__ == '__main__':
  my_list = file2list('./_x/ydma/ydma/ydma/solution/impl/ip/hdl/verilog/ydma.v')
  # del_elements(my_list, 'ydma_fifo_w64_d256_A v', 11)
  del_elements(my_list, 'ydma_fifo_w512_d1024_A v', 11)
  subs_str='\n'
  subs_str+='mono mono_inst(\n'
  subs_str+='  .ap_clk(ap_clk),\n'
  subs_str+='  .ap_rst_n(ap_rst_n),\n'
  subs_str+='  .Input_1_V_TDATA(Loop_VITIS_LOOP_35_3_proc3_U0_v2_buffer_V_din),\n'
  subs_str+='  .Input_1_V_TVALID(Loop_VITIS_LOOP_35_3_proc3_U0_v2_buffer_V_write),\n'
  subs_str+='  .Input_1_V_TREADY(v2_buffer_V_full_n),\n'
  subs_str+='  .Output_1_V_TDATA(v2_buffer_V_dout),\n'
  subs_str+='  .Output_1_V_TVALID(v2_buffer_V_empty_n),\n'
  subs_str+='  .Output_1_V_TREADY(Loop_VITIS_LOOP_36_4_proc4_U0_v2_buffer_V_read),\n'
  subs_str+='  .ap_start(ap_start)\n'
  subs_str+=');\n'

  replace_element(my_list, 'endmodule', subs_str)

  list2file('./_x/ydma/ydma/ydma/solution/impl/ip/hdl/verilog/ydma.v', my_list)







