#!/usr/bin/env python
# -*- coding: utf-8 -*-   
import re


if __name__ == '__main__':

  clb_list = []
  ff_list = []
  bram_list = []
  dsp_list = []
  
  resource_dist = open("resource.csv", 'w')
  for i in range(2, 32):
    file_in = open('./p_'+str(i)+'.rpt', 'r')
    out_str = 'p_'+str(i)
    for line in file_in:
      if line.startswith('| CLB LUTs'):
        clb =  re.findall(r"\d+", line)
        clb_list.append(clb[2])
        out_str+=','+clb[2]

      if line.startswith('| CLB Registers'):
        ff =  re.findall(r"\d+", line)
        ff_list.append(ff[2])
        out_str+=','+ff[2]

      if line.startswith('| Block'):
        bram =  re.findall(r"\d+", line)
        bram_list.append(bram[2])
        out_str+=','+bram[2]

      if line.startswith('| DSPs'):
        dsp =  re.findall(r"\d+", line)
        dsp_list.append(dsp[2])
        out_str+=','+dsp[2]
    print out_str
    resource_dist.write(out_str+'\n')
    file_in.close()

  resource_dist.close()



