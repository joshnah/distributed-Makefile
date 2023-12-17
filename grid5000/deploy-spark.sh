# usage ./deploy-spark.sh nb_executors cores_per_executor  memory_per_executor 
# example ./deploy-spark.sh 2 2 2G


# check if there is OAR_NODE_FILE
if [ ! -f ~/oar_node_file ]; then
    uniq $OAR_NODE_FILE > ~/oar_node_file
fi

if [ ! -z "$1" ]; then
    taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.instances=$1 >> /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]
fi

if [ ! -z "$2" ]; then
    taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.cores=$2 >> /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]
fi


if [ ! -z "$3" ]; then
    taktuk -l root -f ~/oar_node_file broadcast exec [ "echo spark.executor.memory=$3 >> /opt/spark-3.5.0-bin-hadoop3/conf/spark-defaults.conf" ]
fi


# Configure spark config
taktuk -l root -f ~/oar_node_file broadcast exec [ ""echo $(cat ~/worker_nodes)" > /opt/spark-3.5.0-bin-hadoop3/conf/workers" ]

# start spark
ssh $(cat ~/master_node) "/opt/spark-3.5.0-bin-hadoop3/sbin/start-all.sh"