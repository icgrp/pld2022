# -*- coding: utf-8 -*-   

import os  
import subprocess
from gen_basic import gen_basic
import re
import syn 

class xclbin(gen_basic):

  # create one directory for each page 
  def create_page(self, operator, page_num):
    self.shell.cp_file('common/script_src/gen_xclbin_'+self.prflow_params['board']+'.sh', self.bit_dir+'/run_'+operator+'.sh')
    tmp_dict = {'bitstream=' : 'bitstream='+operator+'.bit',
                'xmlfile=' : 'xmlfile='+operator+'.xml',
                'source' : 'source '+self.prflow_params['Xilinx_dir'],
                'xclbin=': 'xclbin='+operator+'.xclbin'}
    self.shell.replace_lines(self.bit_dir+'/run_'+operator+'.sh', tmp_dict)
    self.shell.cp_file('common/metadata/'+self.prflow_params['board']+'/ydma.xml', self.bit_dir+'/'+operator+'.xml')
    self.shell.cp_file('./common/overlay/dynamic_region.xclbin', self.bit_dir)
    os.system('chmod +x '+self.bit_dir+'/run_'+operator+'.sh')
    self.shell.write_lines(self.bit_dir+'/main_'+operator+'.sh', self.shell.return_main_sh_list(
                                                                                                  './run_'+operator+'.sh', 
                                                                                                  self.prflow_params['back_end'], 
                                                                                                  'impl_'+operator, 
                                                                                                  'xclbin_'+operator, 
                                                                                                  self.prflow_params['grid'], 
                                                                                                  'qsub@qsub.com',
                                                                                                  self.prflow_params['mem'], 
                                                                                                  self.prflow_params['node'], 
                                                                                                   ), True)
 
    #self.shell.re_mkdir(self.bit_dir+'/'+operator)
    ## self.shell.write_lines(self.pr_dir+'/'+operator+'/impl_'+operator+'.tcl', self.tcl.return_impl_tcl_list(operator, page_num, 'p_'+str(page_num)+'.dcp', False))
    #self.shell.cp_file('./common/script_src/impl_page.tcl', self.pr_dir+'/'+operator+'/impl_'+operator+'.tcl')
    #tmp_dict = {'set page_num'                : 'set page_num '+str(page_num),
    #            'set operator'                : 'set operator '+operator,
    #            'set benchmark'               : 'set benchmark '+self.prflow_params['benchmark_name'],
    #            'set_property SCOPED_TO_CELLS': 'set_property SCOPED_TO_CELLS { level0_i/ulp/ydma_1/inst/page'+str(page_num)+'_inst } [get_files $page_dcp]',
    #            'link_design -mode default': 'link_design -mode default -reconfig_partitions { level0_i/ulp/ydma_1/inst/page'+str(page_num)+'_inst } -part $part -top level0_wrapper'}
    #self.shell.cp_dir('./common/constraints/'+self.prflow_params['board']+'/*', self.pr_dir+'/'+operator)
    #self.shell.mkdir(self.pr_dir+'/'+operator+'/output')
    #self.shell.replace_lines(self.pr_dir+'/'+operator+'/impl_'+operator+'.tcl', tmp_dict)
    #self.shell.write_lines(self.pr_dir+'/'+operator+'/run.sh', self.shell.return_run_sh_list(self.prflow_params['Xilinx_dir'], 'impl_'+operator+'.tcl', self.prflow_params['back_end']), True)
    #self.shell.write_lines(self.pr_dir+'/'+operator+'/main.sh', self.shell.return_main_sh_list(
    #                                                                                              './run.sh', 
    #                                                                                              self.prflow_params['back_end'], 
    #                                                                                              'syn_'+operator, 
    #                                                                                              'impl_'+operator, 
    #                                                                                              self.prflow_params['grid'], 
    #                                                                                              'qsub@qsub.com',
    #                                                                                              self.prflow_params['mem'], 
    #                                                                                              self.prflow_params['node'], 
    #                                                                                               ), True)
 


    #map_target_exist, map_target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'map_target')
    #if map_target == 'RISCV':
    #  syn_inst = syn.syn(self.prflow_params)
    #  map_target, page_num, input_num, output_num =  syn_inst.return_map_target(operator)
    #  debug_exist, debug_port = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'debug_port')
    #  if(debug_exist): output_num = output_num+1
    #  if map_target == 'RISCV':  inst_mem_exist, inst_mem_size = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'inst_mem_size')
    #  is_triple = 0
    #  if inst_mem_exist == False:
    #    inst_mem_size = 16384 
    #  else:
    #    is_triple, inst_mem_size = syn_inst.ceiling_mem_size(inst_mem_size)

    #  riscv_bit = 'empty'
    #  for i in range(int(input_num), 6):
    #    for j in range(int(output_num), 6):
    #      if os.path.exists(self.overlay_dir+'/riscv_bit_lib/page'+page_num+'_'+str(inst_mem_size/2048)+'bramI'+str(i)+'O'+str(j)+'.bit'):
    #        riscv_bit = self.overlay_dir+'/riscv_bit_lib/page'+page_num+'_'+str(inst_mem_size/2048)+'bramI'+str(i)+'O'+str(j)+'.bit'
    #        break
 
    #  print riscv_bit
    #  if riscv_bit == 'empty':
    #    self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh',\
    #                            {'vivado': 'vivado -mode batch -source impl_'+operator+'.tcl\ncp ../../F005_bits_'\
    #                            +self.prflow_params['benchmark_name']+'/'+operator+'.bit ../../F001_overlay/riscv_bit_lib/page'\
    #                            +page_num+'_'+str(inst_mem_size/2048)+'bram'+'I'+str(input_num)+'O'+str(output_num)+'.bit\n' })
    #  else:
    #    self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'touch ../../F005_bits_'+self.prflow_params['benchmark_name']+'/'+operator+'.bit\nvivado'})
    #    self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo read_checkpoint: 0 seconds > runLogImpl_'+operator+'.log\nvivado'})
    #    self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo opt: 0 seconds >> runLogImpl_'+operator+'.log\nvivado'})
    #    self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo place: 0 seconds >> runLogImpl_'+operator+'.log\nvivado'})
    #    self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo route: 0 seconds >> runLogImpl_'+operator+'.log\nvivado'})
    #    self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo bit_gen: 0 seconds >> runLogImpl_'+operator+'.log\nvivado'})
    #    self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'cp ../../../'+riscv_bit+' ../../F005_bits_'+self.prflow_params['benchmark_name']+'/'+operator+'.bit' })
 
    #  os.system('chmod +x '+self.pr_dir+'/'+operator+'/run.sh')




  def create_shell_file(self):
  # local run:
  #   main.sh <- |_ execute each impl_page.tcl
  #
  # qsub run:
  #   qsub_main.sh <-|_ Qsubmit each qsub_run.sh <- impl_page.tcl
    pass   

  def run(self, operator):
    # mk work directory
    if self.prflow_params['gen_xclbin']==True:
      self.shell.mkdir(self.bit_dir)
    
    # create ip directories for all the pages
    page_num_exist, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'page_num') 
    if page_num_exist==True:
      self.create_page(operator, page_num)

