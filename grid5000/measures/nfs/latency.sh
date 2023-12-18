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

calculate_mean() {
    local times=("$@")
    local sum=0

    for time in "${times[@]}"; do
        sum=$(echo "$sum + $time" | bc)
    done

    local num_elements=${#times[@]}
    local mean=$(echo "scale=4; $sum / $num_elements" | bc)
    echo "$mean"
}

calculate_median() {
    local times=("$@")
    local -a sorted_times=($(for time in "${times[@]}"; do echo "$time"; done | sort -n))
    local num_elements=${#sorted_times[@]}
    local middle=$((num_elements / 2))

    if ((num_elements % 2 == 0)); then
        # even number of elements
        local middle_minus_one=$((middle - 1))
        local median=$(echo "scale=4; (${sorted_times[middle_minus_one]} + ${sorted_times[middle]}) / 2" | bc)
    else
        # odd number of elements
        local median=${sorted_times[middle]}
    fi

    echo "$median"
}

calculate_variance() {
    local array=("$@")
    local num_elements=${#array[@]}
    local mean=$(calculate_mean "${array[@]}")

    # Calculate the sum of squared differences between each value and the mean
    local sum_squared_diff=0
    for val in "${array[@]}"; do
        local diff=$(echo "scale=4; $val - $mean" | bc)
        local squared_diff=$(echo "scale=4; $diff * $diff" | bc)
        sum_squared_diff=$(echo "scale=4; $sum_squared_diff + $squared_diff" | bc)
    done

    # Calculate variance (mean of squared differences)
    local variance=$(echo "scale=4; $sum_squared_diff / $num_elements" | bc)
    echo "$variance"
}

# Fonction pour calculer l'écart-type d'un tableau
calculate_std_deviation() {
    local array=("$@")
    local variance=$(calculate_variance "${array[@]}")

    # Calculate standard deviation (root of variance)
    local std_deviation=$(echo "scale=4; sqrt($variance)" | bc)
    echo "$std_deviation"
}

# write test latency
run_write_test() {
    local block_size=$1
    local result time_result seconds
    local -a all_seconds=()
    echo -n $(echo "$block_size" | sed 's/k/000/') >> $output_csv
    for ((i=1; i<=NUM_TESTS; ++i)); do
        echo "Running NFS write performance test with block size $block_size... ($i/$NUM_TESTS)"
        # extract the "real" time from the result
        result=$( { time dd if=/dev/zero of=$TESTFILE bs=$block_size oflag=direct count=100000 conv=fsync ; } 2>&1 )
        time_result=$(echo "$result" | grep real | awk '{print $2}')
        echo $time_result
        seconds=$(convert_to_seconds "$time_result")
        all_seconds+=($seconds) # append to array
        echo -n ";$seconds" >> $output_csv
    done
    # sort array by value (ascending)
    local -a sorted_array=($(for val in "${all_seconds[@]}"; do echo "$val"; done | sort -n))
    local num_elements=${#sorted_array[@]}    
    # calculate mean
    local mean=$(calculate_mean "${all_seconds[@]}")
    # calculate median
    local median=$(calculate_median "${sorted_array[@]}")
    local min=${sorted_array[0]}
    local max=${sorted_array[num_elements - 1]}
    # calculate variance
    local variance=$(calculate_variance "${all_seconds[@]}")
    # calculate standard deviation
    local stddev=$(calculate_std_deviation "${all_seconds[@]}")
    echo -n ";$mean;$median;$min;$max;$variance;$stddev" >> $output_csv
}

# read test latency
run_read_test() {
    local block_size=$1
    local result time_result seconds
    local -a all_seconds=()
    for ((i=1; i<=NUM_TESTS; ++i)); do
        echo "Running NFS read performance test with block size $block_size... ($i/$NUM_TESTS)"
        # extract the "real" time from the result
        result=$( { time dd if=$TESTFILE of=/dev/null bs=$block_size iflag=direct count=100000 conv=fsync ; } 2>&1 )
        time_result=$(echo "$result" | grep real | awk '{print $2}')
        echo $time_result
        seconds=$(convert_to_seconds "$time_result")
        all_seconds+=($seconds) # append to array
        echo -n ";$seconds" >> $output_csv
    done
     # sort array by value (ascending)
    local -a sorted_array=($(for val in "${all_seconds[@]}"; do echo "$val"; done | sort -n))
    local num_elements=${#sorted_array[@]}    
    # calculate mean
    local mean=$(calculate_mean "${all_seconds[@]}")
    # calculate median
    local median=$(calculate_median "${sorted_array[@]}")
    local min=${sorted_array[0]}
    local max=${sorted_array[num_elements - 1]}
    # calculate variance
    local variance=$(calculate_variance "${all_seconds[@]}")
    # calculate standard deviation
    local stddev=$(calculate_std_deviation "${all_seconds[@]}")
    echo ";$mean;$median;$min;$max;$variance;$stddev" >> $output_csv
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
    echo -n "w_lat_$i;" >> $output_csv # seconds
done
echo -n "w_lat_av;w_lat_med;w_lat_min;w_lat_max;w_lat_var;w_lat_stddev;" >> $output_csv

for ((i=1; i<=NUM_TESTS; ++i)); do
    echo -n "r_lat_$i;" >> $output_csv
done
echo "r_lat_av;r_lat_med;r_lat_min;r_lat_max;r_lat_var;r_lat_stddev" >> $output_csv


# test for each block size
for size in "${BLOCK_SIZES[@]}"; do
    run_write_test $size
    run_read_test $size
done

rm $TESTFILE

echo "Tests completed. Data saved in: $output_csv"
echo "$output_csv" > "result_path.txt"
