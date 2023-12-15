# #!/bin/bash
# DIMENSION=$1
# NB_DECOUPE=$2

# > execution_time_result.txt
# folder=$(dirname "${BASH_SOURCE[0]}")
# # enter the matrix folder 
# MATRIX_FOLDER=$folder/../makefiles/matrix
# $MATRIX_FOLDER/generate_makefile.pl $DIMENSION $NB_DECOUPE > $MATRIX_FOLDER/Makefile
# $MATRIX_FOLDER/random_matrix.pl $DIMENSION $DIMENSION > $MATRIX_FOLDER/a
# $MATRIX_FOLDER/random_matrix.pl $DIMENSION $DIMENSION > $MATRIX_FOLDER/b

# # the time execution is written in executionTime.txt
# $folder/submit-job.sh $MATRIX_FOLDER/Makefile




# Output file
result_file="execution_time_result.txt"
execution_file="executionTime.txt"
folder=$(dirname "${BASH_SOURCE[0]}")   
MATRIX_FOLDER=$folder/../makefiles/matrix

> $result_file
echo "Dimension; Decoupe; Scheduling Time, Execution Time" >> $result_file
# Loop over dimensions
for dimension in {1..5..1}; do
  for decoupe in {10..10}; do
    echo "Running for Dimension: $dimension, Decoupe: $decoupe"
    DIMENSION=$dimension
    NB_DECOUPE=$decoupe

    $MATRIX_FOLDER/generate_makefile.pl $DIMENSION $NB_DECOUPE > $MATRIX_FOLDER/Makefile
    $MATRIX_FOLDER/random_matrix.pl $DIMENSION $DIMENSION > $MATRIX_FOLDER/a
    $MATRIX_FOLDER/random_matrix.pl $DIMENSION $DIMENSION > $MATRIX_FOLDER/b

    $folder/submit-job.sh $MATRIX_FOLDER/Makefile

    # make clean
    echo "Cleaning up"
    make -C $MATRIX_FOLDER clean > /dev/null
    # Capture the execution time
    EXECUTION_TIME=$(<$execution_file)

    # Append the execution time to the result file
    echo "$DIMENSION; $NB_DECOUPE; $EXECUTION_TIME" >> $result_file

  done
done

echo "Execution results are stored in $output_file"



# while IFS= read -r MAKEFILE_PATH; do
#   rm executionTime.txt

#   MAKEFILE_FOLDER=$(dirname $MAKEFILE_PATH)  
#   # make clean and make
#   make -C $MAKEFILE_FOLDER clean > /dev/null
#   echo "Submitting $MAKEFILE_PATH"
#   # Run spark-submit
#   $folder/submit-job.sh $MAKEFILE_PATH
#   # if execution time doesn't exist
#   if [ ! -f executionTime.txt ]; then
#     echo "Error submitting $MAKEFILE_PATH"
#     continue
#   fi

#   # Capture the execution time
#   EXECUTION_TIME=$(<executionTime.txt)

#   # Append the execution time to the result file
#   echo "$MAKEFILE_PATH; $EXECUTION_TIME" >> execution_time_result.txt
#   echo "Done submitting $MAKEFILE_PATH"
# done < $folder/makefiles/matrix/M