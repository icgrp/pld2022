lAddr="(youemail)@seas.upenn.edu"

qsub -N rendering_test -q 70s@icgrid43  -hold_jid spam_mono -l mem=8G -pe onenode 1 -cwd ./qsub_run.sh
