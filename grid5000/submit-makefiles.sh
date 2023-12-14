# truncate executiontime_result
> execution_time_result.txt
folder=$(dirname "${BASH_SOURCE[0]}")
while IFS= read -r MAKEFILE_PATH; do
  rm executionTime.txt

  MAKEFILE_FOLDER=$(dirname $MAKEFILE_PATH)  
  # make clean and make
  make -C $MAKEFILE_FOLDER clean > /dev/null
  echo "Submitting $MAKEFILE_PATH"
  # Run spark-submit
  $folder/submit-job.sh $MAKEFILE_PATH
  # if execution time doesn't exist
  if [ ! -f executionTime.txt ]; then
    echo "Error submitting $MAKEFILE_PATH"
    continue
  fi

  # Capture the execution time
  EXECUTION_TIME=$(<executionTime.txt)

  # Append the execution time to the result file
  echo "$MAKEFILE_PATH; $EXECUTION_TIME" >> execution_time_result.txt
  echo "Done submitting $MAKEFILE_PATH"
done < $1