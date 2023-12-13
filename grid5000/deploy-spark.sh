#Usage
# ./deploy-spark.sh <number of instances>
if [ -z "$1" ]
then
    SPARK_WORKER_INSTANCES=$1
else
    SPARK_WORKER_INSTANCES=1
fi

# check if there is OAR_NODE_FILE
if [ ! -f ~/oar_node_file ]; then
    uniq $OAR_NODE_FILE > ~/oar_node_file
fi

# Configure spark config
taktuk -l root -f ~/oar_node_file broadcast exec [ ""echo $(cat ~/worker_nodes)" > /opt/spark-3.5.0-bin-hadoop3/conf/workers" ]
if [ -z "$1" ]
then
    taktuk -l root -f ~/oar_node_file broadcast exec [ "echo SPARK_WORKER_INSTANCES=$SPARK_WORKER_INSTANCES > /opt/spark-3.5.0-bin-hadoop3/conf/spark-env.sh" ]
fi

# start spark
ssh $(cat ~/master_node) "/opt/spark-3.5.0-bin-hadoop3/sbin/start-all.sh"
