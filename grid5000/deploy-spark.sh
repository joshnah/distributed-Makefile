# check if there is OAR_NODE_FILE
if [ ! -f ~/oar_node_file ]; then
    uniq $OAR_NODE_FILE > ~/oar_node_file
fi

# Configure spark config
taktuk -l root -f ~/oar_node_file broadcast exec [ ""echo $(cat ~/worker_nodes)" > /opt/spark-3.5.0-bin-hadoop3/conf/workers" ]

# start spark
ssh $(cat ~/master_node) "/opt/spark-3.5.0-bin-hadoop3/sbin/start-all.sh"