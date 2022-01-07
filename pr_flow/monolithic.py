# -*- coding: utf-8 -*-   
# Company: IC group, University of Pennsylvania
# Engineer: Yuanlong Xiao
#
# Create Date: 12/18/2021
# Design Name: monolithic
# Project Name: PLD
# Versions: 1.0
# Description: This is a python script to prepare the script for static region 
#              compile for PRflow.
# Dependencies: python3, gen_basic
# Revision:
# Revision 0.01 - File Created
#
# Additional Comments:


import os  
import subprocess
from gen_basic import gen_basic
import re

class monolithic(gen_basic):
  def __init__(self, prflow_params):
    gen_basic.__init__(self, prflow_params)

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
    operator_width_dict = {}
    for operator in operator_list:
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
    return operator_arg_dict, operator_width_dict 


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
 

  def return_operator_connect_list_local(self, operator_arg_dict, operator_var_dict, operator_width_dict):
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
          tmp_str='DMA.Output_1->'+key_a+'.Input_1->512' 
          connection_list.append(tmp_str)
        if var_value_a == 'Input_2': 
          tmp_str='DMA2.Output_1->'+key_a+'.Input_1->512' 
          connection_list.append(tmp_str)
        if var_value_a == 'Output_1': 
          tmp_str=key_a+'.Output_1->'+'DMA.Input_1->512'
          connection_list.append(tmp_str)
        for key_b in operator_var_dict:
          for i_b, var_value_b in enumerate(operator_var_dict[key_b]):
            if var_value_a==var_value_b and key_a!=key_b:
              if self.shell.have_target_string(operator_arg_dict[key_a][i_a], 'Input'):
                tmp_str = operator_width_dict[key_b][i_b].replace('>','')
                tmp_str = tmp_str.replace('ap_uint<','->')
                tmp_str = key_b+'.'+operator_arg_dict[key_b][i_b]+'->'+key_a+'.'+operator_arg_dict[key_a][i_a]+tmp_str
              else:
                tmp_str = operator_width_dict[key_b][i_b].replace('>','')
                tmp_str = tmp_str.replace('ap_uint<','->')
                tmp_str = key_a+'.'+operator_arg_dict[key_a][i_a]+'->'+key_b+'.'+operator_arg_dict[key_b][i_b]+tmp_str
              connection_list.append(tmp_str)

    #connection_list = []
    #connection_list.append('DEBUG.Output_1->add1.Input_1')
    #connection_list.append('add1.Output_1->DEBUG.Input_1')
    #connection_list.append('add1.Output_2->DEBUG.Input_3')
    #connection_list.append('add1.Output_3->DEBUG.Input_3')
    #connection_list.append('add1.Output_5->DEBUG.Input_5')
    connection_list = set(connection_list)
    return connection_list


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


  def return_operator_inst_v_list(self, operator_arg_dict, connection_list, operator_var_dict, operator_width_dict):
    out_list = ['module mono(',
                '  input         ap_clk,',
                '  input         ap_rst_n,',
                '  input [511:0]  Input_1_V_TDATA,',
                '  input         Input_1_V_TVALID,',
                '  output        Input_1_V_TREADY,',
                '  output [511:0] Output_1_V_TDATA,',
                '  output        Output_1_V_TVALID,',
                '  input         Output_1_V_TREADY,',
                '  input         ap_start);']
    out_list.append('wire [511:0] DMA_Input_1_V_TDATA;')
    out_list.append('wire        DMA_Input_1_V_TVALID;')
    out_list.append('wire        DMA_Input_1_V_TREADY;')
    out_list.append('wire [511:0] DMA_Output_1_V_TDATA;')
    out_list.append('wire        DMA_Output_1_V_TVALID;')
    out_list.append('wire        DMA_Output_1_V_TREADY;')
 
    for op in operator_arg_dict:
      for idx, port in enumerate(operator_arg_dict[op]):
        width = int(operator_width_dict[op][idx].split('<')[1].split('>')[0])
        out_list.append('wire ['+str(width-1)+':0] '+op+'_'+port+'_V_TDATA;')
        out_list.append('wire        '+op+'_'+port+'_V_TVALID;')
        out_list.append('wire        '+op+'_'+port+'_V_TREADY;')
    for idx, connect_str in enumerate(connection_list):
      connect_str_list = connect_str.split('->')      
      out_list.append('\nstream_shell #(')
      out_list.append('  .PAYLOAD_BITS('+str(int(connect_str_list[2]))+'),')
      out_list.append('  .NUM_BRAM_ADDR_BITS(7)')
      out_list.append('  )stream_shell_'+str(idx)+'(')
      out_list.append('  .clk(ap_clk),')
      out_list.append('  .din('+connect_str_list[0].replace('.','_')+'_V_TDATA),')
      out_list.append('  .val_in('+connect_str_list[0].replace('.','_')+'_V_TVALID),')
      out_list.append('  .ready_upward('+connect_str_list[0].replace('.','_')+'_V_TREADY),')
      out_list.append('  .dout('+connect_str_list[1].replace('.','_')+'_V_TDATA),')
      out_list.append('  .val_out('+connect_str_list[1].replace('.','_')+'_V_TVALID),')
      out_list.append('  .ready_downward('+connect_str_list[1].replace('.','_')+'_V_TREADY),')
      out_list.append('  .reset(~ap_rst_n));')
    for op in operator_arg_dict:
      out_list.append('\n  '+op+' '+op+'_inst(')
      out_list.append('    .ap_clk(ap_clk),')
      out_list.append('    .ap_start(1\'b1),')
      out_list.append('    .ap_done(),')
      out_list.append('    .ap_idle(),')
      out_list.append('    .ap_ready(),')
      for port in operator_arg_dict[op]:
        out_list.append('    .'+port+'_V_TDATA(' +op+'_'+port+'_V_TDATA),')
        out_list.append('    .'+port+'_V_TVALID('+op+'_'+port+'_V_TVALID),')
        out_list.append('    .'+port+'_V_TREADY('+op+'_'+port+'_V_TREADY),')
      out_list.append('    .ap_rst_n(ap_rst_n)')
      out_list.append('  );')
    out_list.append('assign Output_1_V_TDATA  = DMA_Input_1_V_TDATA;')
    out_list.append('assign Output_1_V_TVALID = DMA_Input_1_V_TVALID;')
    out_list.append('assign DMA_Input_1_V_TREADY = Output_1_V_TREADY;')
    out_list.append('assign DMA_Output_1_V_TDATA  = Input_1_V_TDATA;')
    out_list.append('assign DMA_Output_1_V_TVALID = Input_1_V_TVALID;')
    out_list.append('assign Input_1_V_TREADY = DMA_Output_1_V_TREADY;')
    out_list.append('endmodule')
 
    return out_list

  def update_cad_path(self):
      self.shell.replace_lines(self.mono_dir+'/ydma/'+self.prflow_params['board']+'/build.sh',    {'export ROOTFS'              : 'export ROOTFS='+self.prflow_params['ROOTFS']})
      self.shell.replace_lines(self.mono_dir+'/ydma/'+self.prflow_params['board']+'/build.sh',    {'export PLATFORM_REPO_PATHS=': 'export PLATFORM_REPO_PATHS='+self.prflow_params['PLATFORM_REPO_PATHS']})
      self.shell.replace_lines(self.mono_dir+'/ydma/'+self.prflow_params['board']+'/build.sh',    {'export PLATFORM='           : 'export PLATFORM='+self.prflow_params['PLATFORM']})
      self.shell.replace_lines(self.mono_dir+'/ydma/'+self.prflow_params['board']+'/build.sh',    {'xrt_dir'                    : 'source '+self.prflow_params['xrt_dir']})
      self.shell.replace_lines(self.mono_dir+'/ydma/'+self.prflow_params['board']+'/build.sh',    {'sdk_dir'                    : 'source '+self.prflow_params['sdk_dir']})
      self.shell.replace_lines(self.mono_dir+'/ydma/'+self.prflow_params['board']+'/build.sh',    {'Xilinx_dir'                 : 'source '+self.prflow_params['Xilinx_dir']})
      self.shell.replace_lines(self.mono_dir+'/ydma/src/'+self.prflow_params['board']+'_dfx.cfg', {'platform'                   : 'platform='+self.prflow_params['PLATFORM']})

  def update_build_sh(self):
      cwd = os.getcwd()
      cwd = cwd.replace('/', '\/')
      cwd += '\/workspace\/F007_mono_'+self.prflow_params['benchmark_name']+'\/ydma\/'+self.prflow_params['board']
      str_line=''
      str_line+='make ydma.xo || true\n'
      str_line+='# abs_dir=$(pwd)\n'
      str_line+='python3 ./replace.py\n'
      str_line+='cp ./../../mono.v ./_x/ydma/ydma/ydma/solution/impl/ip/hdl/verilog/\n'
      str_line+='cp ./'+self.prflow_params['board']+'_dfx_manual/src4level2/ydma_bb/config_parser* ./_x/ydma/ydma/ydma/solution/impl/ip/hdl/verilog/\n'
      str_line+='cp ./'+self.prflow_params['board']+'_dfx_manual/src4level2/ydma_bb/data32to512* ./_x/ydma/ydma/ydma/solution/impl/ip/hdl/verilog\n'
      str_line+='cp ./'+self.prflow_params['board']+'_dfx_manual/src4level2/ydma_bb/stream_shell.v ./_x/ydma/ydma/ydma/solution/impl/ip/hdl/verilog\n'
      str_line+='cp ./../../../F002_hls_'+self.prflow_params['benchmark_name']+'/*/*/syn/verilog/*.v ./_x/ydma/ydma/ydma/solution/impl/ip/hdl/verilog\n'
      str_line+='cp ./../../../F002_hls_'+self.prflow_params['benchmark_name']+'/*/*/syn/verilog/*.dat ./_x/ydma/ydma/ydma/solution/impl/ip/hdl/verilog\n'
      str_line+='cp ./../../../F002_hls_'+self.prflow_params['benchmark_name']+'/*/*/syn/verilog/*.tcl ./_x/ydma/ydma/ydma/solution/impl/ip/subcore\n'
      str_line+='cd ./_x/ydma/ydma/ydma/solution/impl/ip/ \n'
      str_line+='sed -i \'s/set kernel_xo ""/set kernel_xo "'+cwd+'\/ydma.xo"/g\' run_ippack.tcl\n'
      str_line+='sed -i \'s/2201/2101/g\' run_ippack.tcl\n'
      str_line+='./pack.sh\n'
      str_line+='cd -\n'
      str_line+='make ydma.xclbin\n'
      str_line+='cp ./ydma.xclbin ../../\n'
      self.shell.replace_lines(self.mono_dir+'/ydma/'+self.prflow_params['board']+'/build.sh', {'make all': str_line}) 
      self.shell.replace_lines(self.mono_dir+'/ydma/'+self.prflow_params['board']+'/Makefile', {'kernel_frequency': '                 --kernel_frequency '+self.prflow_params['mono_freq_MHz']+' \\'}) 
      os.system('chmod +x '+self.mono_dir+'/ydma/'+self.prflow_params['board']+'/build.sh')

  # main.sh will be used for local compilation
  def return_main_sh_list_local(self, input_list):
    lines_list = []
    lines_list.append('#!/bin/bash -e')
    lines_list.extend(input_list)
    return lines_list



 
  def run(self, operators):
    # mk work directory
    if self.prflow_params['gen_monolithic']==True:
      self.shell.re_mkdir(self.mono_dir)

    # prepare the source for vitis monolithic run
    self.shell.cp_dir("./common/ydma", self.mono_dir) 

    self.shell.write_lines(self.mono_dir+'/run.sh',  self.return_main_sh_list_local(['cd ./ydma/'+self.prflow_params['board'], './build.sh']), True)
    self.shell.write_lines(self.mono_dir+'/main.sh', self.return_main_sh_list_local(['./run.sh']), True)


    self.update_cad_path()
    self.update_build_sh() 

    page_num_dict = self.return_page_num_dict_local(operators)
    operator_arg_dict, operator_width_dict = self.return_operator_io_argument_dict_local(operators)
    operator_var_dict = self.return_operator_inst_dict_local(operators)
    connection_list=self.return_operator_connect_list_local(operator_arg_dict, operator_var_dict, operator_width_dict)
    mono_v_list = self.return_operator_inst_v_list(operator_arg_dict, connection_list, operator_var_dict, operator_width_dict)
    self.shell.write_lines(self.mono_dir+'/mono.v', mono_v_list)

