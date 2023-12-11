#Usage
# ./deploy-spark.sh <number of instances>
if [ -z "$1" ]
then
    SPARK_WORKER_INSTANCES=$1
else
    SPARK_WORKER_INSTANCES=1
fi

# get the master node
uniq $OAR_NODE_FILE | head -n 1 > ~/master_node

# get the workers node
uniq $OAR_NODE_FILE | tail -n +2 > ~/worker_nodes

# Configure spark config
taktuk -l root -f <( uniq $OAR_NODE_FILE ) broadcast exec [ "echo $(cat ~/worker_nodes) > /opt/spark-3.5.0-bin-hadoop3/conf/workers" ]
taktuk -l root -f <( uniq $OAR_NODE_FILE ) broadcast exec [ "echo SPARK_WORKER_INSTANCES=$SPARK_WORKER_INSTANCES > /opt/spark-3.5.0-bin-hadoop3/conf/spark-env.sh" ]

# start spark
ssh $(cat ~/master_node) "/opt/spark-3.5.0-bin-hadoop3/sbin/start-all.sh"
