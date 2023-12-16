#!/bin/bash

chmod u+x ~/distributed-Makefile/grid5000/measures/nfs/latency.sh

~/distributed-Makefile/grid5000/measures/nfs/latency.sh 10 &

# wait for the script to finish
wait $!

# get the results path
result_path=$(cat ~/distributed-Makefile/grid5000/measures/nfs/result_path.txt)

# generate plots
Rscript ~/distributed-Makefile/grid5000/measures/nfs/latency_perf.R $result_path

rm ~/distributed-Makefile/grid5000/measures/nfs/result_path.txt
