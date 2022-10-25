# -*- coding: utf-8 -*-


import os
import subprocess
import xml.etree.ElementTree
import re




class _shell:
  def __init__(self, prflow_params):
    self.prflow_params = prflow_params


  def have_target_string(self, string_in, target_string):
    if string_in.replace(target_string, '') == string_in:
      return False
    else:
      return True
      
  def file_to_list(self, file_name):
    file_list = []
    file_in = open(file_name, 'r')
    for line in file_in:
      file_list.append(line.replace('\n',''))
    return file_list

  # return the qsub command according to the input parameters
  def return_qsub_command_str(self, shell_file='./qsub_run', hold_jid='NONE', name='NONE', q='70s', email='qsub@qsub.com', MEM='2G', node_num='1'):
    return ('qsub -N '+name + ' -q ' + q + ' -hold_jid ' + hold_jid + ' -m abe -M ' + email + ' -l mem='+MEM + ' -pe onenode '+node_num + '  -cwd '+ shell_file)

  # return the slurm command according to the input parameters
  def return_slurm_command_str(self, shell_file='./qsub_run', hold_jid='NONE', name='NONE', q='70s', email='qsub@qsub.com', MEM='2G', node_num='1'):
    return ('sbatch --ntasks=1 --cpus-per-task='+node_num+' --mem-per-cpu='+MEM+' --job-name='+name+' --dependency=$(squeue --noheader --format %i --user=$USER --name '+hold_jid+'| sed -n -e \'H;${x;s/\\n/,/g;s/^,//;p;}\') '+shell_file)


  def get_file_name(self, file_dir):
  # return a file list under a file_dir
    for root, dirs, files in os.walk(file_dir):
      return files

  def replace_lines(self, filename, modification_dict):
  # change the string(key of modification_dict) to
  # target string (value of modification_dict)
    try:
      file_in =  open(filename, 'r')
      file_out = open(filename+'tmp', 'w')
      for line in file_in:
        find_target = False
        for key, value in modification_dict.items():
          if line.replace(key, '') != line:
            file_out.write(value+'\n')
            find_target = True
            break
        if find_target == False:
          file_out.write(line)
      file_out.close()
      file_in.close()
      os.system('mv '+filename+'tmp '+filename)
    except:
      print ("Modification for "+filename+" failed!")

  def add_lines(self, filename, anchor, lines_list):
  # add more lines in a file according to
  # some anchor string
    try:
      file_in =  open(filename, 'r')
      file_out = open(filename+'tmp', 'w')
      for line in file_in:
        if line.replace(anchor, '') != line:
          file_out.write('\n'.join(lines_list)+'\n')
        file_out.write(line)
      file_out.close()
      file_in.close()
      os.system('mv '+filename+'tmp '+filename)
    except:
      print ("Adding more line in "+filename+" failed!")

  def write_lines(self, filename, lines_list, executable=False, write_or_add='w'):
    try:
      file_out = open(filename, write_or_add)
      file_out.write('\n'.join(lines_list)+'\n')
      file_out.close()
      if executable == True:
         os.system('chmod +x ' + filename)
    except:
      print ("Writing "+filename+" failed!")

  def re_mkdir(self, dir_name):
     os.system('rm -rf ' + dir_name)
     os.system('mkdir -p ' + dir_name)

  def mkdir(self, dir_name):
     os.system('mkdir -p ' + dir_name)

  def del_dir(self, dir_name):
     os.system('rm -rf ' + dir_name)

  def cp_dir(self, src_dir, dst_dir):
     os.system('cp -rf '+src_dir+' '+dst_dir)

  def cp_file(self, src_file, dst_file):
     os.system('cp -rf '+src_file+' '+dst_file)

  def return_run_sh_list(self, vivado_dir, tcl_file, back_end='qsub'):
    out_file = []
    out_file.append('#!/bin/bash -e')
    if (back_end == 'slurm'):
      # out_file.append('module load ' + vivado_dir)
      out_file.append('source ' + vivado_dir)
      out_file.append('srun vivado -mode batch -source  ' + tcl_file)
    else:
      out_file.append('source ' + vivado_dir)
      out_file.append('vivado -mode batch -source  ' + tcl_file)
    return out_file 


  def return_run_hls_sh_list(self, vivado_dir, tcl_file, back_end='qsub'):
    out_file = []
    out_file.append('#!/bin/bash -e')
    if (back_end == 'slurm'):
      # out_file.append('module load ' + vivado_dir)
      out_file.append('source ' + vivado_dir)
      out_file.append('srun vitis_hls -f ' + tcl_file)
    else:
      out_file.append('source ' + vivado_dir)
      out_file.append('vitis_hls -f ' + tcl_file)
    return out_file 

  def return_main_sh_list(self, run_file='run.sh', back_end='qsub', hold_jid='NONE', name='NONE', q='70s', email='qsub@qsub.com', MEM='2G', node_num='1'):
    out_list = []
    out_list.append('#!/bin/bash -e')
    if back_end == 'qsub':
      out_list.append(self.return_qsub_command_str(run_file, hold_jid, name, q, email, MEM, node_num))
    elif back_end == 'slurm':
      out_list.append(self.return_slurm_command_str(run_file, hold_jid, name, q, email, MEM, node_num))
    else:
      out_list.append(run_file)
    return (out_list)

  def return_empty_sh_list(self):
    return ([
      '#!/bin/bash -e',
      ''])


  def return_qsub_scan_sh_list(self, scan_dir, run_shell='qsub_run.sh', hold_prefix='hls_', name_prefix='mono_bft_'):
    return ([
      '#!/bin/bash -e',
      'source ' + self.prflow_params['Xilinx_dir'],
      'emailAddr="' + self.prflow_params['email'] + '"',
      'file_list=\'dummy\'',
      'for file in $(ls '+scan_dir+')',
      'do',
      '  if [ "$file" != "synth_1" ]; then',
      '    file_list=$file_list\','+name_prefix+'\'$file',
      '    cd \''+scan_dir+'/\'$file',
      '    qsub  -hold_jid '+hold_prefix+'$file -N '+name_prefix+'$file -q ' + self.prflow_params['grid'] + ' -m abe -M $emailAddr -l mem=8G  -cwd ./'+run_shell,
      '    cd -',
      '  fi',
      'done',
      ''])


