#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import subprocess
import xml.etree.ElementTree
import re
import math


class gen_fifo:
  def __init__(self, parameter_file):
    self.parameter_file = parameter_file

  def file_to_list(self, file_name):
    file_list = []
    file_in = open(file_name, 'r')
    for line in file_in:
      file_list.append(line.replace('\n',''))
    return file_list

  def value_to_power_of_2_list(self, value, num_list):
    if value <= 512: 
      if value != 0:
        num_list.append(value)
      return num_list
    power_of_2_num = 2**int(math.log(value)/math.log(2))
    residual_value = value - power_of_2_num
    num_list.append(power_of_2_num)
    self.value_to_power_of_2_list(residual_value, num_list)
    return num_list
    
  def list_to_file(self, file_list, file_name):
    file_out = open(file_name, 'w')
    for line in file_list:
      file_out.write(line+'\n') 
    file_out.close()

  def extract_array_definition(self, file_list):
    array_name_list = file_list[0].split('[')
    array_definition = array_name_list[0]
    return array_definition

  def extract_data(self, file_list):
    data_list = []
    for line in file_list:
      data = re.findall(r"0x\w*", line)
      data_list.append(data[0]) 
    return data_list 

  def gen_parameter_file(self, data_list, bram_size_list, array_definition, out_dir):
    # extract the big array name
    # use the same name as prefix for the decomposed small fifos
    out_file_prefix_list = array_definition.split()
    out_file_prefix = out_file_prefix_list[-1]
    
    counter = 0 
    for i in range(len(bram_size_list)):
      # decide how many small fifos to use
      array_list = self.value_to_power_of_2_list(bram_size_list[i], []) 
      file_out = open(out_dir+'/'+out_file_prefix+'_par_'+str(i)+'.h','w')
      func_def_cpp = open(out_dir+'/'+out_file_prefix+'_gen_'+str(i)+'.cpp','w')
      func_def_h   = open(out_dir+'/'+out_file_prefix+'_gen_'+str(i)+'.h','w')
     
      if i==0: 
        func_def_h.write('void '+out_file_prefix+'_gen_'+str(i)+'(hls::stream< Word > & Output_1);\n')
        func_def_cpp.write('#include \"Typedefs.h\"\n')
        func_def_cpp.write('void '+out_file_prefix+'_gen_'+str(i)+'(hls::stream< Word > & Output_1){\n')
        func_def_cpp.write('#pragma HLS INTERFACE ap_hs port=Output_1\n')
        func_def_cpp.write('#include "'+out_file_prefix+'_par_'+str(i)+'.h"\n')
      else:
        func_def_h.write('void '+out_file_prefix+'_gen_'+str(i)+'(hls::stream< Word > & Input_1, hls::stream< Word > & Output_1);\n')
        func_def_cpp.write('#include \"Typedefs.h\"\n')
        func_def_cpp.write('void '+out_file_prefix+'_gen_'+str(i)+'(hls::stream< Word > & Input_1, hls::stream< Word > & Output_1){\n')
        func_def_cpp.write('#pragma HLS INTERFACE ap_hs port=Input_1\n')
        func_def_cpp.write('#pragma HLS INTERFACE ap_hs port=Output_1\n')
        func_def_cpp.write('#include "'+out_file_prefix+'_par_'+str(i)+'.h"\n')
        func_def_cpp.write(' loop_redir: for(int i=0; i<'+str(counter)+'; i++){\n')
        func_def_cpp.write('#pragma HLS PIPELINE II=1\n')
        func_def_cpp.write('    Output_1.write(Input_1.read());\n')
        func_def_cpp.write('  }\n')

      for j in range(len(array_list)):
        # decompose the small fifos size to the  power of 2
        func_def_cpp.write(' loop_'+str(j)+': for(int i=0; i<'+str(array_list[j])+'; i++){\n')
        func_def_cpp.write('#pragma HLS PIPELINE II=1\n')
        func_def_cpp.write('  Output_1.write('+out_file_prefix+'_'+str(i)+'_'+str(j)+'[i]);\n')
        func_def_cpp.write('  }\n')
        for k in range(array_list[j]):
          if array_list[j]==1:
            file_out.write(array_definition+'_'+str(i)+'_'+str(j)+'[] = {'+data_list[counter]+'};\n')
          elif k==0:
            file_out.write(array_definition+'_'+str(i)+'_'+str(j)+'[] = {'+data_list[counter]+',\n')
          elif k==array_list[j]-1:
            file_out.write(data_list[counter]+'};\n')
          else:
            file_out.write(data_list[counter]+',\n')
          counter+=1
      func_def_cpp.write('}\n')
      file_out.close()



  def run(self, file_name, bram_size_list, out_dir):
    # convert file to a list
    file_list = self.file_to_list(file_name)

    # extract the array definition
    array_definition = self.extract_array_definition(file_list)

    # extract the pure value
    data_list = self.extract_data(file_list)
    
    # generate the paramter header files and fifo function files 
    self.gen_parameter_file(data_list, bram_size_list, array_definition, out_dir) 

if __name__ == '__main__':
  # bram_size_list = [20480, 20480, 20480, 15452]
  bram_size_list = [8192, 8192,  14336, 14336, 20480, 20480, 20480, 14336, 14336, 20480, 19954]
  # bram_size_list = [20480, 20480, 20480, 20480, 20480]
  fifo_inst = gen_fifo('')
  fifo_inst.run('./src/bin_dense_par.h', bram_size_list, './src')

