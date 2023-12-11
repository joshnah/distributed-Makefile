#get the master node
uniq $OAR_NODE_FILE | head -n 1 > master_node

# get the workers node
uniq $OAR_NODE_FILE | tail -n +2 > worker_nodes

# deploy
kadeploy3 -f $OAR_NODE_FILE   debian10-nfs-spark

# Configure spark config
taktuk -l root -f <( uniq $OAR_NODE_FILE ) broadcast exec [ "echo $(cat ~/worker_nodes) > /opt/spark-3.5.0-bin-hadoop3/conf/workers" ]
taktuk -l root -f <( uniq $OAR_NODE_FILE ) broadcast exec [ "echo SPARK_WORKER_INSTANCES=2 > /opt/spark-3.5.0-bin-hadoop3/conf/spark-env.sh" ]

# start spark
ssh $(cat master_node) "/opt/spark-3.5.0-bin-hadoop3/sbin/start-all.sh"

# submit the job
if [ -z "$1" ]
then
    ssh $(cat master_node) "/opt/spark-3.5.0-bin-hadoop3/bin/spark-submit /opt/spark-3.5.0-bin-hadoop3/distributed-makefile_2.12-0.1.0-SNAPSHOT.jar -m spark://$(cat ~/master_node):7077"
else
    ssh $(cat master_node) "/opt/spark-3.5.0-bin-hadoop3/bin/spark-submit /opt/spark-3.5.0-bin-hadoop3/distributed-makefile_2.12-0.1.0-SNAPSHOT.jar -m spark://$(cat ~/master_node):7077 -f $1"
fi

# stop spark
ssh $(cat master_node) "/opt/spark-3.5.0-bin-hadoop3/sbin/stop-all.sh"