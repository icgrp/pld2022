#!/bin/bash -e
workspace=$1


cd ${workspace}/_x/link/vivado/vpl/prj/prj.runs/impl_1/
vivado -mode batch -source  gen_pfm_dynamic.tcl
cd -
cp ${workspace}/_x/link/vivado/vpl/prj/prj.runs/impl_1/pfm_dynamic.dcp ./checkpoint
