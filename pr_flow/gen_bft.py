# -*- coding: utf-8 -*-   

import os  
import subprocess

class gen_bft:
  def __init__(self, prflow_params):
    self.prflow_params = prflow_params

  def bft_gen(self):
    #cp the bft src to workspace directory and then generate the bft verilog files.
    os.system('rm -rf '+self.prflow_params['workspace']+'/F000_bft_gen')
    os.system('cp -rf ./input_files/bft_src '+self.prflow_params['workspace']+'/F000_bft_gen')
    os.chdir(self.prflow_params['workspace']+'/F000_bft_gen')
    os.system('make clean')
    os.system('python3 network_tester.py -s -nl ' + self.prflow_params['nl']\
            + ' -p ' + self.prflow_params['p'] + ' -pks ' + self.prflow_params['pks'])
    os.chdir('../../')
































