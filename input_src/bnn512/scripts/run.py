#!/usr/bin/env python
# -*- coding: utf-8 -*-   
#starting
import os  
import subprocess
import argparse
import xml.etree.ElementTree



def write_line(filename, line_list):
 file_out = open(filename, 'w')
 for line in line_list:
   file_out.write(line)

 file_out.close() 


def dummy_func():
  
  # line_num = 1
  # line_list []
  # for line in file_in
  
  a_list = [1, 1, 1, 2, 2, 2, 2, 2]
  sum = 0
  str_sum = '0:bin_dense_par_0_1_a[8192]'
  for i, value in enumerate(a_list):
    if value==1:
      sum += 8192     
      str_sum += ','+str(sum) + ':'+'bin_dense_par_0_'+str(i+1)+'_b[2048]' 
      sum += 2048
      str_sum += ','+str(sum) + ':'+'bin_dense_par_0_'+str(i+2)+'_a[8192]'
    else:
      sum += 16384     
      str_sum += ','+str(sum)  + ':'+'bin_dense_par_0_'+str(i+1)+'_b[4096]' 
      sum += 4096
      str_sum += ','+str(sum)  + ':'+'bin_dense_par_0_'+str(i+1)+'_c[1024]'
      sum += 1024
      str_sum += ','+str(sum)  + ':'+'bin_dense_par_0_'+str(i+2)+'_a[16384]'

  print str_sum



if __name__ == '__main__':
  bin_conv_size = [
              4096,
              2048,
              8192,
              2048,
              8192,
              2048,
              8192,
              2048,
              16384,
              4096,
              1024,
              8192,
              2048,
              16384,
              4096,
              1024,
              8192,
              2048,
              16384,
              4096,
              1024,
              8192,
              2048,
              14688]

  bin_conv_list = [
              'const int32_t bin_conv_par_0_a',
              'const int32_t bin_conv_par_0_b',
              'const int32_t bin_conv_par_1_a',
              'const int32_t bin_conv_par_1_b',
              'const int32_t bin_conv_par_2_a',
              'const int32_t bin_conv_par_2_b',
              'const int32_t bin_conv_par_3_a',
              'const int32_t bin_conv_par_3_b',
              'const int32_t bin_conv_par_4_a',
              'const int32_t bin_conv_par_4_b',
              'const int32_t bin_conv_par_4_c',
              'const int32_t bin_conv_par_5_a',
              'const int32_t bin_conv_par_5_b',
              'const int32_t bin_conv_par_6_a',
              'const int32_t bin_conv_par_6_b',
              'const int32_t bin_conv_par_6_c',
              'const int32_t bin_conv_par_7_a',
              'const int32_t bin_conv_par_7_b',
              'const int32_t bin_conv_par_8_a',
              'const int32_t bin_conv_par_8_b',
              'const int32_t bin_conv_par_8_c',
              'const int32_t bin_conv_par_9_a',
              'const int32_t bin_conv_par_9_b',
              'const int32_t bin_conv_par_10_a']

  bin_dense_0_size = [
              8192,
              2048,
              8192,
              2048,
              8192,
              2048,
              16384,
              4096,
              1024,
              16384,
              4096,
              1024,
              16384,
              4096,
              1024,
              8192,
              8192,
              1024,
              16384,
              4096,
              1024,
              13472]
   


  bin_dense_0_list = [
              'const unsigned int bin_dense_par_0_0_a',
              'const unsigned int bin_dense_par_0_0_b',
              'const unsigned int bin_dense_par_0_1_a',
              'const unsigned int bin_dense_par_0_1_b',
              'const unsigned int bin_dense_par_0_2_a',
              'const unsigned int bin_dense_par_0_2_b',
              'const unsigned int bin_dense_par_0_3_a',
              'const unsigned int bin_dense_par_0_3_b',
              'const unsigned int bin_dense_par_0_3_c',
              'const unsigned int bin_dense_par_0_4_a',
              'const unsigned int bin_dense_par_0_4_b',
              'const unsigned int bin_dense_par_0_4_c',
              'const unsigned int bin_dense_par_0_5_a',
              'const unsigned int bin_dense_par_0_5_b',
              'const unsigned int bin_dense_par_0_5_c',
              'const unsigned int bin_dense_par_0_6_a',
              'const unsigned int bin_dense_par_0_6_b',
              'const unsigned int bin_dense_par_0_6_c',
              'const unsigned int bin_dense_par_0_7_a',
              'const unsigned int bin_dense_par_0_7_b',
              'const unsigned int bin_dense_par_0_7_c',
              'const unsigned int bin_dense_par_0_8_a']

  bin_dense_1_size = [
              16384,
              4096,
              1024,
              16384,
              4096,
              1024,
              16384,
              4096,
              1024,
              16384,
              4096,
              1024,
              16384,
              4096,
              1024,
              16384,
              4096,
              1024,
              16384,
              2208]
 
  bin_dense_1_list =[
             'const unsigned int bin_dense_par_1_0_a',
             'const unsigned int bin_dense_par_1_0_b',
             'const unsigned int bin_dense_par_1_0_c',
             'const unsigned int bin_dense_par_1_1_a',
             'const unsigned int bin_dense_par_1_1_b',
             'const unsigned int bin_dense_par_1_1_c',
             'const unsigned int bin_dense_par_1_2_a',
             'const unsigned int bin_dense_par_1_2_b',
             'const unsigned int bin_dense_par_1_2_c',
             'const unsigned int bin_dense_par_1_3_a',
             'const unsigned int bin_dense_par_1_3_b',
             'const unsigned int bin_dense_par_1_3_c',
             'const unsigned int bin_dense_par_1_4_a',
             'const unsigned int bin_dense_par_1_4_b',
             'const unsigned int bin_dense_par_1_4_c',
             'const unsigned int bin_dense_par_1_5_a',
             'const unsigned int bin_dense_par_1_5_b',
             'const unsigned int bin_dense_par_1_5_c',
             'const unsigned int bin_dense_par_1_6_a',
             'const unsigned int bin_dense_par_1_6_b']
 
  file_in = open('./para/bin_dense_para_0.h', 'r')
  line_list = []
  for line in file_in:
    line_list.append(line)


  line_num = 0
  for i, value in enumerate(bin_dense_0_size): 

    if line_num!=0: line_list[line_num-1] = line_list[line_num-1].replace(',','};')
    line_list[line_num] = bin_dense_0_list[i]+'['+str(value)+']= {'+line_list[line_num] 
    line_num += value

  write_line('./sdsoc/bin_dense_para_0.h', line_list)

###########################################################################################
  file_in = open('./para/bin_dense_para_1.h', 'r')
  line_list = []
  for line in file_in:
    line_list.append(line)


  line_num = 0
  for i, value in enumerate(bin_dense_1_size): 

    if line_num!=0: line_list[line_num-1] = line_list[line_num-1].replace(',','};')
    line_list[line_num] = bin_dense_1_list[i]+'['+str(value)+']= {'+line_list[line_num] 
    line_num += value

  write_line('./sdsoc/bin_dense_para_1.h', line_list)



###########################################################################################
  file_in = open('./para/bin_conv_para.h', 'r')
  line_list = []
  for line in file_in:
    line_list.append(line)


  line_num = 0
  for i, value in enumerate(bin_conv_size): 

    if line_num!=0: line_list[line_num-1] = line_list[line_num-1].replace(',','};')
    line_list[line_num] = bin_conv_list[i]+'['+str(value)+']= {'+line_list[line_num] 
    line_num += value

  write_line('./sdsoc/bin_conv_para.h', line_list)








 