class _pragma(_shell):
  def return_pragma(self, file_name, pragma_name, pragma_object=''):
    src_list = self.file_to_list(file_name)
    if_exist = False
    value = 0
    for line in src_list:
      if(line.replace("#pragma", "") != line):
        if(len(re.findall(r""+pragma_name+"\s*=\s*\w*", line)) > 0):
          if_exist = True
          value = re.findall(r""+pragma_name+"\s*=\s*\w*", line)[0]
          value = value.replace(' ', '')
          value = value.replace(pragma_name, '')
          value = value.replace('=', '')
    return if_exist, value 
 
class _verilog:
  def __init__(self, prflow_params):
    self.prflow_params = prflow_params
    pass

  def return_idx_in_list_local(self, in_list, ele):
    print(ele, in_list)
    for idx, val in enumerate(in_list):
      if val == ele:
        return idx
    return 'NONE'


  def my_max(self, a, b):
    if(a>b): return a
    else: return b

  def return_page_v_list(self, 
                         page_num, 
                         fun_name,
                         input_num,
                         output_num,
                         operator_arg_list,
                         operator_width_list,
                         for_syn=False,
                         is_riscv=False,
                         PAYLOAD_BITS=None,
                         PACKET_BITS=None,
                         NUM_LEAF_BITS=None,
                         NUM_PORT_BITS=None,
                         NUM_ADDR_BITS=None,
                         NUM_BRAM_ADDR_BITS=None,
                         FREESPACE_UPDATE_SIZE=None
                         ):
    PAYLOAD_BITS=self.prflow_params['payload_bits'] if PAYLOAD_BITS == None else PAYLOAD_BITS
    PACKET_BITS=self.prflow_params['packet_bits'] if PACKET_BITS == None else PACKET_BITS
    NUM_LEAF_BITS=self.prflow_params['addr_bits'] if NUM_LEAF_BITS == None  else NUM_LEAF_BITS
    NUM_PORT_BITS=self.prflow_params['port_bits'] if NUM_PORT_BITS == None  else NUM_PORT_BITS
    NUM_ADDR_BITS=self.prflow_params['bram_addr_bits'] if NUM_ADDR_BITS == None else NUM_ADDR_BITS
    NUM_BRAM_ADDR_BITS=self.prflow_params['bram_addr_bits'] if NUM_BRAM_ADDR_BITS == None else NUM_BRAM_ADDR_BITS
    FREESPACE_UPDATE_SIZE=self.prflow_params['freespace'] if FREESPACE_UPDATE_SIZE == None  else FREESPACE_UPDATE_SIZE
 
    lines_list = []
    lines_list.append('`timescale 1ns / 1ps')
    if for_syn:
      lines_list.append('module leaf(')
    else:
      lines_list.append('module leaf_'+str(page_num)+'(')

    lines_list.append('    input wire clk,')
    lines_list.append('    input wire ['+str(PACKET_BITS)+'-1 : 0] din_leaf_bft2interface,')
    lines_list.append('    output wire ['+str(PACKET_BITS)+'-1 : 0] dout_leaf_interface2bft,')
    lines_list.append('    input wire resend,')
    # lines_list.append('    input wire ap_start,')
    lines_list.append('    input wire reset')
    lines_list.append('    );')
    lines_list.append('')
  
    lines_list.append('    wire [23:0] riscv_addr;')
    lines_list.append('    wire [7:0] riscv_dout;')
    lines_list.append('    wire instr_wr_en_out;')
    lines_list.append('    wire ap_start;')
     
    dout_list = []
    val_out_list = [] 
    ack_out_list = []
    for i in range(self.my_max(1, int(input_num)),0,-1): 
      if int(input_num) != 0:
        WIDTH = operator_width_list[self.return_idx_in_list_local(operator_arg_list, 'Input_'+str(i))].split('<')[1].split('>')[0]
      else:
        WIDTH = 32
      lines_list.append('    wire ['+str(PAYLOAD_BITS)+'-1 :0] dout_leaf_interface2user_'+str(i)+';')
      lines_list.append('    wire vld_interface2user_'+str(i)+';')
      lines_list.append('    wire ack_user2interface_'+str(i)+';')
      if is_riscv == True: 
        lines_list.append('    wire ['+str(PAYLOAD_BITS)+'-1 :0] dout_leaf_interface2user_'+str(i)+'_user;')
      else:
        lines_list.append('    wire ['+str(WIDTH)+'-1 :0] dout_leaf_interface2user_'+str(i)+'_user;')

      lines_list.append('    wire vld_interface2user_'+str(i)+'_user;')
      lines_list.append('    wire ack_user2interface_'+str(i)+'_user;')
 
      if int(WIDTH) != 32 and is_riscv == False:    
         lines_list.append('    read_queue#(')
         lines_list.append('      .IN_WIDTH(32),')
         lines_list.append('      .OUT_WIDTH('+str(WIDTH)+')')
         lines_list.append('    )Input_'+str(i)+'_converter(')
         lines_list.append('      .clk(clk),')
         lines_list.append('      .reset(reset),')
         lines_list.append('      .din(dout_leaf_interface2user_'+str(i)+'),')
         lines_list.append('      .vld_in(vld_interface2user_'+str(i)+'),')
         lines_list.append('      .rdy_upward(ack_user2interface_'+str(i)+'),')
         lines_list.append('      .dout(dout_leaf_interface2user_'+str(i)+'_user),')
         lines_list.append('      .vld_out(vld_interface2user_'+str(i)+'_user),')
         lines_list.append('      .rdy_downward(ack_user2interface_'+str(i)+'_user)') 
         lines_list.append('    );')
      else:
         lines_list.append('    assign dout_leaf_interface2user_'+str(i)+'_user = dout_leaf_interface2user_'+str(i)+';')
         lines_list.append('    assign vld_interface2user_'+str(i)+'_user = vld_interface2user_'+str(i)+';')
         lines_list.append('    assign ack_user2interface_'+str(i)+' = ack_user2interface_'+str(i)+'_user;')


      dout_list.append('dout_leaf_interface2user_'+str(i))
      val_out_list.append('vld_interface2user_'+str(i))
      ack_out_list.append('ack_user2interface_'+str(i))
    dout_str='{'+','.join(dout_list)+'}'
    val_out_str='{'+','.join(val_out_list)+'}'
    ack_out_str='{'+','.join(ack_out_list)+'}'

    din_list = []
    val_in_list = [] 
    ack_in_list = []
    for i in range(int(output_num),0,-1): 
      WIDTH = operator_width_list[self.return_idx_in_list_local(operator_arg_list, 'Output_'+str(i))].split('<')[1].split('>')[0]
      lines_list.append('    wire ['+str(PAYLOAD_BITS)+'-1 :0] din_leaf_user2interface_'+str(i)+';')
      lines_list.append('    wire vld_user2interface_'+str(i)+';')
      lines_list.append('    wire ack_interface2user_'+str(i)+';')
      if is_riscv == True:
        lines_list.append('    wire ['+str(PAYLOAD_BITS)+'-1 :0] din_leaf_user2interface_'+str(i)+'_user;')
      else:
        lines_list.append('    wire ['+str(WIDTH)+'-1 :0] din_leaf_user2interface_'+str(i)+'_user;')
      lines_list.append('    wire vld_user2interface_'+str(i)+'_user;')
      lines_list.append('    wire ack_interface2user_'+str(i)+'_user;')

      if int(WIDTH) != 32 and is_riscv == False:    
         lines_list.append('    write_queue#(')
         lines_list.append('      .IN_WIDTH('+str(WIDTH)+'),')
         lines_list.append('      .OUT_WIDTH(32)')
         lines_list.append('    )Output_'+str(i)+'_converter(')
         lines_list.append('      .clk(clk),')
         lines_list.append('      .reset(reset),')
         lines_list.append('      .din(din_leaf_user2interface_'+str(i)+'_user),')
         lines_list.append('      .vld_in(vld_user2interface_'+str(i)+'_user),')
         lines_list.append('      .rdy_upward(ack_interface2user_'+str(i)+'_user),') 
         lines_list.append('      .dout(din_leaf_user2interface_'+str(i)+'),')
         lines_list.append('      .vld_out(vld_user2interface_'+str(i)+'),')
         lines_list.append('      .rdy_downward(ack_interface2user_'+str(i)+')')
         lines_list.append('    );')
      else:
         lines_list.append('    assign din_leaf_user2interface_'+str(i)+' = din_leaf_user2interface_'+str(i)+'_user;')
         lines_list.append('    assign vld_user2interface_'+str(i)+' = vld_user2interface_'+str(i)+'_user;')
         lines_list.append('    assign ack_interface2user_'+str(i)+'_user = ack_interface2user_'+str(i)+';')

      din_list.append('din_leaf_user2interface_'+str(i))
      val_in_list.append('vld_user2interface_'+str(i))
      ack_in_list.append('ack_interface2user_'+str(i))
    din_str='{'+','.join(din_list)+'}'
    val_in_str='{'+','.join(val_in_list)+'}'
    ack_in_str='{'+','.join(ack_in_list)+'}'


    if int(input_num) == 0: lines_list.append('    assign ack_user2interface_1_user = 0;')

    lines_list.append('    ')
    lines_list.append('    leaf_interface #(')
    lines_list.append('        .PACKET_BITS('+str(PACKET_BITS)+'),')
    lines_list.append('        .PAYLOAD_BITS('+str(PAYLOAD_BITS)+'),')
    lines_list.append('        .NUM_LEAF_BITS('+str(NUM_LEAF_BITS)+'),')
    lines_list.append('        .NUM_PORT_BITS('+str(NUM_PORT_BITS)+'),')
    lines_list.append('        .NUM_ADDR_BITS('+str(NUM_ADDR_BITS)+'),')
    lines_list.append('        .NUM_IN_PORTS('+str(self.my_max(1, input_num))+'),')
    lines_list.append('        .NUM_OUT_PORTS('+str(output_num)+'),')
    lines_list.append('        .NUM_BRAM_ADDR_BITS('+str(NUM_BRAM_ADDR_BITS)+'),')
    lines_list.append('        .FREESPACE_UPDATE_SIZE('+str(FREESPACE_UPDATE_SIZE)+')')
    lines_list.append('    )leaf_interface_inst(')
    lines_list.append('        .clk(clk),')
    lines_list.append('        .reset(reset),')
    lines_list.append('        .din_leaf_bft2interface(din_leaf_bft2interface),')
    lines_list.append('        .dout_leaf_interface2bft(dout_leaf_interface2bft),')
    lines_list.append('        .riscv_addr(riscv_addr),')
    lines_list.append('        .riscv_dout(riscv_dout),')
    lines_list.append('        .instr_wr_en_out(instr_wr_en_out),') 
    lines_list.append('        .ap_start(ap_start),') 
    lines_list.append('        .resend(resend),')
    lines_list.append('        .dout_leaf_interface2user('+dout_str+'),')
    lines_list.append('        .vld_interface2user('+val_out_str+'),')
    lines_list.append('        .ack_user2interface('+ack_out_str+'),')
    lines_list.append('        .ack_interface2user('+ack_in_str+'),')
    lines_list.append('        .vld_user2interface('+val_in_str+'),')
    lines_list.append('        .din_leaf_user2interface('+din_str+')')
    lines_list.append('    );')
    lines_list.append('    ')
    if is_riscv == True:
      lines_list.append('   picorv32_wrapper picorv32_wrapper_inst(')
      lines_list.append('       .clk(clk),')
      lines_list.append('       .instr_config_addr(riscv_addr),')
      lines_list.append('       .instr_config_din(riscv_dout),')
      lines_list.append('       .instr_config_wr_en(instr_wr_en_out),')
      for i in range(1, int(input_num)+1, 1):
        lines_list.append('       .din'+str(i)+'(dout_leaf_interface2user_'+str(i)+'_user),')
        lines_list.append('       .val_in'+str(i)+'(vld_interface2user_'+str(i)+'_user),')
        lines_list.append('       .ready_upward'+str(i)+'(ack_user2interface_'+str(i)+'_user),')
      for i in range(1, int(output_num)+1, 1):
        lines_list.append('       .dout'+str(i)+'(din_leaf_user2interface_'+str(i)+'_user),')
        lines_list.append('       .val_out'+str(i)+'(vld_user2interface_'+str(i)+'_user),')
        lines_list.append('       .ready_downward'+str(i)+'(ack_interface2user_'+str(i)+'_user),')
      for i in range(int(input_num)+1, 6, 1):
        lines_list.append('       .din'+str(i)+'(32\'d0),')
        lines_list.append('       .val_in'+str(i)+'(1\'d0),')
      for i in range(int(output_num)+1, 6, 1):
        lines_list.append('       .ready_downward'+str(i)+'(1\'d0),')
      lines_list.append('       .resetn(ap_start&(!reset))')
      # lines_list.append('       .resetn((!reset))')
      lines_list.append('       );') 
    else:
      lines_list.append('    '+fun_name+' '+fun_name+'_inst(')
      lines_list.append('        .ap_clk(clk),')
      lines_list.append('        .ap_start(ap_start),')
      # lines_list.append('        .ap_start(1\'b1),')
      lines_list.append('        .ap_done(),')
      lines_list.append('        .ap_idle(),')
      lines_list.append('        .ap_ready(),')
      for i in range(int(input_num),0,-1): 
        lines_list.append('        .Input_'+str(i)+'_V_TDATA(dout_leaf_interface2user_'+str(i)+'_user),')
        lines_list.append('        .Input_'+str(i)+'_V_TVALID(vld_interface2user_'+str(i)+'_user),')
        lines_list.append('        .Input_'+str(i)+'_V_TREADY(ack_user2interface_'+str(i)+'_user),')
      for i in range(int(output_num),0,-1): 
        lines_list.append('        .Output_'+str(i)+'_V_TDATA(din_leaf_user2interface_'+str(i)+'_user),')
        lines_list.append('        .Output_'+str(i)+'_V_TVALID(vld_user2interface_'+str(i)+'_user),')
        lines_list.append('        .Output_'+str(i)+'_V_TREADY(ack_interface2user_'+str(i)+'_user),')
      lines_list.append('        .ap_rst_n(~reset)')
      lines_list.append('        );  ')
    lines_list.append('    ')
    lines_list.append('endmodule')

    return lines_list

