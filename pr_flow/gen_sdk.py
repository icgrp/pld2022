# -*- coding: utf-8 -*-   

import os  
import subprocess

class gen_sdk:
  def __init__(self, prflow_params):
    self.prflow_params = prflow_params
    self.static_dir = self.prflow_params['workspace']+'/F001_static_' + self.prflow_params['nl'] + '_leaves'
    self.sdk_dir  = self.prflow_params['workspace']+'/F006_sdk'
    self.prflow_params = prflow_params



  def modify_parameters(self):

    #uncomment the leaf logic
    leaf_file_src = open(self.static_dir + '/src/leaf_empty.v', 'r')
    leaf_file_dst = open(self.sdk_dir+'/src/leaf_empty.v', 'w')
    for line in  leaf_file_src:
      if line.startswith('/*') or line.startswith("*/"):
        pass
      else:
        leaf_file_dst.write(line)
    leaf_file_src.close()
    leaf_file_dst.close()
    # Make the PR xdc files to empty
    xdc_file = open(self.sdk_dir+'/src/pblocks_' + self.prflow_params['nl'] + '.xdc', 'w')
    xdc_file.close()


  def project_syn_impl_gen(self):

    #open project_syn_impl.tcl
    tcl_file_dst = open(self.sdk_dir+'/project_syn_impl.tcl', 'w')
    tcl_file_dst.write('open_project ./prj/floorplan_static.xpr\n')
    tcl_file_dst.write('reset_run synth_1\n')
    tcl_file_dst.write('launch_runs synth_1\n')
    tcl_file_dst.write('wait_on_run synth_1\n')
    tcl_file_dst.write('launch_runs impl_1 -to_step write_bitstream\n')
    tcl_file_dst.write('wait_on_run impl_1\n')
    tcl_file_dst.write('file mkdir ./prj/floorplan_static.sdk\n')
    tcl_file_dst.write('file copy -force ./prj/floorplan_static.runs/impl_1/floorplan_static_wrapper.sysdef ./prj/floorplan_static.sdk/floorplan_static_wrapper.hdf\n')
    tcl_file_dst.close()


  def project_syn_gen_gen(self):
    os.system('cp ./input_files/script_src/project_syn_gen_'+self.prflow_params['board']+'.tcl ' + self.sdk_dir +'/project_syn_gen.tcl')

  def sdk_gen(self):
    os.system('rm -rf ' + self.sdk_dir)
    os.system('mkdir ' + self.sdk_dir)

    #generate the tcl for project construction
    self.project_syn_gen_gen()
    #generate the tcl for project implementation after the sub-moudle synthesis
    self.project_syn_impl_gen()
    
 

    os.system('cp -rf ' + self.static_dir + '/src ' + self.sdk_dir)
    #fill in the empty leaf with some logic
    #self.modify_parameters()

    #make the sh and files for implementation
    mk_file=open('./' + self.sdk_dir + '/run.sh', 'w')
    mk_file.write('#!/bin/bash -e\n')
    mk_file.write('source ' + self.prflow_params['Xilinx_dir'] + '\n')
    mk_file.write('vivado -mode batch -source project_syn_gen.tcl\n')
    mk_file.write('vivado -mode batch -source project_syn_impl.tcl\n')
    mk_file.close()
    os.system('chmod +x ' + './' + self.sdk_dir + '/run.sh')

    mk_file=open('./' + self.sdk_dir + '/qsub_run.sh', 'w')
    mk_file.write('#!/bin/bash -e\n')
    mk_file.write('source ' + self.prflow_params['qsub_Xilinx_dir'] + '\n')
    mk_file.write('vivado -mode batch -source project_syn_gen.tcl\n')
    mk_file.close()
    os.system('chmod +x ' + './' + self.sdk_dir + '/qsub_run.sh')
    
    #this files can qsub each OoC tasks independently into icgrid
    mk_file=open('./' + self.sdk_dir + '/qsub_sub_syn.sh', 'w')
    mk_file.write('#!/bin/bash -e\n')
    mk_file.write('source ' + self.prflow_params['qsub_Xilinx_dir'] + '\n')
    mk_file.write('emailAddr="' + self.prflow_params['email'] + '"\n')
    mk_file.write('for file in $(ls ./prj/floorplan_static.runs)\n')
    mk_file.write('do\n')
    mk_file.write('    cd \'./prj/floorplan_static.runs/\'$file\n')
    mk_file.write('    qsub -N \'sdk_\'$file -q ' + self.prflow_params['qsub_grid'] + ' -m abe -M $emailAddr -l mem=8G  -cwd ./runme.sh\n')
    mk_file.write('    cd ../../../\n')
    mk_file.write('done\n')
    mk_file.write('file_list=\'synth_1\'\n')
    mk_file.write('for file in $(ls ./prj/floorplan_static.runs)\n')
    mk_file.write('do\n')
    mk_file.write('    file_list=$file_list\',sdk_\'$file\n')
    mk_file.write('done\n')
    mk_file.write('qsub -N sdk_syn_impl -hold_jid $file_list -q ' + self.prflow_params['qsub_grid'] + ' -m abe -M $emailAddr -l mem=8G  -cwd ./qsub_syn_impl.sh\n')
    mk_file.close()
    os.system('chmod +x ' + './' + self.sdk_dir + '/qsub_sub_syn.sh')

    mk_file=open('./' + self.sdk_dir + '/qsub_syn_impl.sh', 'w')
    mk_file.write('#!/bin/bash -e\n')
    mk_file.write('source ' + self.prflow_params['qsub_Xilinx_dir'] + '\n')
    mk_file.write('vivado -mode batch -source project_syn_impl.tcl\n')
    mk_file.close()
    os.system('chmod +x ' + './' + self.sdk_dir + '/qsub_syn_impl.sh')


    mk_file=open('./' + self.sdk_dir + '/main.sh', 'w')
    mk_file.write('#!/bin/bash -e\n')
    mk_file.write('./run.sh\n')
    mk_file.close()
    os.system('chmod +x ' + './' + self.sdk_dir + '/main.sh')

    mk_file=open('./' + self.sdk_dir + '/qsub_main.sh', 'w')
    mk_file.write('#!/bin/bash -e\n')
    mk_file.write('emailAddr="'+ self.prflow_params['email']+'"\n')
    mk_file.write('qsub -N sdk_project_syn_gen -q ' + self.prflow_params['qsub_grid'] + ' -m abe -M $emailAddr -l mem=8G  -cwd ./qsub_run.sh\n')
    mk_file.write('qsub -N sdk_sub_syn -hold_jid sdk_project_syn_gen  -q ' + self.prflow_params['qsub_grid'] + ' -m abe -M $emailAddr -l mem=8G  -cwd ./qsub_sub_syn.sh\n')
    mk_file.close()
    os.system('chmod +x ' + './' + self.sdk_dir + '/qsub_main.sh')
    os.chdir('./' + self.sdk_dir)
    if self.prflow_params['run_qsub']:
       os.system('./qsub_main.sh')
    os.chdir('../..')



