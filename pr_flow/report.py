#!/usr/bin/env python
import sys
import os
import xml.etree.ElementTree
import argparse
import re
import math
import subprocess
from pr_flow.gen_basic import gen_basic


class report(gen_basic):
  def gen_compile_time_report(self, benchmark_name, operators_list):
    time_report_dict = {}
    time_data_dict = {}
    for fun_name in sorted(operators_list):
      map_target_exist, map_target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+fun_name+'.h', 'map_target')
      page_exist, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+fun_name+'.h', 'page_num')
      time_report_dict[fun_name] = fun_name.ljust(30) + '\t' + map_target + '\t' + page_num 
      time_data_dict[fun_name] = []
      #process hls timing
      try:
        file_name = './workspace/F002_hls_'+benchmark_name+'/runLog' + fun_name + '.log'
        file_in = open(file_name, 'r')
        for line in file_in:
          run_time = re.findall(r"\d+", line)
          time_report_dict[fun_name] += '\t' + run_time[0] 
          time_data_dict[fun_name].append(int(run_time[0]))
        file_in.close()
      except:
        print ('Something is wrong with '+file_name) 

      #process syn timing
      try:
        file_name = './workspace/F003_syn_'+benchmark_name+'/' + fun_name + '/runLog_' + fun_name + '.log'
        file_in = open(file_name, 'r')
        for line in file_in:
          #run_time = re.findall(r"\d+", line)
          run_time = line.split()
          time_report_dict[fun_name] += '\t' + run_time[1]
          time_data_dict[fun_name].append(run_time[1])
        file_in.close()
      except:
        print ('Something is wrong with '+file_name) 

      #process impl timing
      run_time_list = []
      try: 
        file_name = './workspace/F004_impl_'+benchmark_name+'/' + fun_name + '/runLogImpl_' + fun_name + '.log'
        file_in = open(file_name, 'r')
        for line in file_in:
          run_time = re.findall(r"\d+", line)
          run_time_list.append(int(run_time[0])) 
          time_data_dict[fun_name].append(int(run_time[0]))
        file_in.close()
        for i in range(6): time_report_dict[fun_name] += '\t' + str(run_time_list[i])
        total_time = 0
        for i in range(8): total_time += float(time_data_dict[fun_name][i])
        run_time_list.append(float(total_time))
        time_report_dict[fun_name] += '\t' + str(run_time_list[6])
        #time_report_dict[fun_name] += '\t\t' + str(run_time_list[5])
      except:
        print ("Something is wrong with "+file_name)

    
    time_report_file = open('./workspace/report/time_report_'+benchmark_name+'.csv', 'w')
    time_report_file.write('operator                  \ttarget\tpage\thls\tsyn\trdchk\topt\tplace\tpopt\troute\tbitgen\ttotal\n')
    for key, value in sorted(time_report_dict.items()):
      time_report_file.write(value+'\n')  
    print ('\n                               operator                  \ttarget\tpage\thls\tsyn\trdchk\topt\tplace\tpopt\troute\tbitgen\ttotal')
    print ('--------------------------------------------------------------------------------------------------------------------------------------------------------------')
    self.print_dict(time_report_dict)

  def gen_resource_report(self, benchmark_name, operators_list):
    resource_report_dict = {}
    for fun_name in operators_list:
      map_target_exist, map_target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+fun_name+'.h', 'map_target')
      page_exist, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+fun_name+'.h', 'page_num')
      resource_report_dict[fun_name] = fun_name.ljust(30) + '\t' + map_target + '\t' + page_num
      #####################################################################################
      #process resource utilization
      try:
        file_name = './workspace/F003_syn_'+benchmark_name+'/' + fun_name + '/utilization.rpt'
        file_in = open(file_name, 'r')
        for line in file_in:
          if line.startswith('| leaf'):
            resource_list =  re.findall(r"\d+", line)
            resource_report_dict[fun_name] += '\t' + resource_list[0]
            resource_report_dict[fun_name] += '\t' + resource_list[4]
            bram_num = int(resource_list[5])*2+int(resource_list[6])
            resource_report_dict[fun_name] += '\t' + str(bram_num)
            resource_report_dict[fun_name] += '\t' + resource_list[8]
        file_in.close()
      except:
        print ('Something is wrong with '+file_name) 



    resource_report_file = open('./workspace/report/resource_report_'+benchmark_name+'.csv', 'w')
    resource_report_file.write('operator                  \ttarget\tpage\tLUTs\tFFs\tBRAM18s\tDSPs\n')
    for key, value in sorted(resource_report_dict.items()):
      resource_report_file.write(value+'\n')  
    print ('\n                               operator                  \ttarget\tpage\tLUTs\tFFs\tBRAM18s\tDSPs')
    print ('------------------------------------------------------------------------------------------------------------')
    self.print_dict(resource_report_dict)

  def gen_timing_report(self, benchmark_name, operators_list):
    timing_report_dict = {}
    for fun_name in operators_list:
      map_target_exist, map_target = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+fun_name+'.h', 'map_target')
      page_exist, page_num = self.pragma.return_pragma('./input_src/'+self.prflow_params['benchmark_name']+'/operators/'+fun_name+'.h', 'page_num')
      timing_report_dict[fun_name] = fun_name.ljust(30) + '\t' + map_target + '\t' + page_num
      #####################################################################################
      #process timing report
      try:
        file_name = './workspace/F004_impl_'+benchmark_name+'/' + fun_name + '/timing_page'+str(page_num)+'.rpt'
        file_in = open(file_name, 'r')
        find_summary_flag = False
        line_offset = 0
        for line in file_in:
          if line.replace('Design Timing Summary', '') != line:
            find_summary_flag = True
          if find_summary_flag:
            line_offset += 1
          if line_offset == 7:
            timing_list =  line.split()
            timing_report_dict[fun_name] += '\t' + timing_list[0]
        file_in.close()
      except:
        print ('Something is wrong with '+file_name) 



    resource_report_file = open('./workspace/report/timing_report_'+benchmark_name+'.csv', 'w')
    resource_report_file.write('operator                  \ttarget\tpage\tslack\n')
    for key, value in sorted(timing_report_dict.items()):
      resource_report_file.write(value+'\n')  
    print ('\n                               operator                  \ttarget\tpage\tslack')
    print ('-------------------------------------------------------------------------------------')
    self.print_dict(timing_report_dict)

 
  def run(self, operators_str):

    self.shell.mkdir(self.rpt_dir)
    benchmark_name = self.prflow_params['benchmark_name']
    operators_list = operators_str.split() 
    self.gen_resource_report(benchmark_name, operators_list)
    self.gen_compile_time_report(benchmark_name, operators_list)
    self.gen_timing_report(benchmark_name, operators_list)
    print ('You can find the comile time report and resource report under: ./workspace/report')

