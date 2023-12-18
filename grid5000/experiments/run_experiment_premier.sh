# Run the matrix multiplication experiment on Grid5000 proving that spark is deployed correctly
# Final result is stored in execution_time_result.txt
result_file="premier_result.txt"
execution_file="~/executionTime.txt"
folder=$(pwd)/$(dirname "${BASH_SOURCE[0]}")   
echo "folder: $folder"
PREMIER_FOLDER=$folder/../../makefiles/premier
NB_ATTEMPTS=5

# if NB_ATTEMPTS is provided
if [ ! -z "$1" ]; then
  NB_ATTEMPTS=$1
fi

# Clean up the result file
> $result_file
echo "nb_executors; nb_cores_per_executor; nb_memory_per_executor, Execution Time" >> $result_file
TOTAL_CORES=64
NB_MEMORY_PER_EXECUTOR="1g"
gcc -o $PREMIER_FOLDER/premier $PREMIER_FOLDER/premier.c -lm
# loop through value of nb_executors 2 4 8 16 32  
for nb_executors in {1,2,4}; do
  NB_CORES_PER_EXECUTOR=$(($TOTAL_CORES / $nb_executors))
  echo "Running for nb_executors: $nb_executors, nb_cores_per_executor: $NB_CORES_PER_EXECUTOR, nb_memory_per_executor: $NB_MEMORY_PER_EXECUTOR"

  taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.instances=$nb_executors > /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]
  taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.cores=$NB_CORES_PER_EXECUTOR >> /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]
  taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.memory=$NB_MEMORY_PER_EXECUTOR >> /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]

  for i in $(seq "$NB_ATTEMPTS"); do 
    echo "Attempt $i"

    $folder/../submit-job.sh $PREMIER_FOLDER/Makefile 2> /dev/null

    if [ $? -ne 0 ]; then
      echo "Error while submitting job"
      exit 1
    fi
    
    # make clean
    echo "Cleaning up"
    make -C $PREMIER_FOLDER clean > /dev/null

    # First line is scheduling time, second line is execution time
    SCHEDULING_TIME=$(head -n 1 $execution_file)
    EXECUTION_TIME=$(tail -n 1 $execution_file)

    echo finished attempt $i
    echo "$nb_executors; $NB_CORES_PER_EXECUTOR; $NB_MEMORY_PER_EXECUTOR; $EXECUTION_TIME" >> $result_file

  done
done

echo "Execution results are stored in $result_file"