class _tcl:
  def __init__(self, prflow_params):
    self.prflow_params = prflow_params

  def return_delete_bd_objs_tcl_str(self, obj_name):
    return('delete_bd_objs  [get_bd_cells '+obj_name+']')

  def return_change_parameter_tcl_str(self, cell_name, par_name, par_value):
    return('set_property -dict [list CONFIG.'+par_name+' {'+str(par_value)+'}] [get_bd_cells '+cell_name+']')

  def return_connect_bd_net_tcl_str(self, src_pin, dest_pin):
    return('connect_bd_net [get_bd_pins '+src_pin + '] [get_bd_pins '+dest_pin+']')

  def return_create_bd_cell_tcl_str(self, obj_name, inst_name, obj_type='ip'):
    return('create_bd_cell -type '+obj_type+' -vlnv '+obj_name+' ' + inst_name)

  def return_connect_bd_stream_tcl_list(self, src_name, dest_name, src_port_name='', dest_port_name=''):
    return([
      'connect_bd_net [get_bd_pins /'+src_name+'/'+src_port_name+'dout] [get_bd_pins /'+dest_name+'/'+dest_port_name+'din]',
      'connect_bd_net [get_bd_pins /'+src_name+'/'+src_port_name+'val_out] [get_bd_pins /'+dest_name+'/'+dest_port_name+'val_in]',
      'connect_bd_net [get_bd_pins /'+src_name+'/'+src_port_name+'ready_upward] [get_bd_pins /'+dest_name+'/'+dest_port_name+'ready_downward]',
      ''])

  def return_syn2bits_tcl_list(self, jobs=8, prj_dir='./prj/', prj_name = 'floorplan_static'):
    threads_num = subprocess.getoutput("nproc")
    return ([
      'open_project '+prj_dir+prj_name+'.xpr',
      'reset_run synth_1',
      'launch_runs synth_1 -jobs '+str(threads_num),
      'wait_on_run synth_1',
      'launch_runs impl_1 -to_step write_bitstream -jobs '+str(threads_num),
      'wait_on_run impl_1',
      'file mkdir '+prj_dir+prj_name+'.sdk',
      'write_hw_platform -fixed -include_bit -force -file ' + prj_dir + prj_name + '.sdk/floorplan_static_wrapper.xsa',
      ''])

  def return_syn2dcp_tcl_list(self, back_end = 'slurm', prj_dir='./prj/', prj_name = 'floorplan_static.xpr'):
    if back_end == 'slurm':
      threads_num = 8
    else:
      threads_num = commands.getoutput("nproc")
    return ([
      'open_project '+prj_dir+prj_name,
      'reset_run synth_1',
      'launch_runs synth_1 -jobs '+str(threads_num),
      'wait_on_run synth_1',
      'open_run synth_1 -name synth_1',
      'write_checkpoint -force floorplan_static.dcp',
      ''])


  def return_ip_page_tcl_list(self, fun_name, fun_num, file_list):
    lines_list = ['create_project floorplan_static ./prj -part '+self.prflow_params['part']]
    for file_name in file_list:
      lines_list.append('add_files -norecurse '+file_name)
     
    lines_list.extend([
     'set dir "../../../F002_hls_'+self.prflow_params['benchmark_name']  + '/' + fun_name + '_prj/' + fun_name + '/syn/verilog"',
      'set contents [glob -nocomplain -directory $dir *]',
      'foreach item $contents {',
      '  if { [regexp {.*\.tcl} $item] } {',
      '    source $item',
      '  } else {',
      '    add_files -norecurse $item',
      '  }',
      '}',
      'set_param general.maxThreads  8',
      'set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]',
      'add_files  -norecurse ./leaf_'+str(fun_num)+'.v',
      'ipx::package_project -root_dir ./prj/floorplan_static.srcs/sources_1 -vendor user.org -library user -taxonomy /UserIP',
      'set_property core_revision 2 [ipx::current_core]',
      'ipx::create_xgui_files [ipx::current_core]',
      'ipx::update_checksums [ipx::current_core]',
      'ipx::save_core [ipx::current_core]',
      'set_property  ip_repo_paths  ./prj/floorplan_static.srcs/sources_1 [current_project]',
      'update_ip_catalog',
      ''])
      
    return lines_list

  def return_syn_page_tcl_list(self, fun_name,  file_list, top_name='leaf'):
    #lines_list = ['create_project floorplan_static ./prj -part '+self.prflow_params['part']]
    lines_list = []
    for file_name in file_list:
      lines_list.append('add_files -norecurse '+file_name)
 
    lines_list.extend([
      #'set dir "../../F002_hls_'+self.prflow_params['benchmark_name']  + '/' + fun_name + '_prj/' + fun_name + '/syn/verilog"',
      'set dir "./src/"',
      'set contents [glob -nocomplain -directory $dir *]',
      'foreach item $contents {',
      '  if { [regexp {.*\.tcl} $item] } {',
      '    source $item',
      '  } else {',
      '    add_files -norecurse $item',
      '  }',
      '}',
      'set dir "../../F002_hls_'+self.prflow_params['benchmark_name']  + '/' + fun_name + '_prj/' + fun_name + '/syn/verilog"',
      'set contents [glob -nocomplain -directory $dir *]',
      'foreach item $contents {',
      '  if { [regexp {.*\.tcl} $item] } {',
      '    source $item',
      '  } else {',
      '    add_files -norecurse $item',
      '  }',
      '}',
 
      'set_param general.maxThreads  8',
      'set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]',
      'set logFileId [open ./runLog_'+fun_name+'.log "w"]',
      'set start_time [clock seconds]',
      'set_param general.maxThreads  8 ',
      'synth_design -top '+top_name+' -part '+self.prflow_params['part']+' -mode out_of_context',
      'write_checkpoint -force page_netlist.dcp',
      'set end_time [clock seconds]',
      'set total_seconds [expr $end_time - $start_time]',
      'puts $logFileId "syn: $total_seconds seconds"',
      'report_utilization -hierarchical > utilization.rpt',
      ''])
     
    return lines_list

  def get_file_name(self, file_dir):                                            
    for root, dirs, files in os.walk(file_dir):                                 
      return files  

  def return_hls_tcl_list(self, fun_name):
    lines_list = []
    lines_list.append('set logFileId [open ./runLog' + fun_name + '.log "w"]')
    lines_list.append('set_param general.maxThreads ' + self.prflow_params['maxThreads'] + ' ')
    lines_list.append('set start_time [clock seconds]')                     
    lines_list.append('open_project ' + fun_name + '_prj')                  
    lines_list.append('set_top ' + fun_name + '')                           
    lines_list.append('add_files ../../input_src/' + self.prflow_params['benchmark_name'] + '/operators/' + fun_name + '.cpp')
    lines_list.append('add_files ../../input_src/' + self.prflow_params['benchmark_name'] + '/host/typedefs.h')
    lines_list.append('open_solution "' +fun_name +'"')                     
    lines_list.append('set_part {'+self.prflow_params['part']+'}')          
    lines_list.append('create_clock -period '+self.prflow_params['clk_user']+' -name default')
    lines_list.append('#source "./Rendering_hls/colorFB/directives.tcl"')   
    lines_list.append('#csim_design')                                       
    lines_list.append('csynth_design')                                      
    lines_list.append('#cosim_design -trace_level all -tool xsim')          
    #if(fun_name == self.prflow_params['mono_function']):                      
    #  lines_list.append('export_design -rtl verilog -format ip_catalog')    
    #else:                                                                     
    lines_list.append('#export_design -rtl verilog -format ip_catalog')   
                                                                              
    lines_list.append('set end_time [clock seconds]')                       
    lines_list.append('set total_seconds [expr $end_time - $start_time]')   
    lines_list.append('puts $logFileId "hls: $total_seconds seconds"')      
    lines_list.append('')                                                     
    lines_list.append('exit')                                               

    return lines_list

  def return_hls_prj_list(self, fun_name):
    lines_list = []
    #generate project files for each function                                 
    #the reason is that one vivado project can only have on active hardware function
    #to be implemented                                                        
    lines_list.append('<project xmlns="com.autoesl.autopilot.project" name="' + fun_name + '_prj" top="'+ fun_name + '">')
    lines_list.append('    <includePaths/>')
    lines_list.append('    <libraryPaths/>')
    lines_list.append('    <Simulation>')
    lines_list.append('        <SimFlow askAgain="false" name="csim" csimMode="0" lastCsimMode="0"/>')
    lines_list.append('    </Simulation>')
    lines_list.append('    <files>')

    #capture all the files under operator dirctory
    lines_list.append('        <file name="../../input_src/' + self.prflow_params['benchmark_name'] + '/operators/' + fun_name + '.cpp " sc="0" tb="false" cflags=""/>')
    lines_list.append('        <file name="../../input_src/' + self.prflow_params['benchmark_name'] + '/host/typedefs.h" sc="0" tb="false" cflags=""/>')
    lines_list.append('    </files> ')
    lines_list.append('    <solutions>')
    lines_list.append('        <solution name="' + fun_name + '" status="active"/>')
    lines_list.append('    </solutions>')
    lines_list.append('</project>')

    return lines_list

  def return_impl_tcl_list(self, fun_name, num, overlay='overlay.dcp', IsNet=False):
    lines_list = []
    lines_list.append('set logFileId [open ./runLogImpl_'+fun_name+'.log "w"]')
    #lines_list.append('set_param general.maxThreads ' + self.prflow_params['maxThreads'] + ' ')
    lines_list.append('set_param general.maxThreads 2 ')
    lines_list.append('')
    lines_list.append('#####################')
    lines_list.append('## read_checkpoint ##')
    lines_list.append('#####################')
    lines_list.append('set start_time [clock seconds]')
    lines_list.append('open_checkpoint ../../F001_overlay/'+overlay)
    if IsNet:
      lines_list.append("update_design -cell floorplan_static_i/net" + str(num) + "/inst -black_box")
      lines_list.append("read_checkpoint -cell floorplan_static_i/net" + str(num) + "/inst ../../F003_syn_" + self.prflow_params['benchmark_name'] + '/net' + str(num) + "/net" + str(num) + "_netlist.dcp")
    else:
      lines_list.append("update_design -cell floorplan_static_i/leaf_empty_" + str(num) + "/inst -black_box -quiet")
      lines_list.append("read_checkpoint -cell floorplan_static_i/leaf_empty_" + str(num) + "/inst ../../F003_syn_" + self.prflow_params['benchmark_name'] + '/' + fun_name + "/page_netlist.dcp")
 
    lines_list.append("set end_time [clock seconds]")
    lines_list.append("set total_seconds [expr $end_time - $start_time]")
    lines_list.append('puts $logFileId "read_checkpoint: $total_seconds seconds"')
    lines_list.append("")
    lines_list.append("")

    lines_list.append("####################")
    lines_list.append("## implementation ##")
    lines_list.append("####################")
    lines_list.append("set start_time [clock seconds]")
    lines_list.append("#reset_timing ")
    lines_list.append("opt_design ")
    lines_list.append("set end_time [clock seconds]")
    lines_list.append("set total_seconds [expr $end_time - $start_time]")
    lines_list.append('puts $logFileId "opt: $total_seconds seconds"')
    lines_list.append("write_checkpoint  -force  "+ fun_name + "_opt.dcp")
    lines_list.append("")

    lines_list.append("set start_time [clock seconds]")
    if self.prflow_params['PR_mode'] == 'quick':
      lines_list.append("if { [catch {place_design -directive Quick } errmsg] } {")
    else:
      lines_list.append("if { [catch {place_design} errmsg] } {")
    lines_list.append("  puts $logFileId \"place: 99999 failed!\"")
    lines_list.append("}")

    lines_list.append("set end_time [clock seconds]")
    lines_list.append("set total_seconds [expr $end_time - $start_time]")
    lines_list.append('puts $logFileId "place: $total_seconds seconds"')
    lines_list.append("write_checkpoint  -force  page_placed.dcp")
    lines_list.append("")

    lines_list.append("set start_time [clock seconds]")
    if self.prflow_params['PR_mode'] == 'quick':
      lines_list.append("if { [catch {route_design -directive Quick } errmsg] } {")
    else:
      lines_list.append("if { [catch {route_design  } errmsg] } {")
    lines_list.append("  puts $logFileId \"routing: 99999 failed!\"")
    lines_list.append("}")
          
    lines_list.append("set end_time [clock seconds]")
    lines_list.append("set total_seconds [expr $end_time - $start_time]")
    lines_list.append('puts $logFileId "route: $total_seconds seconds"')
    lines_list.append("write_checkpoint -force   page_routed.dcp")
    lines_list.append("")
    lines_list.append("")

    lines_list.append("###############")
    lines_list.append("## bitstream ##")
    lines_list.append("###############")
    lines_list.append("set_param bitstream.enablePR 2341")
    lines_list.append("set start_time [clock seconds]")
    if IsNet:
      lines_list.append("write_bitstream  -force  -cell floorplan_static_i/net" + str(num) + "/inst ../../F005_bits_"+self.prflow_params['benchmark_name']+"/net_" + str(num) + "")
    else:
      lines_list.append("write_bitstream  -force  -cell floorplan_static_i/leaf_empty_" + str(num) + "/inst ../../F005_bits_"+self.prflow_params['benchmark_name']+'/'+fun_name)
    lines_list.append("set end_time [clock seconds]")
    lines_list.append("set total_seconds [expr $end_time - $start_time]")
    lines_list.append('puts $logFileId "bit_gen: $total_seconds seconds"')
    if IsNet:
      lines_list.append('report_utilization -pblocks ' + fun_name + ' > utilization.rpt')
    else:
      lines_list.append('report_utilization -pblocks p_' + str(num) + ' > utilization.rpt')
    lines_list.append('report_timing_summary > timing.rpt')
    return lines_list






  def return_mk_overlay_tcl_list(self):
    lines_list = []
    lines_list.append('set logFileId [open ./runLog_impl_big_static_' + str(self.prflow_params['nl']) + '.log "w"]')
    lines_list.append('')
    lines_list.append('#####################')
    lines_list.append('## read_checkpoint ##')
    lines_list.append('#####################')
    lines_list.append('set start_time [clock seconds]')
    lines_list.append('open_checkpoint ./floorplan_static.dcp')
    for i in range(int(self.prflow_params['nl'])):
      if self.prflow_params['page'+str(i)].replace('RISCV', '') != self.prflow_params['page'+str(i)]:
        lines_list.append('read_checkpoint -cell floorplan_static_i/leaf_empty_' + str(i) + '/inst ./dummy_repo/'+self.prflow_params['page'+str(i)]+'/page_netlist.dcp')
      if self.prflow_params['page'+str(i)].replace('user_kernel', '') != self.prflow_params['page'+str(i)]:
        lines_list.append('read_checkpoint -cell floorplan_static_i/leaf_empty_' + str(i) + '/inst ./dummy_repo/'+self.prflow_params['page'+str(i)]+'/page_netlist.dcp')
    lines_list.append('set end_time [clock seconds]')
    lines_list.append('set total_seconds [expr $end_time - $start_time]')
    lines_list.append('puts $logFileId "read_checkpoint: $total_seconds seconds"')
    lines_list.append('')
    lines_list.append('####################')
    lines_list.append('## implementation ##')
    lines_list.append('####################')
    lines_list.append('set start_time [clock seconds]')
    lines_list.append('opt_design')
    lines_list.append('set end_time [clock seconds]')
    lines_list.append('set total_seconds [expr $end_time - $start_time]')
    lines_list.append('puts $logFileId "opt: $total_seconds seconds"')
    lines_list.append('set start_time [clock seconds]')
    lines_list.append('place_design')
    lines_list.append('set end_time [clock seconds]')
    lines_list.append('set total_seconds [expr $end_time - $start_time]')
    lines_list.append('puts $logFileId "place: $total_seconds seconds"')
    lines_list.append('# write_hwdef -force pr_test_wrapper.hwdef')
    lines_list.append('write_checkpoint -force init_placed_' + str(self.prflow_params['nl']) + '.dcp')
    lines_list.append('set start_time [clock seconds]')
    lines_list.append('route_design')
    lines_list.append('set end_time [clock seconds]')
    lines_list.append('set total_seconds [expr $end_time - $start_time]')
    lines_list.append('puts $logFileId "route: $total_seconds seconds"')
    lines_list.append('write_checkpoint -force init_routed_' + str(self.prflow_params['nl']) + '.dcp')
    lines_list.append('set_param bitstream.enablePR 2341')
    lines_list.append('write_bitstream -force -no_partial_bitfile  ./main.bit')
    for i in range(int(self.prflow_params['nl'])):
      if self.prflow_params['page'+str(i)].replace('RISCV', '') != self.prflow_params['page'+str(i)]:
        lines_list.append('write_bitstream -force -cell floorplan_static_i/leaf_empty_'+str(i)+\
                          '/inst ./riscv_bit_lib/page'+str(i)+'_'+self.prflow_params['page'+str(i)]+'.bit')
    lines_list.append('report_timing_summary > timing.rpt')
    lines_list.append('#############################################')
    lines_list.append('## create static design with no bft pblock ##')
    lines_list.append('#############################################')
    lines_list.append('')
    lines_list.append('set start_time [clock seconds]')
    lines_list.append('update_design -cell floorplan_static_i/bft0 -black_box')
    lines_list.append('update_design -cell floorplan_static_i/bft1 -black_box')
    lines_list.append('update_design -cell floorplan_static_i/bft2 -black_box')
    lines_list.append('update_design -cell floorplan_static_i/bft3 -black_box')
    lines_list.append('update_design -cell floorplan_static_i/bft_center -black_box')
    for i in range(int(self.prflow_params['nl'])):
      if self.prflow_params['page'+str(i)].replace('RISCV', '') != self.prflow_params['page'+str(i)] or \
         self.prflow_params['page'+str(i)].replace('user_kernel', '') != self.prflow_params['page'+str(i)]:
        lines_list.append('update_design -cell floorplan_static_i/leaf_empty_' + str(i) + '/inst -black_box')

    lines_list.append('#############################################')
    lines_list.append('## Only after empty all modules out, can   ##')
    lines_list.append('## you add -buffer_ports                   ##')
    lines_list.append('#############################################')
 
    lines_list.append('update_design -cell floorplan_static_i/bft0 -buffer_ports')
    lines_list.append('update_design -cell floorplan_static_i/bft1 -buffer_ports')
    lines_list.append('update_design -cell floorplan_static_i/bft2 -buffer_ports')
    lines_list.append('update_design -cell floorplan_static_i/bft3 -buffer_ports')
    lines_list.append('update_design -cell floorplan_static_i/bft_center -buffer_ports')
    for i in range(int(self.prflow_params['nl'])):
      if self.prflow_params['page'+str(i)].replace('RISCV', '') != self.prflow_params['page'+str(i)] or \
         self.prflow_params['page'+str(i)].replace('user_kernel', '') != self.prflow_params['page'+str(i)]:
        lines_list.append('update_design -cell floorplan_static_i/leaf_empty_' + str(i) + '/inst -buffer_ports')
        lines_list.append('report_utilization -pblocks p_'+str(i)+' > utilization'+str(i)+'.rpt')
   

    lines_list.append('lock_design -level routing')
    lines_list.append('write_checkpoint -force overlay.dcp')
    lines_list.append('close_design')
    lines_list.append('set end_time [clock seconds]')
    lines_list.append('set total_seconds [expr $end_time - $start_time]')
    lines_list.append('puts $logFileId "update, black_box: $total_seconds seconds"')
    lines_list.append('# set start_time [clock seconds]')
    lines_list.append('# set end_time [clock seconds]')
    lines_list.append('# set total_seconds [expr $end_time - $start_time]')
    lines_list.append('# puts $logFileId "write bitstream: $total_seconds seconds"')

    return lines_list

  def return_download_bit_tcl_list(self, operators):
    lines_list = []
    lines_list.append('open_hw')
    lines_list.append('connect_hw_server')
    lines_list.append('open_hw_target')
    lines_list.append('current_hw_device [get_hw_devices '+self.prflow_params['device']+']')
    lines_list.append('set_property PROBES.FILE {} [get_hw_devices '+self.prflow_params['device']+']')
    lines_list.append('set_property FULL_PROBES.FILE {} [get_hw_devices '+self.prflow_params['device']+']')
    lines_list.append('set_property PROGRAM.FILE {./main.bit} [get_hw_devices '+self.prflow_params['device']+']')
    lines_list.append('program_hw_devices [get_hw_devices '+self.prflow_params['device']+']')
    lines_list.append('refresh_hw_device [lindex [get_hw_devices '+self.prflow_params['device']+'] 0]\n')
    for operator in operators:
      lines_list.append('set_property PROBES.FILE {} [get_hw_devices '+self.prflow_params['device']+']')
      lines_list.append('set_property FULL_PROBES.FILE {} [get_hw_devices '+self.prflow_params['device']+']')
      lines_list.append('set_property PROGRAM.FILE {./'+ operator + '.bit} [get_hw_devices '+self.prflow_params['device']+']')
      lines_list.append('program_hw_devices [get_hw_devices '+self.prflow_params['device']+']')
      lines_list.append('refresh_hw_device [lindex [get_hw_devices '+self.prflow_params['device']+'] 0]\n')
    
    return lines_list 
 




  # tcl command function end
  ######################################################################################################################################################



