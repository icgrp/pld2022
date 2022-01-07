# -*- coding: utf-8 -*-   
# Company: IC group, University of Pennsylvania
# Engineer: Yuanlong Xiao
#
# Create Date: 02/23/2021
# Design Name: overlay
# Project Name: DIRC
# Versions: 1.0
# Description: This is a python script to prepare the script for static region 
#              compile for PRflow.
# Dependencies: python2, gen_basic
# Revision:
# Revision 0.01 - File Created
#
# Additional Comments:


import os  
import subprocess
from gen_basic import gen_basic

class overlay(gen_basic):
  def __init__(self, prflow_params):
    gen_basic.__init__(self, prflow_params)

  # create dummy directory for each empty block
  def create_place_holder(self):
    fun_name = 'user_kernel'
    self.shell.mkdir(self.overlay_dir+'/dummy_repo')
    self.shell.mkdir(self.overlay_dir+'/dummy_repo/'+fun_name)
    file_list = [
                  '../../src/Config_Controls.v',
                  '../../src/converge_ctrl.v',
                  '../../src/ExtractCtrl.v',
                  '../../src/Input_Port_Cluster.v',
                  '../../src/Input_Port.v',
                  '../../src/leaf_interface.v',
                  '../../src/Output_Port_Cluster.v',
                  '../../src/Output_Port.v',
                  '../../src/read_b_in.v',
                  '../../src/Stream_Flow_Control.v',
                  '../../src/write_b_in.v',
                  '../../src/rise_detect.v',
                  '../../src/instr_config.v',
                  '../../src/write_b_out.v',
                  '../../src/user_kernel.v',
                  '../../src/picorv32_wrapper.v',
                  '../../src/picorv32.v',
                  '../../src/picorv_mem.v',
                  '../../src/xram2.v',
                  '../../src/xram_triple.v',
                  '../../src/riscv2consumer.v',
                  './leaf.v'
                ]
    self.shell.write_lines(self.overlay_dir+'/dummy_repo/'+fun_name+'/dummy.tcl', self.tcl.return_syn_page_tcl_list(fun_name, file_list))
    self.shell.write_lines(self.overlay_dir+'/dummy_repo/'+fun_name+'/run.sh',      self.shell.return_run_sh_list(self.prflow_params['Xilinx_dir'], 'dummy.tcl', self.prflow_params['back_end']), True)
    self.shell.write_lines(self.overlay_dir+'/dummy_repo/'+fun_name+'/'+'leaf.v', self.verilog.return_page_v_list(0, fun_name, 1, 1, True))
    
    # temporarily only copy the synthesis files for RISC-V core syntheis
    # We use this RISC-V post-syn dcp to pre-load somes pages.
    # When an operator is mapped to RISC-V, we can use the pre-compiled RISC-V, instead of re-compilation
    instr_mem_addr_width = [13, 14, 15]
    instr_mem_size = [32768, 65536, 131072]
    for index, i in enumerate([16, 32, 64]):
      file_list[-1] = './leaf_riscv.v'
      self.shell.re_mkdir(self.overlay_dir+'/dummy_repo/riscv_'+str(i)+'bramI5O5')
      self.shell.cp_dir(self.overlay_dir+'/src/leaf_riscv.v', self.overlay_dir+'/dummy_repo/riscv_'+str(i)+'bramI5O5')
      self.shell.write_lines(self.overlay_dir+'/dummy_repo/riscv_'+str(i)+'bramI5O5/dummy.tcl', self.tcl.return_syn_page_tcl_list(fun_name, file_list, 'leaf_riscv'))
      self.shell.write_lines(self.overlay_dir+'/dummy_repo/riscv_'+str(i)+'bramI5O5/run.sh',      self.shell.return_run_sh_list(self.prflow_params['Xilinx_dir'], 'dummy.tcl', self.prflow_params['back_end']), True)
      self.shell.replace_lines(self.overlay_dir+'/dummy_repo/riscv_'+str(i)+'bramI5O5/leaf_riscv.v', {'parameter MEM_SIZE': '    parameter MEM_SIZE = '+str(instr_mem_size[index])+';'})
      self.shell.replace_lines(self.overlay_dir+'/dummy_repo/riscv_'+str(i)+'bramI5O5/leaf_riscv.v', {'parameter ADDR_BITS': '    parameter ADDR_BITS = '+str(instr_mem_addr_width[index])+';'})
      self.shell.replace_lines(self.overlay_dir+'/dummy_repo/riscv_'+str(i)+'bramI5O5/leaf_riscv.v', {'.NUM_LEAF_BITS(': '.NUM_LEAF_BITS('+self.prflow_params['addr_bits']+'),'})


  # main.sh will be used for local compilation
  def return_main_sh_list_local(self):
    lines_list = []
    lines_list.append('#!/bin/bash -e')
    lines_list.append('cd ydma/'+self.prflow_params['board'])
    lines_list.append('./build.sh')
    lines_list.append('cd '+self.prflow_params['board']+'_dfx_manual')
    lines_list.append('source '+self.prflow_params['Xilinx_dir'])
    lines_list.append('make -j3')
    lines_list.append('cd ../../../')
    lines_list.append('cp ./ydma/'+self.prflow_params['board']+'/_x/link/int/ydma.xml ./dynamic_region.xml')
    lines_list.append('cp ./ydma/'+self.prflow_params['board']+'/_x/link/vivado/vpl/prj/prj.runs/impl_1/dynamic_region.bit ./')
    lines_list.append('./gen_xclbin_'+self.prflow_params['board']+'.sh dynamic_region.bit dynamic_region.xml dynamic_region.xclbin')
    return lines_list


  def create_tcl_shell_file(self):
  # local run:
  #   main.sh <- |_ vivado each dummy.tcl
  #              |_ vivado project_syn2gen.tcl
  #              |_ vivado project_syn2dcp.tcl
  #              |_ vivado mk_overlay.tcl

    # we use existed files instead
    # generating tcl file to create the overlay region vivado project
    # self.shell.cp_dir('./common/script_src/project_syn_gen_'+self.prflow_params['board']+'.tcl ', self.overlay_dir +'/project_syn2gen.tcl')

    # self.shell.write_lines(self.overlay_dir+'/project_syn2dcp.tcl', self.tcl.return_syn2dcp_tcl_list(self.prflow_params['back_end']), False)
    # self.shell.write_lines(self.overlay_dir+'/mk_overlay.tcl', self.tcl.return_mk_overlay_tcl_list(), False)
    self.shell.cp_file('./common/script_src/gen_xclbin_'+self.prflow_params['board']+'.sh ', self.overlay_dir)
    self.shell.write_lines(self.overlay_dir+'/run.sh', self.return_main_sh_list_local(), True)
    self.shell.write_lines(self.overlay_dir+'/main.sh', self.shell.return_main_sh_list(\
                                                       './run.sh', \
                                                       self.prflow_params['back_end'], \
                                                       'NONE',\
                                                       'overlay', \
                                                       self.prflow_params['grid'],  \
                                                       self.prflow_params['email'], \
                                                       self.prflow_params['mem'],  \
                                                       '8'), True)
                                                       #self.prflow_params['node']), True)

  def update_cad_path(self):
      self.shell.replace_lines(self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/build.sh', {'export ROOTFS'      : 'export ROOTFS='+self.prflow_params['ROOTFS']})
      self.shell.replace_lines(self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/build.sh', {'export PLATFORM_REPO_PATHS=': 'export PLATFORM_REPO_PATHS='+self.prflow_params['PLATFORM_REPO_PATHS']})
      self.shell.replace_lines(self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/build.sh', {'export PLATFORM='   : 'export PLATFORM='+self.prflow_params['PLATFORM']})
      self.shell.replace_lines(self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/build.sh', {'xrt_dir'            : 'source '+self.prflow_params['xrt_dir']})
      self.shell.replace_lines(self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/build.sh', {'sdk_dir'            : 'source '+self.prflow_params['sdk_dir']})
      self.shell.replace_lines(self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/build.sh', {'Xilinx_dir'         : 'source '+self.prflow_params['Xilinx_dir']})
      self.shell.replace_lines(self.overlay_dir+'/ydma/src/'+self.prflow_params['board']+'_dfx.cfg', {'platform'         : 'platform='+self.prflow_params['PLATFORM']})
      os.system('chmod +x '+self.overlay_dir+'/ydma/'+self.prflow_params['board']+'/build.sh')



  def run(self):
    # make work directory
    self.shell.mkdir(self.prflow_params['workspace'])
    self.shell.re_mkdir(self.overlay_dir)
    
    # copy the hld/xdc files from input source directory
    self.shell.del_dir(self.overlay_dir+'/src')
    self.shell.cp_dir('./common/verilog_src', self.overlay_dir+'/src')

    # copy the initial source files for vitis compile
    self.shell.cp_dir('./common/ydma', self.overlay_dir)
  
    # update the cad tool path
    self.update_cad_path()
 
    # copy the verilog file for the BFT from bft generate directory
    # self.shell.cp_file('./workspace/F000_bft_gen/gen_nw_vivado.v', self.overlay_dir+'/src')

    # create a bft wrapper
    # self.shell.write_lines(self.overlay_dir+'/src/bft.v', self.verilog.return_bft_wrapper_v_list(int(self.prflow_params['nl']), int(self.prflow_params['addr_bits']), int(self.prflow_params['packet_bits'])))

    # generate tcl and shell files for local run
    self.create_tcl_shell_file()

    # create dummy logic place and route the overlay.dcp
    self.create_place_holder()

    # create a folder to store the partial bitstreams for different versions of riscv
    # implementations for different pages
    self.shell.re_mkdir(self.overlay_dir+'/riscv_bit_lib')



