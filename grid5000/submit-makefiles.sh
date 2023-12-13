# truncate execution-time-result
> execution_time_result
folder=$(dirname "${BASH_SOURCE[0]}")
while IFS= read -r MAKEFILE_PATH; do
  MAKEFILE_FOLDER=$(dirname $MAKEFILE_PATH)  
  # make clean and make
  make -C $MAKEFILE_FOLDER clean

  echo "Submitting $MAKEFILE_PATH"
  # Run spark-submit
  $folder/submit-job.sh $MAKEFILE_PATH

  # Capture the execution time
  EXECUTION_TIME=$(<executionTime.txt)

  # Append the execution time to the result file
  echo "$MAKEFILE_PATH; $EXECUTION_TIME" >> execution_time_result.txt
  echo "Done submitting $MAKEFILE_PATH"
done < $1