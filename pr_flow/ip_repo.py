import os  
import subprocess
from gen_basic import gen_basic
import re

class ip_repo(gen_basic):
  def return_io_num(self, io_pattern, file_list):
    max_num = 0
    for line in file_list:
      num_list = re.findall(r""+io_pattern+"\d*", line)
      if(len(num_list)>0 and int(num_list[0].replace(io_pattern,''))): max_num = int(num_list[0].replace(io_pattern,''))
    return max_num


  # create ip directory for each page 
  def create_ip(self, operator):
    src_list = self.shell.file_to_list('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h')
    input_num = self.return_io_num('Input_', src_list)
    output_num = self.return_io_num('Output_', src_list)
    HW, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+operator+'.h', 'page_num') 
    num_bram_addr_bits =int(self.prflow_params['bram_addr_bits'])
    self.shell.re_mkdir(self.mono_bft_dir+'/ip_repo/'+operator)
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
              '../../src/instr_config.v',
              '../../src/rise_detect.v',
              '../../src/write_b_out.v',
              '../../src/user_kernel.v',
    ]
    self.shell.write_lines(self.mono_bft_dir+'/ip_repo/'+operator+'/ip_page.tcl', self.tcl.return_ip_page_tcl_list(operator, page_num, file_list))
    self.shell.write_lines(self.mono_bft_dir+'/ip_repo/'+operator+'/run.sh',      self.shell.return_run_sh_list(self.prflow_params['Xilinx_dir'], 'ip_page.tcl'), True)
    self.shell.write_lines(self.mono_bft_dir+'/ip_repo/'+operator+'/qsub_run.sh', self.shell.return_run_sh_list(self.prflow_params['Xilinx_dir'], 'ip_page.tcl'), True)
    self.shell.write_lines(self.mono_bft_dir+'/ip_repo/'+operator+'/leaf_'+str(page_num)+'.v', self.verilog.return_page_v_list(page_num, operator, input_num, output_num), True)



  def run(self, operator):
    # mk work directory
    self.shell.mkdir(self.mono_bft_dir)
    
    # copy the hld/xdc files from static dirctory
    self.shell.cp_dir(self.overlay_dir + '/src ', self.mono_bft_dir)

    # create ip directories for all the pages
    self.create_ip(operator)



