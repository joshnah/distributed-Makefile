#!/bin/bash

# Check if number of iterations is given
if [ $# -eq 0 ]; then
    echo "Usage: $(basename $0) <number_of_iterations>"
    exit 1
fi

# constants
CSV_NAME="latency.csv"
# NFS path to write to in Grid5000
NFS_DIR="/home/$(whoami)"
TESTFILE="$NFS_DIR/testfile"
BLOCK_SIZES=("4k" "8k" "16k" "32k" "64k")  # block sizes to test
NUM_TESTS=$1 # number of tests to run for each block size

# variables
results_dir="./results"
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
    local average_latency=0.0
    local result time_result seconds
    echo -n $(echo "$block_size" | sed 's/k/000/') >> $output_csv
    for ((i=1; i<=NUM_TESTS; ++i)); do
        echo "Running NFS write performance test with block size $block_size... ($i/$NUM_TESTS)"
        # extract the "real" time from the result
        result=$( { time dd if=/dev/zero of=$TESTFILE bs=$block_size count=100000 conv=fsync ; } 2>&1 )
        time_result=$(echo "$result" | grep real | awk '{print $2}')
        echo $time_result
        seconds=$(convert_to_seconds "$time_result")
        average_latency=$(echo "$average_latency + $seconds" | bc)
        echo -n ";$seconds" >> $output_csv
    done
    average_latency=$(echo "scale=4; $average_latency / $NUM_TESTS" | bc)
    echo -n ";$average_latency" >> $output_csv
}

# read test latency
run_read_test() {
    local block_size=$1
    local average_latency=0
    local result time_result seconds
    for ((i=1; i<=NUM_TESTS; ++i)); do
        echo "Running NFS read performance test with block size $block_size... ($i/$NUM_TESTS)"
        # extract the "real" time from the result
        result=$( { time dd if=$TESTFILE of=/dev/null bs=$block_size count=100000 conv=fsync ; } 2>&1 )
        time_result=$(echo "$result" | grep real | awk '{print $2}')
        echo $time_result
        seconds=$(convert_to_seconds "$time_result")
        average_latency=$(echo "$average_latency + $seconds" | bc)
        echo -n ";$seconds" >> $output_csv
    done
    average_latency=$(echo "scale=4; $average_latency / $NUM_TESTS" | bc)
    echo -n ";$average_latency" >> $output_csv
    echo "" >> $output_csv # newline
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
echo -n "block_size;" > $output_csv # bytes
for ((i=1; i<=NUM_TESTS; ++i)); do
    echo -n "write_latency_$i;" >> $output_csv # seconds
done
echo -n "write_latency_average;" >> $output_csv
for ((i=1; i<=NUM_TESTS; ++i)); do
    echo -n "read_latency_$i;" >> $output_csv
done
echo "read_latency_average" >> $output_csv

# test for each block size
for size in "${BLOCK_SIZES[@]}"; do
    run_write_test $size
    run_read_test $size
done

rm $TESTFILE

echo "Tests completed. Data saved in: $output_csv"
echo "$output_csv" > "result_path.txt"
