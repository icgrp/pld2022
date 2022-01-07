#!/bin/bash -e

tcl_name=$1
tcl_argv=$2

vivado -mode batch -source  ${tcl_name} -tclargs $2 
