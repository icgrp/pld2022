# -*- coding: utf-8 -*-   

import os  
import subprocess
from gen_basic import gen_basic
class bit(gen_basic):
  #def __init__(self, prflow_params):
  #  self.prflow_params = prflow_params
  #  self.bits_dir = self.prflow_params['workspace']+'/F005_bits_'+self.prflow_params['benchmark_name']


  def run(self, operators):
    operator_list = operators.split()
    hw_operator_list = []
    for operator in operator_list:
      #if_HW, target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'map_target')
      #if (if_HW==True and target=='HW') or target == 'RISCV': hw_operator_list.append(operator)
      #if (if_HW==True and target=='HW'): 
      hw_operator_list.append(operator)
    self.shell.cp_dir(self.overlay_dir+'/main.bit', self.bit_dir)
    self.shell.write_lines(self.bit_dir+'/download.tcl', self.tcl.return_download_bit_tcl_list(hw_operator_list))
    self.shell.write_lines(self.bit_dir+'/qsub_run.sh', self.shell.return_run_sh_list(self.prflow_params['Xilinx_dir'], 'download.tcl'), True)
    self.shell.add_lines(self.bit_dir+'/qsub_run.sh', 'vivado', ['rm -rf ./vivado*'])
    os.system('chmod +x '+self.bit_dir+'/qsub_run.sh')
         
