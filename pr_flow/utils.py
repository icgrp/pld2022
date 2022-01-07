#!/usr/bin/env python
import sys
import os
import xml.etree.ElementTree
import argparse
import re
import math

    
def load_prflow_params(filename):
  prflow_params = {
  }

  # parse the common specifications 
  root = xml.etree.ElementTree.parse(filename).getroot()
  specs = root.findall('spec')
  network = root.findall('network')
  clock =root.findall('clock')

  for child in specs: prflow_params[child.get('name')] = child.get('value')
  for child in clock: prflow_params[child.get('name')] = child.get('period')

  print (filename.replace('configure/', 'configure/'+prflow_params['board']+'/'))
  board_root = root = xml.etree.ElementTree.parse(filename.replace('configure/', 'configure/'+prflow_params['board']+'/')).getroot()
  specs = board_root.findall('spec')
  for child in specs: prflow_params[child.get('name')] = child.get('value')


  return prflow_params