class gen_basic:
  def __init__(self, prflow_params):
    self.shell = _shell(prflow_params)
    self.pragma = _pragma(prflow_params)
    self.verilog = _verilog(prflow_params)
    self.tcl = _tcl(prflow_params)
    self.prflow_params = prflow_params
    self.bft_dir = self.prflow_params['workspace']+'/F000_bft_gen'
    #self.overlay_dir = self.prflow_params['workspace']+'/F001_overlay_' + self.prflow_params['nl'] + '_leaves'
    self.overlay_dir  = self.prflow_params['workspace']+'/F001_overlay'
    self.hls_dir      = self.prflow_params['workspace']+'/F002_hls_'+self.prflow_params['benchmark_name']
    self.syn_dir      = self.prflow_params['workspace']+'/F003_syn_'+self.prflow_params['benchmark_name']
    self.pr_dir       = self.prflow_params['workspace']+'/F004_impl_'+self.prflow_params['benchmark_name']
    self.bit_dir      = self.prflow_params['workspace']+'/F005_bits_'+self.prflow_params['benchmark_name']
    self.mono_dir     = self.prflow_params['workspace']+'/F007_mono_'+self.prflow_params['benchmark_name']
    self.mono_bft_dir = self.prflow_params['workspace']+'/F007_mono_bft_'+self.prflow_params['benchmark_name']
    self.sdk_dir      = self.prflow_params['workspace']+'/F008_sdk_'+self.prflow_params['benchmark_name']
    self.rpt_dir      = self.prflow_params['workspace']+'/report'
    self.net_list     = ['1', '1', '1', '1', '1', '2', '2', '2',
                         '2', '2', '2', '0', '3', '3', '3', '3',
                         '3', '3', '4', '4', '4', '4', '4', '4',
                         '5', '5', '5', '5', '5', '5', '5', '5']






  ######################################################################################################################################################
  # help functions start
  def print_params(self):
    print (self.prflow_params)

  def print_list(self, in_list):
    for num, value in enumerate(in_list):
      print (str(num)+'\t'+str(value))

  def print_dict(self, in_dict):
    for key, value in sorted(in_dict.items()):
      print (str(key).ljust(30)+'->'+str(value))

  def has_pattern(self, in_str, pattern_str):
    if in_str.replace(pattern_str, '') == in_str:
      return False
    else:
      return True

  # help functions end
  ######################################################################################################################################################

if __name__ == '__main__':
  modification_dict = {'parameter PAYLOAD_BITS0': 'parameter PAYLOAD_BITS0 = a,',
                       'parameter PORT_NUM_IN0': 'parameter PORT_NUM_IN0 = b,',
                       'parameter PORT_NUM_OUT0': 'parameter PORT_NUM_OUT0 = c,'}
  filename='net0.v'
  inst = gen_basic()
  inst.replace_lines(filename, modification_dict)
  lines_list = ['hell',
   'you',
   'are',
   'every',
   'thing']

  inst.add_lines(filename, 'input clk', lines_list)
  inst.write_lines('net1.txt',  lines_list)



