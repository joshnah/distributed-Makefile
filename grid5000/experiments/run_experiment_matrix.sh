# Run the matrix multiplication experiment on Grid5000 proving that spark is deployed correctly
# Final result is stored in execution_time_result.txt
result_file="matrix_result.txt"
folder=$(pwd)/$(dirname "${BASH_SOURCE[0]}")   
echo "folder: $folder"
MATRIX_FOLDER=$folder/../../makefiles/matrix
NB_ATTEMPTS=5

# if NB_ATTEMPTS is provided
if [ ! -z "$1" ]; then
  NB_ATTEMPTS=$1
fi

# Clean up the result file
> $result_file
echo "Nb_executor; nb_cores_per_executor; nb_memory_per_executor;Dimension; Decoupe; Scheduling Time, Execution Time" >> $result_file

TOTAL_CORES=64
NB_MEMORY_PER_EXECUTOR="1g"
for nb_executors in {1,2}; do
  NB_CORES_PER_EXECUTOR=$(($TOTAL_CORES / $nb_executors))
  echo "Running for nb_executors: $nb_executors, nb_cores_per_executor: $NB_CORES_PER_EXECUTOR, nb_memory_per_executor: $NB_MEMORY_PER_EXECUTOR"

  taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.instances=$nb_executors > /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]
  taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.cores=$NB_CORES_PER_EXECUTOR >> /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]
  taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.memory=$NB_MEMORY_PER_EXECUTOR >> /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]

  for dimension in {20..20..1}; do
    for decoupe in {2,4,8}; do
      echo "Running for Dimension: $dimension, Decoupe: $decoupe"
      DIMENSION=$dimension
      NB_DECOUPE=$decoupe

      $MATRIX_FOLDER/generate_makefile.pl $NB_DECOUPE > $MATRIX_FOLDER/Makefile
      $MATRIX_FOLDER/random_matrix.pl $DIMENSION $DIMENSION > $MATRIX_FOLDER/a
      $MATRIX_FOLDER/random_matrix.pl $DIMENSION $DIMENSION > $MATRIX_FOLDER/b

      for i in $(seq "$NB_ATTEMPTS"); do 
        echo "Attempt $i"

        $folder/../submit-job.sh $MATRIX_FOLDER/Makefile 2> /dev/null

        if [ $? -ne 0 ]; then
          echo "Error while submitting job"
          exit 1
        fi
        chmod +rwx ~/executionTime.txt
        # make clean
        echo "Cleaning up"
        make -C $MATRIX_FOLDER clean > /dev/null

        # First line is scheduling time, second line is execution time
        SCHEDULING_TIME=$(head -n 1 ~/executionTime.txt)
        EXECUTION_TIME=$(tail -n 1 ~/executionTime.txt)

        echo finished attempt $i
        echo "$nb_executors; $NB_CORES_PER_EXECUTOR; $NB_MEMORY_PER_EXECUTOR; $DIMENSION; $NB_DECOUPE; $SCHEDULING_TIME; $EXECUTION_TIME" >> $result_file
      done 
    done
  done
done

echo "Execution results are stored in $result_file"
