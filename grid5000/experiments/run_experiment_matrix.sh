# Run the matrix multiplication experiment on Grid5000 proving that spark is deployed correctly
# Final result is stored in execution_time_result.txt
result_file="matrix_result.txt"
execution_file="executionTime.txt"
folder=$(pwd)/$(dirname "${BASH_SOURCE[0]}")   
echo "folder: $folder"
MATRIX_FOLDER=$folder/../../makefiles/matrix
NB_ATTEMPTS=3

# if NB_ATTEMPTS is provided
if [ ! -z "$1" ]; then
  NB_ATTEMPTS=$1
fi

# Clean up the result file
> $result_file
echo "Dimension; Decoupe; Scheduling Time, Execution Time" >> $result_file
# Loop over dimensions
for dimension in {1..1..1}; do
  for decoupe in {5..5..10}; do
    echo "Running for Dimension: $dimension, Decoupe: $decoupe"
    DIMENSION=$dimension
    NB_DECOUPE=$decoupe

    $MATRIX_FOLDER/generate_makefile.pl $NB_DECOUPE > $MATRIX_FOLDER/Makefile
    $MATRIX_FOLDER/random_matrix.pl $DIMENSION $DIMENSION > $MATRIX_FOLDER/a
    $MATRIX_FOLDER/random_matrix.pl $DIMENSION $DIMENSION > $MATRIX_FOLDER/b

    total_execution_time=0
    total_scheduling_time=0

    for i in $(seq "$NB_ATTEMPTS"); do 
      echo "Attempt $i"

      $folder/../submit-job.sh $MATRIX_FOLDER/Makefile 2> /dev/null

      if [ $? -ne 0 ]; then
        echo "Error while submitting job"
        exit 1
      fi
      
      # make clean
      echo "Cleaning up"
      make -C $MATRIX_FOLDER clean > /dev/null

      # First line is scheduling time, second line is execution time
      SCHEDULING_TIME=$(head -n 1 $execution_file)
      EXECUTION_TIME=$(tail -n 1 $execution_file)

      total_execution_time=$(($total_execution_time + $EXECUTION_TIME))
      total_scheduling_time=$(($total_scheduling_time + $SCHEDULING_TIME))

      echo finished attempt $i
    done 

    average_execution_time=$(echo "scale=2; $total_execution_time / $NB_ATTEMPTS" | bc)
    average_scheduling_time=$(echo "scale=2; $total_scheduling_time / $NB_ATTEMPTS" | bc)


      # Append the execution time to the result file
      echo "$DIMENSION; $NB_DECOUPE; $average_scheduling_time; $average_execution_time " >> $result_file
  done
done

echo "Execution results are stored in $output_file"
