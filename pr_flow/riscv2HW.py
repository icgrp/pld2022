#!/usr/bin/env python
# -*- coding: utf-8 -*-   
#starting
import os  
import subprocess
import argparse
import xml.etree.ElementTree
import fnmatch

if __name__ == '__main__':


  # Use argparse to parse the input arguments
  parser = argparse.ArgumentParser()
  parser.add_argument('benchmark_name')
  parser.add_argument('-op', '--operator',       type=str, default="no_func", help="choose which function to be regenrated")

  args = parser.parse_args()
  benchmark_name = args.benchmark_name  
  #operator = args.operator

  for operator in os.listdir('./input_src/'+benchmark_name+'/operators/'):
    if fnmatch.fnmatch(operator, '*.h'):
      print(operator)

      os.system('cp ./input_src/'+benchmark_name+'/operators/'+operator+' ./input_src/'+benchmark_name+'/operators/'+operator+'tmp')
      file_in =  open('./input_src/'+benchmark_name+'/operators/'+operator+'tmp', 'r')
      file_out = open('./input_src/'+benchmark_name+'/operators/'+operator,   'w')


      for line in file_in:
        if(line == line.replace('debug_port', '')):
          file_out.write(line.replace('RISCV', 'HW'))
        

      file_in.close()
      file_out.close()

      os.system('rm  ./input_src/'+benchmark_name+'/operators/'+operator+'tmp')
