#!/bin/bash

nfsFilePath="file.txt"
csvFilePath="res_latency_write.csv"
echo "Size (Mb);Latency (s)" > "$csvFilePath"
for sizeMB in {1..250..10}; do
  sizeBytes=$((sizeMB * 1024 * 1024))
  
  # Generate data to write
  dataToWrite=$(printf "%-${sizeBytes}s" "X") 

  # Write data
  startTime=$(date +%s.%N)
  echo "$dataToWrite" > "$nfsFilePath"
  endTime=$(date +%s.%N)

  # Calculate latency
  latencySeconds=$(echo "$endTime - $startTime" | bc)

  # Print out the result
  echo "$sizeMB;$latencySeconds" >> "$csvFilePath"
done
echo "$csvFilePath file generated"
