#!/bin/bash

for i in {1..10000}
do
  echo ''
  echo ''
  make report
  # cat ./workspace/F001_overlay/slurm-124.out
  squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R" --me
  echo 'Current time is :'$(date "+%Y-%m-%d %H:%M:%S")
  sleep 10
done
