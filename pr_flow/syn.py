# -*- coding: utf-8 -*-   
# Company: IC group, University of Pennsylvania
# Engineer: Yuanlong Xiao
#
# Create Date: 02/11/2021
# Design Name: overlay
# Project Name: DIRC
# Versions: 1.0
# Description: This is a python script to prepare the script for Out-Context-Synthesis 
#              from verilog to DCP for PRFlow
# Dependencies: python2, gen_basic.py, config.py
# Revision:
# Revision 0.01 - File Created
#
# Additional Comments:



import os  
import subprocess
from pr_flow.gen_basic import gen_basic
import pr_flow.config as config
import re


class syn(gen_basic):

  # from the source header file, find the input or output number
  def return_io_num(self, io_pattern, file_list):
    max_num = 0
    for line in file_list:
      num_list = re.findall(r""+io_pattern+"\d*", line)
      if(len(num_list)>0 and int(num_list[0].replace(io_pattern,''))): max_num = int(num_list[0].replace(io_pattern,''))
    return max_num
  
  def return_bit_size(self, num):
    bit_size = 1
    num_local = int(num)
    while (True):
      if (num_local >> 1) != 0:
        num_local = num_local >> 1 
        bit_size = bit_size + 1
      else:
        return bit_size


  def prepare_HW(self, operator, page_num, input_num, output_num):
    # If the map target is Hardware, we need to prepare the HDL files and scripts to 
    # compile it.
    self.shell.mkdir(self.syn_dir+'/'+operator+'/src')
    file_list = [
      'src/Config_Controls.v',
      'src/write_queue.v',
      'src/rise_detect.v',
      'src/read_queue.v',
      'src/converge_ctrl.v',
      'src/ExtractCtrl.v',
      'src/Input_Port_Cluster.v',
      'src/Input_Port.v',
      'src/leaf_interface.v',
      'src/Output_Port_Cluster.v',
      'src/Output_Port.v',
      'src/read_b_in.v',
      'src/ram0.v',
      'src/single_ram.v',
      'src/SynFIFO.v',
      'src/instr_config.v',
      'src/picorv32_wrapper.v',
      'src/picorv32.v',
      'src/picorv_mem.v',
      'src/xram2.v',
      'src/xram_triple.v',
      'src/riscv2consumer.v',
      'src/Stream_Flow_Control.v',
      'src/write_b_in.v',
      'src/write_b_out.v']
    # copy the necessary leaf interface verilog files for out-of-context compilation
    for name in file_list: self.shell.cp_file(self.overlay_dir+'/'+name, self.syn_dir+'/'+operator+'/'+name)

    # prepare the tcl files for out-of-context compilation
    self.shell.write_lines(self.syn_dir+'/'+operator+'/syn_page.tcl', self.tcl.return_syn_page_tcl_list(operator, ['./leaf.v']))

    # prepare the leaf verilog files.
    # Id depends on the IO numbers and operator name
    operator_arg_list, operator_width_list = self.return_operator_io_argument_width_list_local(operator)   
    self.shell.write_lines(self.syn_dir+'/'+operator+'/leaf.v', self.verilog.return_page_v_list(page_num, operator, input_num, output_num, operator_arg_list, operator_width_list, True), False)

    # Prepare the shell script to run vivado
    self.shell.write_lines(self.syn_dir+'/'+operator+'/run.sh', self.shell.return_run_sh_list(self.prflow_params['Xilinx_dir'], 'syn_page.tcl', self.prflow_params['back_end']), True)

  def ceiling_mem_size(self, size_in):
    size_out = 1
    # use 3/4 of the power-of-2 size to improve BRAM effeciency
    is_triple = 0
    while(size_out < int(size_in)):
      size_out = size_out * 2

    if size_out/4*3 < int(size_in):
      is_triple = 0
      return is_triple, size_out
    else:
      is_triple = 1
      return is_triple, size_out/4*3

  def return_bram18_number(self, size_in, input_num, output_num):
    out= int(size_in)/2048 + int(self.prflow_params['input_port_bram_cost'])*input_num+int(self.prflow_params['output_port_bram_cost'])*output_num + 1
    return out

  def prepare_RISCV(self, operator, page_num, input_num, output_num):
    # extract basic information about the operator
    operator_arg_list, operator_width_list = self.return_operator_io_argument_width_list_local(operator)   
    map_target, page_num, input_num, output_num =  self.return_map_target(operator)
    debug_exist, debug_port = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'debug_port')
    if(debug_exist): output_num = output_num+1

    # if 1, use 3/4 of the power-of-2 brams
    is_triple = 0

    if map_target == 'RISCV':  inst_mem_exist, inst_mem_size = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'inst_mem_size')
    if inst_mem_exist == False:
      inst_mem_size = 16384 
    else:
      is_triple, inst_mem_size = self.ceiling_mem_size(inst_mem_size)



    # if no existed bitstream for riscv core, regenerate the necessary files for synthesis
    riscv_bit = 'empty'
    for i in range(int(input_num), 6):
      for j in range(int(output_num), 6):
        if os.path.exists(self.overlay_dir+'/riscv_bit_lib/page'+page_num+'_'+str(inst_mem_size/2048)+'bram'+'I'+str(i)+'O'+str(j)+'.bit'):
          riscv_bit = self.overlay_dir+'/riscv_bit_lib/page'+page_num+'_'+str(inst_mem_size/2048)+'bram'+str(i)+'O'+str(j)+'.bit'
          break

    utilization_log_list = self.shell.file_to_list(self.overlay_dir+'/utilization'+page_num+'.rpt')
    for line in utilization_log_list: 
      if (self.shell.have_target_string(line, '|   RAMB18       |')):
        line = line.replace(' ','')
        line_list = line.split('|')
        bram_limit = line_list[8] 



    if(int(bram_limit) < self.return_bram18_number(inst_mem_size, input_num, output_num)): 
      log_out = open( self.syn_dir+'/'+operator+'/runLog_'+operator+'.log', 'w')
      log_out.write('echo no enough bram18s to map the riscv cores\n')
      print ('\n================================================')
      print ('This operator needs ' + str(self.return_bram18_number(inst_mem_size, input_num, output_num)) + ' brams, while we only have ' + str(bram_limit) +' brams in this page')
      print ('================================================\n')
      log_out.close()
      return

    if(int(output_num) > 5):
      log_out = open( self.syn_dir+'/'+operator+'/runLog_'+operator+'.log', 'w')
      log_out.write('No enough output ports. The maximum output port number is 5!\n')
      print ('\n==========================================================')
      print ('No enough output ports. The maximum output port number is 5!\n')
      print ('============================================================\n')
      log_out.close()
      return

    if riscv_bit == 'empty':
      self.prepare_HW(operator, page_num, input_num, output_num)

    inst_mem_bits = self.return_bit_size(inst_mem_size-1)-2
    print ('inst_mem_bits', inst_mem_bits)
    LENGTH = '0x'+hex(int(inst_mem_size)).replace('0x', '').zfill(8)
    print (LENGTH)
    # create a riscv dirctory
    self.shell.cp_dir('./common/riscv_src/riscv/*', self.syn_dir+'/'+operator)
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/run.sh', {'RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX=': 'RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX='+self.prflow_params['riscv_dir']}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/run.sh', {'operator=': 'operator='+operator}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/run.sh', {'MEM_SIZE=': 'MEM_SIZE='+str(int(inst_mem_size)/4)}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/run.sh', {'PAGE_NUM=': 'PAGE_NUM='+str(page_num)}) 
    os.system('chmod +x ' + self.syn_dir+'/'+operator+'/run.sh') 

    # Add operator instantiation into the main wrapper function  
    config_inst = config.config(self.prflow_params)
    io_argument_dict = config_inst.return_operator_io_argument_dict_local(operator)
    main_cpp_str_list = []
    for num in range(input_num):
      WIDTH = operator_width_list[self.verilog.return_idx_in_list_local(operator_arg_list, 'Input_'+str(num+1))].split('<')[1].split('>')[0]
      main_cpp_str_list.append('  hls::stream<ap_uint<'+str(WIDTH)+'> > Input_'+str(num+1)+'(STREAMIN'+str(num+1)+','+str(WIDTH)+');')
    for num in range(output_num):
      WIDTH = operator_width_list[self.verilog.return_idx_in_list_local(operator_arg_list, 'Output_'+str(num+1))].split('<')[1].split('>')[0]
      main_cpp_str_list.append('  hls::stream<ap_uint<'+str(WIDTH)+'> > Output_'+str(num+1)+'(STREAMOUT'+str(num+1)+','+str(WIDTH)+');')
    str_line = '    '+operator+'('
    for io_name in io_argument_dict[operator]:
      str_line = str_line + io_name + ','
    str_line = str_line + ')'
    str_line = str_line.replace(',)', ');')
    main_cpp_str_list.append('  while(1){')
    main_cpp_str_list.append(str_line)
    main_cpp_str_list.append('  }')
    self.shell.add_lines(self.syn_dir+'/'+operator+'/main.cpp', '//stream', main_cpp_str_list)

    # copy the typedefs.h file into out-of-context synthesis dir
    # replace the headerfile defintions
    self.shell.cp_file('input_src/'+self.prflow_params['benchmark_name']+'/host/typedefs.h', self.syn_dir+'/'+operator)
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/typedefs.h', {'<hls_stream.h>': '#include "hls_stream.h"'}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/typedefs.h', {'<ap_fixed.h>': '#include "ap_fixed.h"'}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/typedefs.h', {'#define risc': '#define RISCV'}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/typedefs.h', {'<ap_int.h>': '#include "ap_int.h"'}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/typedefs.h', {'<hls_video.h>': '#include "hls_video.h"'}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/typedefs.h', {'gmp': ''}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/typedefs.h', {'#define __TYPEDEFS_H__': '#define __TYPEDEFS_H__\n#define RISCV'}) 
    self.shell.cp_file('input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.*', self.syn_dir+'/'+operator)
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/'+operator+'.cpp', {'typedefs.h': '#include "typedefs.h"\n#include "firmware.h"'}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/firmware.h', {'// operator': '#include "'+operator+'.h"'}) 
    self.shell.replace_lines(self.syn_dir+'/'+operator+'/sections.lds', {'mem : ORIGIN': '         mem : ORIGIN = 0x00000000, LENGTH = '+LENGTH}) 
    if debug_exist: self.shell.replace_lines(self.syn_dir+'/'+operator+'/print.cpp', {'#define OUTPORT': '#define OUTPORT (0x10000000+8*'+str(output_num)+')'})  
 
    # modify the run.sh shell for riscv
    self.shell.write_lines(self.syn_dir+'/'+operator+'/leaf.v', self.verilog.return_page_v_list(page_num, operator, input_num, output_num, operator_arg_list, operator_width_list, True, True), False)
    if riscv_bit == 'empty':
      if self.prflow_params['back_end'] == 'slurm':
        self.shell.replace_lines(self.syn_dir+'/'+operator+'/run.sh', {'vivado': 'source '+self.prflow_params['Xilinx_dir']+'\nvivado -mode batch -source syn_page.tcl\n'} )
      else:
        self.shell.replace_lines(self.syn_dir+'/'+operator+'/run.sh', {'vivado': 'source '+self.prflow_params['Xilinx_dir']+'\nvivado -mode batch -source syn_page.tcl\n'} )
      self.shell.replace_lines(self.syn_dir+'/'+operator+'/src/picorv32_wrapper.v', {'parameter IS_TRIPLE': 'parameter IS_TRIPLE = '+str(is_triple)+','})
      self.shell.replace_lines(self.syn_dir+'/'+operator+'/src/picorv32_wrapper.v', {'parameter MEM_SIZE': 'parameter MEM_SIZE = '+str(inst_mem_size)+','})
      self.shell.replace_lines(self.syn_dir+'/'+operator+'/src/picorv32_wrapper.v', {'parameter ADDR_BITS': 'parameter ADDR_BITS = '+str(inst_mem_bits)})
    else:
      self.shell.replace_lines(self.syn_dir+'/'+operator+'/run.sh', {'vivado': 'touch page_netlist.dcp\n'} )
      
    os.system('chmod +x '+self.syn_dir+'/'+operator+'/run.sh')
 

  # create one directory for each page 
  def create_page(self, operator):
    self.shell.re_mkdir(self.syn_dir+'/'+operator)
    map_target, page_num, input_num, output_num =  self.return_map_target(operator)
    self.shell.write_lines(self.syn_dir+'/'+operator+'/main.sh', self.shell.return_main_sh_list(
                                                                                                  './run.sh', 
                                                                                                  self.prflow_params['back_end'], 
                                                                                                  'hls_'+operator, 
                                                                                                  'syn_'+operator, 
                                                                                                  self.prflow_params['grid'], 
                                                                                                  'qsub@qsub.com',
                                                                                                  self.prflow_params['mem'], 
                                                                                                  self.prflow_params['node'], 
                                                                                                   ), True)
 
    if map_target == 'HW': 
      self.prepare_HW(operator, page_num, input_num, output_num)
    else:
      pass
      # prepare script files for riscv implementation.
      # As we don't need to compile any verilog files, we only need to perform 
      # RISC-V compile flow
      self.prepare_RISCV(operator, page_num, input_num, output_num)

   

  #pragma map_target=HW page_num=page_17
  def return_map_target(self, operator):
    src_list = self.shell.file_to_list('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h')
    input_num = self.return_io_num('Input_', src_list)
    output_num = self.return_io_num('Output_', src_list)
    HW_exist, page_num           = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'page_num')
    map_target_exist, map_target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'map_target')
    return map_target, page_num, input_num, output_num

  def return_operator_io_argument_width_list_local(self, operator):
    operator_list = operator.split()
    operator_arg_dict = {}
    operator_width_dict = {}
    file_list = self.shell.file_to_list('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h')
    arguments_list = [] 
    width_list = [] 
    def_valid = False # Ture if function definition begins
    def_str = ''
    for line in file_list:
      if self.shell.have_target_string(line, '('): def_valid = True
      if def_valid: 
        line_str=re.sub('\s+', '', line)
        line_str=re.sub('\t+', '', line_str)
        def_str=def_str+line_str
      if self.shell.have_target_string(line, ')'): def_valid = False

    # a list for the stream arguments functions
    arg_str_list = def_str.split(',')
    for arg_str in arg_str_list:
      input_str_list  = re.findall(r"Input_\d+", arg_str)
      output_str_list = re.findall(r"Output_\d+", arg_str)
      str_width_list = re.findall(r"ap_uint\<\d+\>", arg_str)
      input_str_list.extend(output_str_list)
      io_str = input_str_list
      width_list.append(str_width_list[0]) 
      arguments_list.append(io_str[0])
    operator_arg_dict[operator] = arguments_list
    operator_width_dict[operator] = width_list
    return arguments_list, width_list 



  def run(self, operator):
    # mk work directory
    self.shell.mkdir(self.syn_dir)
    # create ip directories for the operator
    self.create_page(operator)

     
