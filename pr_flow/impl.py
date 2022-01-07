# -*- coding: utf-8 -*-   

import os  
import subprocess
from gen_basic import gen_basic
import re
import syn 

class impl(gen_basic):

  # create one directory for each page 
  def create_page(self, operator, page_num):
    self.shell.re_mkdir(self.pr_dir+'/'+operator)
    # self.shell.write_lines(self.pr_dir+'/'+operator+'/impl_'+operator+'.tcl', self.tcl.return_impl_tcl_list(operator, page_num, 'p_'+str(page_num)+'.dcp', False))
    self.shell.cp_file('./common/script_src/impl_page_'+self.prflow_params['board']+'.tcl', self.pr_dir+'/'+operator+'/impl_'+operator+'.tcl')
    tmp_dict = {'set page_num'                : 'set page_num '+str(page_num),
                'set operator'                : 'set operator '+operator,
                'set part'                    : 'set part '+self.prflow_params['part'],
                'set benchmark'               : 'set benchmark '+self.prflow_params['benchmark_name'],
                'set_property SCOPED_TO_CELLS': '',
                'CELL_ANCHOR'                 : 'set_property SCOPED_TO_CELLS { '+self.prflow_params['inst_name']+'/page'+str(page_num)+'_inst } [get_files $page_dcp]',
                'set inst_name'               : 'set inst_name "'+self.prflow_params['inst_name']+'/${page_name}_inst"',
                'set context_dcp'             : 'set context_dcp "../../F001_overlay/ydma/'+self.prflow_params['board']+'/'+self.prflow_params['board']+'_dfx_manual/checkpoint/p_${page_num}.dcp"',
                'link_design'                 : 'link_design -mode default -reconfig_partitions { '+self.prflow_params['inst_name']+'/page'+str(page_num)+'_inst } -part $part -top '+self.prflow_params['top_name']}
    self.shell.cp_dir('./common/constraints/'+self.prflow_params['board']+'/*', self.pr_dir+'/'+operator)
    self.shell.mkdir(self.pr_dir+'/'+operator+'/output')
    os.system('touch '+self.pr_dir+'/'+operator+'/output/_user_impl_clk.xdc')
    self.shell.replace_lines(self.pr_dir+'/'+operator+'/impl_'+operator+'.tcl', tmp_dict)
    self.shell.write_lines(self.pr_dir+'/'+operator+'/run.sh', self.shell.return_run_sh_list(self.prflow_params['Xilinx_dir'], 'impl_'+operator+'.tcl', self.prflow_params['back_end']), True)
    self.shell.write_lines(self.pr_dir+'/'+operator+'/main.sh', self.shell.return_main_sh_list(
                                                                                                  './run.sh', 
                                                                                                  self.prflow_params['back_end'], 
                                                                                                  'syn_'+operator, 
                                                                                                  'impl_'+operator, 
                                                                                                  self.prflow_params['grid'], 
                                                                                                  'qsub@qsub.com',
                                                                                                  self.prflow_params['mem'], 
                                                                                                  self.prflow_params['node'], 
                                                                                                   ), True)
 


    map_target_exist, map_target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'map_target')
    if map_target == 'RISCV':
      syn_inst = syn.syn(self.prflow_params)
      map_target, page_num, input_num, output_num =  syn_inst.return_map_target(operator)
      debug_exist, debug_port = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'debug_port')
      if(debug_exist): output_num = output_num+1
      if map_target == 'RISCV':  inst_mem_exist, inst_mem_size = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'inst_mem_size')
      is_triple = 0
      if inst_mem_exist == False:
        inst_mem_size = 16384 
      else:
        is_triple, inst_mem_size = syn_inst.ceiling_mem_size(inst_mem_size)

      riscv_bit = 'empty'
      for i in range(int(input_num), 6):
        for j in range(int(output_num), 6):
          if os.path.exists(self.overlay_dir+'/riscv_bit_lib/page'+page_num+'_'+str(inst_mem_size/2048)+'bramI'+str(i)+'O'+str(j)+'.bit'):
            riscv_bit = self.overlay_dir+'/riscv_bit_lib/page'+page_num+'_'+str(inst_mem_size/2048)+'bramI'+str(i)+'O'+str(j)+'.bit'
            break
 
      print riscv_bit
      if riscv_bit == 'empty':
        self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh',\
                                {'vivado': 'vivado -mode batch -source impl_'+operator+'.tcl\n# cp ../../F005_bits_'\
                                +self.prflow_params['benchmark_name']+'/'+operator+'.bit ../../F001_overlay/riscv_bit_lib/page'\
                                +page_num+'_'+str(inst_mem_size/2048)+'bram'+'I'+str(input_num)+'O'+str(output_num)+'.bit\n' })
      else:
        self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'touch ../../F005_bits_'+self.prflow_params['benchmark_name']+'/'+operator+'.bit\nvivado'})
        self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo read_checkpoint: 0 seconds > runLogImpl_'+operator+'.log\nvivado'})
        self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo opt: 0 seconds >> runLogImpl_'+operator+'.log\nvivado'})
        self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo place: 0 seconds >> runLogImpl_'+operator+'.log\nvivado'})
        self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo route: 0 seconds >> runLogImpl_'+operator+'.log\nvivado'})
        self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'echo bit_gen: 0 seconds >> runLogImpl_'+operator+'.log\nvivado'})
        self.shell.replace_lines(self.pr_dir+'/'+operator+'/run.sh', {'vivado': 'cp ../../../'+riscv_bit+' ../../F005_bits_'+self.prflow_params['benchmark_name']+'/'+operator+'.bit' })
 
      os.system('chmod +x '+self.pr_dir+'/'+operator+'/run.sh')




  def create_shell_file(self):
  # local run:
  #   main.sh <- |_ execute each impl_page.tcl
  #
  # qsub run:
  #   qsub_main.sh <-|_ Qsubmit each qsub_run.sh <- impl_page.tcl
    pass   

  def run(self, operator):
    # mk work directory
    if self.prflow_params['gen_impl']==True:
      print "gen_impl"
      self.shell.mkdir(self.pr_dir)
      self.shell.mkdir(self.bit_dir)
    
    # generate shell files for qsub run and local run
    #self.create_shell_file() 

    # create ip directories for all the pages
    page_num_exist, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'page_num') 
    if page_num_exist==True:
      self.create_page(operator, page_num)

