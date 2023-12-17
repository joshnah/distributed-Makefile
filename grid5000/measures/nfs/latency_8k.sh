#!/bin/bash

# constants
CSV_NAME="latency.csv"
# NFS path to write to in Grid5000
NFS_DIR="/home/$(whoami)"
TESTFILE="$NFS_DIR/testfile"
BLOCK_SIZE="8k" # block size to test
NUM_TESTS=30 # number of tests to run for each block size

# variables
results_dir="./results-8k"
output_csv="$results_dir/$CSV_NAME"
results_dir_suffix=1

# convert minutes to seconds
convert_to_seconds() {
    local input=$1
    local minutes seconds

    if [[ $input =~ ([0-9]+)m([0-9,\.]+)s ]]; then # regex: 0m0,000s
        minutes=${BASH_REMATCH[1]}
        seconds=${BASH_REMATCH[2]//,/.}  # replace , with . for bc
        echo "($minutes * 60) + $seconds" | bc -l
    else
        echo "-1"  # if format is invalid
    fi
}

# write test latency
run_write_test() {
    local block_size=$1
    local result time_result seconds
    # extract the "real" time from the result
    result=$( { time dd if=/dev/zero of=$TESTFILE bs=$block_size count=100000 oflag=direct conv=fsync ; } 2>&1 )
    time_result=$(echo "$result" | grep real | awk '{print $2}')
    echo $time_result
    seconds=$(convert_to_seconds "$time_result")
    echo -n "$seconds" >> $output_csv
}

# read test latency
run_read_test() {
    local block_size=$1
    local result time_result seconds
    # extract the "real" time from the result
    result=$( { time dd if=$TESTFILE of=/dev/null bs=$block_size count=100000 iflag=direct conv=fsync ; } 2>&1 )
    time_result=$(echo "$result" | grep real | awk '{print $2}')
    echo $time_result
    seconds=$(convert_to_seconds "$time_result")
    echo ";$seconds" >> $output_csv
}

if [ -e "$output_csv" ]; then
    while [ -e "$output_csv" ]; do
        results_dir_suffix=$((results_dir_suffix + 1))
        output_csv="$results_dir$results_dir_suffix/$CSV_NAME"
    done
    mkdir -p "$results_dir$results_dir_suffix"
else
    mkdir -p "$results_dir"
fi

# CSV Header
echo "write_latency;read_latency" > $output_csv

# test
for ((i=1; i<=NUM_TESTS; ++i)); do
    echo "Running NFS write performance test with block size $BLOCK_SIZE... ($i/$NUM_TESTS)"
    run_write_test $BLOCK_SIZE
    echo "Running NFS read performance test with block size $BLOCK_SIZE... ($i/$NUM_TESTS)"
    run_read_test $BLOCK_SIZE
done

rm $TESTFILE

echo "Tests completed. Data saved in: $output_csv"
