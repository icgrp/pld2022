# -*- coding: utf-8 -*-   

import os  
import subprocess
from pr_flow.gen_basic import gen_basic
import re

class runtime(gen_basic):
  def __init__(self, prflow_params):
    gen_basic.__init__(self, prflow_params)
    self.packet_bits        = int(self.prflow_params['packet_bits'])
    self.addr_bits          = int(self.prflow_params['addr_bits']) 
    self.port_bits          = int(self.prflow_params['port_bits'])
    self.payload_bits       = int(self.prflow_params['payload_bits'])
    self.bram_addr_bits     = int(self.prflow_params['bram_addr_bits'])
    self.freespace          = int(self.prflow_params['freespace'])
    self.page_addr_offset   = self.packet_bits - 1 - self.addr_bits
    self.port_offset        = self.packet_bits - 1 - self.addr_bits - self.port_bits
    self.config_port_offset = self.payload_bits - self.port_bits 
    self.dest_page_offset   = self.payload_bits - self.port_bits - self.addr_bits
    self.dest_port_offset   = self.payload_bits - self.port_bits - self.addr_bits - self.port_bits
    self.src_page_offset    = self.payload_bits - self.port_bits - self.addr_bits
    self.src_port_offset    = self.payload_bits - self.port_bits - self.addr_bits - self.port_bits
    self.freespace_offset   = self.payload_bits - self.port_bits - self.addr_bits - self.port_bits - self.bram_addr_bits - self.bram_addr_bits

  # from the source header file, find the input or output number
  def return_io_num(self, io_pattern, file_list):
    max_num = 0
    for line in file_list:
      num_list = re.findall(r""+io_pattern+"\d*", line)
      if(len(num_list)>0 and int(num_list[0].replace(io_pattern,''))): max_num = int(num_list[0].replace(io_pattern,''))
    return max_num
 
  # find all the operators page num  
  def return_page_num_dict_local(self, operators):
    operator_list = operators.split()
    page_num_dict = {'DMA':1, 'DMA2': 7, 'ARM':0, 'DEBUG':2}
    for operator in operator_list:
      HW_exist, target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'map_target')
      page_exist, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'page_num')
      #if HW_exist and target=='HW' and page_exist:
      if page_exist:
        page_num_dict[operator] = page_num
    return page_num_dict 

  # find all the operators arguments order
  # in case the user define the input and output arguments out of order 
  def return_operator_io_argument_dict_local(self, operators):
    operator_list = operators.split()
    operator_arg_dict = {}
    for operator in operator_list:
      file_list = self.shell.file_to_list('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h')
      arguments_list = [] 
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
        input_str_list = re.findall(r"Input_\d+", arg_str)
        output_str_list = re.findall(r"Output_\d+", arg_str)
        input_str_list.extend(output_str_list)
        io_str = input_str_list
        arguments_list.append(io_str[0])
       
      operator_arg_dict[operator] = arguments_list
    return operator_arg_dict 


  # find all the operators instantiation in the top function
  def return_operator_inst_dict_local(self, operators):
    operator_list = operators.split()
    operator_var_dict = {}
    file_list = self.shell.file_to_list('./input_src/'+self.prflow_params['benchmark_name']+'/host/top.cpp')
    for operator in operator_list:
      arguments_list = [] 
      
      # 1 when detect the start of operation instantiation
      # 2 when detect the end of operation instantiation
      inst_cnt = 0 
      inst_str = ''
      for line in file_list:
        if self.shell.have_target_string(line, operator+'('): inst_cnt = inst_cnt + 1
        if inst_cnt == 1: 
          line_str=re.sub('\s+', '', line)
          line_str=re.sub('\t+', '', line_str)
          line_str=re.sub('//.*', '', line_str)
          inst_str=inst_str+line_str
        if self.shell.have_target_string(line, ')') and inst_cnt == 1: inst_cnt = 2
      inst_str = inst_str.replace(operator+'(','')
      inst_str = inst_str.replace(');','')
      var_str_list = inst_str.split(',')
      operator_var_dict[operator] = var_str_list
    
    return operator_var_dict 

  def return_io_num(self, io_pattern, file_list):
    max_num = 0
    for line in file_list:
      num_list = re.findall(r""+io_pattern+"\d*", line)
      if(len(num_list)>0 and int(num_list[0].replace(io_pattern,''))): max_num = int(num_list[0].replace(io_pattern,''))
    return max_num
 

  def return_operator_connect_list_local(self, operator_arg_dict, operator_var_dict):
    connection_list = []
    for key_a in operator_var_dict:
      operator = key_a
      src_list = self.shell.file_to_list('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h')
      debug_exist, debug_port = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+key_a+'.h', 'debug_port')
      map_target_exist, map_target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+key_a+'.h', 'map_target')
      if debug_exist:
        src_list = self.shell.file_to_list('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h')
        output_num = self.return_io_num('Output_', src_list)
        tmp_str = key_a+'.Output_'+str(output_num+1)+'->DEBUG.Input_'+str(debug_port) 
        connection_list.append(tmp_str)
      for i_a, var_value_a in enumerate(operator_var_dict[key_a]):
        if var_value_a == 'Input_1': 
          tmp_str='DMA.Output_1->'+key_a+'.Input_1' 
          connection_list.append(tmp_str)
        if var_value_a == 'Input_2': 
          tmp_str='DMA2.Output_1->'+key_a+'.Input_1' 
          connection_list.append(tmp_str)
        if var_value_a == 'Output_1': 
          tmp_str=key_a+'.Output_1->'+'DMA.Input_1'
          connection_list.append(tmp_str)
        for key_b in operator_var_dict:
          for i_b, var_value_b in enumerate(operator_var_dict[key_b]):
            if var_value_a==var_value_b and key_a!=key_b:
              if self.shell.have_target_string(operator_arg_dict[key_a][i_a], 'Input'):
                tmp_str = key_b+'.'+operator_arg_dict[key_b][i_b]+'->'+key_a+'.'+operator_arg_dict[key_a][i_a]
              else:
                tmp_str = key_a+'.'+operator_arg_dict[key_a][i_a]+'->'+key_b+'.'+operator_arg_dict[key_b][i_b]
              connection_list.append(tmp_str)

    #connection_list = []
    #connection_list.append('DEBUG.Output_1->add1.Input_1')
    #connection_list.append('add1.Output_1->DEBUG.Input_1')
    #connection_list.append('add1.Output_2->DEBUG.Input_3')
    #connection_list.append('add1.Output_3->DEBUG.Input_3')
    #connection_list.append('add1.Output_5->DEBUG.Input_5')
    connection_list = set(connection_list)
    return connection_list


  def return_config_packet_list_local(self, page_num_dict, connection_list, operators):
    packet_list = []
    packet_num = 2
    for str_value in connection_list:
      packet_list.append('//'+str_value)
      str_list = str_value.split('->')
      [src_operator, src_output] = str_list[0].split('.')
      [dest_operator, dest_input] = str_list[1].split('.')
      src_page = int(page_num_dict[src_operator])
      src_port = int(src_output.replace('Output_',''))+int(self.prflow_params['output_port_base'])-1
      dest_page = int(page_num_dict[dest_operator])
      dest_port = int(dest_input.replace('Input_',''))+int(self.prflow_params['input_port_base'])-1
      print (src_page,src_port,'->',dest_page,dest_port)
      src_page_packet =                   (src_page  << self.page_addr_offset)
      src_page_packet = src_page_packet + (       0  << self.port_offset)
      src_page_packet = src_page_packet + (src_port  << self.config_port_offset)
      src_page_packet = src_page_packet + (dest_page << self.dest_page_offset)
      src_page_packet = src_page_packet + (dest_port << self.dest_port_offset)
      src_page_packet = src_page_packet + ((2**self.bram_addr_bits-1) << self.freespace_offset)
      value_low  =  (src_page_packet      ) & 0xffffffff
      value_high =  (src_page_packet >> 32) & 0xffffffff
      # print 'src_page_packet: ', str(hex(value_high)).replace('L', ''), str(hex(value_low)).replace('L', '') 
      # packet_list.append("  write_to_fifo(" + str(hex(value_high)).replace('L', '') + ', ' + str(hex(value_low)).replace('L', '') + ");")

      packet_list.append("      in1["+str(packet_num)+"].range(63, 32) = 0x" + str(hex(value_high)).replace('L', '').replace('0x','').zfill(8) + '; ')
      packet_list.append("      in1["+str(packet_num)+"].range(31,  0) = " + str(hex(value_low)).replace('L', '') + ";")
      packet_num += 1

      dest_page_packet =                    (dest_page  << self.page_addr_offset)
      dest_page_packet = dest_page_packet + (        1  << self.port_offset)
      dest_page_packet = dest_page_packet + (dest_port  << self.config_port_offset)
      dest_page_packet = dest_page_packet + (src_page   << self.src_page_offset)
      dest_page_packet = dest_page_packet + (src_port   << self.src_port_offset)
      value_low  =  (dest_page_packet      ) & 0xffffffff
      value_high =  (dest_page_packet >> 32) & 0xffffffff
      # print 'src_page_packet: ', str(hex(value_high)).replace('L', ''), str(hex(value_low)).replace('L', '') 
      # packet_list.append("  write_to_fifo(" + str(hex(value_high)).replace('L', '') + ', ' + str(hex(value_low)).replace('L', '') + ");")
      packet_list.append("      in1["+str(packet_num)+"].range(63, 32) = 0x" + str(hex(value_high)).replace('L', '').replace('0x','').zfill(8) + '; ')
      packet_list.append("      in1["+str(packet_num)+"].range(31,  0) = " + str(hex(value_low)).replace('L', '') + ";")
      packet_num += 1

    operator_list = operators.split()
    bft_addr_shift = int(self.prflow_params['pks']) - int(self.prflow_params['payload_bits']) - 1 - int(self.prflow_params['addr_bits'])
    include_str = '#include \"typedefs.h\"\n'
    for op in operator_list: 
      HW_exist, target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+op+'.h', 'map_target')
      instr_size_exist, instr_size = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+op+'.h', 'inst_mem_size')
      if target == 'RISCVV': 
        value_high = (int(page_num_dict[op]) << bft_addr_shift) + 1 
        packet_list.append('      for( int i=0; i<'+str(int(instr_size)/4)+'; i++){')
        packet_list.append("        in1["+str(packet_num)+"+i*4+0].range(63, 32) = 0x" + str(hex(value_high)).replace('L', '').replace('0x','').zfill(8) + '; ')
        packet_list.append("        in1["+str(packet_num)+"+i*4+0].range(31,  0) = ((i*4+0) << 8) + ((instr_data"+str(page_num_dict[op])+"[i]>>0 )  & 0x000000ff);")
        packet_list.append("        in1["+str(packet_num)+"+i*4+1].range(63, 32) = 0x" + str(hex(value_high)).replace('L', '').replace('0x','').zfill(8) + '; ')
        packet_list.append("        in1["+str(packet_num)+"+i*4+1].range(31,  0) = ((i*4+1) << 8) + ((instr_data"+str(page_num_dict[op])+"[i]>>8 )  & 0x000000ff);")
        packet_list.append("        in1["+str(packet_num)+"+i*4+2].range(63, 32) = 0x" + str(hex(value_high)).replace('L', '').replace('0x','').zfill(8) + '; ')
        packet_list.append("        in1["+str(packet_num)+"+i*4+2].range(31,  0) = ((i*4+2) << 8) + ((instr_data"+str(page_num_dict[op])+"[i]>>16)  & 0x000000ff);")
        packet_list.append("        in1["+str(packet_num)+"+i*4+3].range(63, 32) = 0x" + str(hex(value_high)).replace('L', '').replace('0x','').zfill(8) + '; ')
        packet_list.append("        in1["+str(packet_num)+"+i*4+3].range(31,  0) = ((i*4+3) << 8) + ((instr_data"+str(page_num_dict[op])+"[i]>>24)  & 0x000000ff);")
        packet_list.append("      }")
        packet_num += int(instr_size)
        include_str += '#include \"instr_data'+str(page_num_dict[op])+'.h\"\n'
        self.shell.cp_dir(self.syn_dir+'/'+op+'/instr_data'+str(page_num_dict[op])+'.h', self.bit_dir)
 
    self.shell.replace_lines(self.bit_dir+'/'+self.prflow_params['benchmark_name']+'/host/host.cpp', {'typedefss.h': include_str}) 

    for op in operator_list: 
      value_high = (int(page_num_dict[op]) << bft_addr_shift) + 2 
      value_low  = 0
      packet_list.append('      // start page'+str(page_num_dict[op])+'; ')
      packet_list.append("      in1["+str(packet_num)+"].range(63, 32) = 0x" + str(hex(value_high)).replace('L', '').replace('0x','').zfill(8) + '; ')
      packet_list.append("      in1["+str(packet_num)+"].range(31,  0) = 0x" + str(hex(value_low )).replace('L', '').replace('0x','').zfill(8) + ";")
      packet_num += 1
    return packet_list, packet_num

  def return_run_sdk_sh_list_local(self, vivado_dir, tcl_file):
    return ([
      '#!/bin/bash -e',
      'source ' + vivado_dir,
      'xsdk -batch -source ' + tcl_file,
      ''])

  def return_sh_list_local(self, command):
    return ([
      '#!/bin/bash -e',
      command,
      ''])



  def return_include_list_local(self, operators, dest_dir):
    include_list = []
    for operator in operators.split():
      page_exist, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'page_num')
      HW_exist, target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'map_target')
      if target == 'RISCV':
        self.shell.cp_dir(self.syn_dir+'/'+operator+'/instr_data'+str(page_num)+'.h', dest_dir)
        include_list.append('#include "instr_data'+str(page_num)+'.h"')
    
    return include_list

  def return_call_list_local(self, operators):
    call_list = []
    for operator in operators.split():
      page_exist, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'page_num')
      HW_exist, target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'map_target')
      instr_size_exist, instr_size = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'inst_mem_size')
      if target == 'RISCV': call_list.append('	instr_config('+str(page_num)+',instr_data'+str(page_num)+','+str(int(instr_size)/4)+');')

    return call_list
 
  def run(self, operators):
    # mk work directory
    if self.prflow_params['gen_runtime']==True:
      self.shell.mkdir(self.bit_dir)
    
    # prepare the host driver source for vitis runtime
    self.shell.cp_file('input_src/'+self.prflow_params['benchmark_name'], self.bit_dir)
    page_num_dict = self.return_page_num_dict_local(operators)
    operator_arg_dict = self.return_operator_io_argument_dict_local(operators)
    operator_var_dict = self.return_operator_inst_dict_local(operators)
    connection_list=self.return_operator_connect_list_local(operator_arg_dict, operator_var_dict)
    self.print_dict(page_num_dict)
    self.print_list(connection_list)
    packet_list, packet_num = self.return_config_packet_list_local(page_num_dict, connection_list, operators)
    self.print_list(packet_list) 
    tmp_dict = {'in1[0].range(31': '    in1[0].range(31,  0) = 0x'+str(hex(packet_num-2)).replace('L', '').replace('0x','').zfill(8)+';',
                '#define CONFIG_SIZE': '#define CONFIG_SIZE '+str(packet_num)} 
    self.shell.replace_lines(self.bit_dir+'/'+self.prflow_params['benchmark_name']+'/host/host.cpp', tmp_dict) 
    self.shell.add_lines(self.bit_dir+'/'+self.prflow_params['benchmark_name']+'/host/host.cpp', '// configure packets', packet_list) 

    self.shell.cp_file('common/script_src/gen_runtime_'+self.prflow_params['board']+'.sh', self.bit_dir+'/'+self.prflow_params['benchmark_name']+'/host/gen_runtime.sh')
    tmp_dict = {'Vitis'               : 'source '+self.prflow_params['Xilinx_dir'],
                'xrt'                 : 'source '+self.prflow_params['xrt_dir'],
                'Xilinx_dir'          : 'source '+self.prflow_params['Xilinx_dir'],
                'make'                : 'make app.exe\ncp ./app.exe ../../\ncp ./app.exe ../../sd_card\n cp ../../sd_card/dynamic_region.xclbin ../../',
                'XCL_EMULATION_MODE'  : '',
                'PLATFORM_REPO_PATHS' : 'export PLATFORM_REPO_PATHS='+self.prflow_params['PLATFORM_REPO_PATHS'],
                'ROOTFS'              : 'export ROOTFS='+self.prflow_params['ROOTFS'],
                'sdk_dir'             : 'source '+self.prflow_params['sdk_dir']}
    self.shell.replace_lines(self.bit_dir+'/'+self.prflow_params['benchmark_name']+'/host/gen_runtime.sh', tmp_dict)
    self.shell.replace_lines(self.bit_dir+'/'+self.prflow_params['benchmark_name']+'/sw_emu/build_and_run.sh', tmp_dict)
    self.shell.cp_file(self.bit_dir+'/'+self.prflow_params['benchmark_name']+'/host/gen_runtime.sh', self.bit_dir+'/run_app.sh')
    xclbin_list_str = 'dynamic_region.xclbin' 
    for operator in operators.split(): xclbin_list_str += ' '+operator+'.xclbin'
    self.shell.replace_lines(self.bit_dir+'/run_app.sh', {'g++': './app.exe '+xclbin_list_str, 'cp': ''})
    os.system('chmod +x '+self.bit_dir+'/run_app.sh')
    os.system('chmod +x '+self.bit_dir+'/'+self.prflow_params['benchmark_name']+'/sw_emu/build_and_run.sh')
    self.shell.re_mkdir(self.bit_dir+'/sd_card')
    self.shell.cp_file(self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/xrt.ini', self.bit_dir)
    self.shell.cp_file(self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/load.exe', self.bit_dir+'/sd_card')
    self.shell.cp_file(self.overlay_dir+'/dynamic_region.xclbin', self.bit_dir+'/sd_card')
    op_list = operators.split()
    tmp_list = ['#!/bin/bash -e', 'date', './load.exe dynamic_region.xclbin']
    self.shell.write_lines(self.bit_dir+ '/sd_card/run_app.sh', ['#!/bin/bash -e'], True)
    for idx, op in enumerate(op_list):
      if idx == len(op_list)-1: 
        tmp_list.append('./app.exe '+op+'.xclbin')
      else:
        tmp_list.append('./load.exe '+op+'.xclbin')

      # HW_exist, target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+op+'.h', 'map_target')
      # if target == 'RISCV':
      #   pass
      # else:
      #  tmp_list.append('./load.exe '+op+'.xclbin')

    # riscv_exist = False
    # for idx, op in enumerate(op_list):
    #  HW_exist, target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+op+'.h', 'map_target')
    #  if target == 'RISCV':
    #    riscv_exist = True
    #    tmp_list.append('./app.exe '+op+'.xclbin')
    # 
    # if riscv_exist == False:
    #  tmp_list.append('./app.exe '+op_list[0]+'.xclbin')
       

    self.shell.write_lines(self.bit_dir+ '/sd_card/run_app.sh', tmp_list, True)
 

