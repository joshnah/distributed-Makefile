
#get the master node
uniq $OAR_NODE_FILE | head -n 1 > master_node
# get the workers node
uniq $OAR_NODE_FILE | tail -n +2 > worker_nodes

# taktuk on master node
TAKTUK_MASTER="./spark-3.5.0-bin-hadoop3/sbin/start-master.sh ; \
    uniq worker_nodes > /tmp/worker_nodes_list ; \
    taktuk -f /tmp/worker_nodes_list broadcast exec \[ \
    ./spark-3.5.0-bin-hadoop3/sbin/start-worker.sh spark://\$(hostname -i):7077 \]"

# deploy
kadeploy3 -f $OAR_NODE_FILE -e debian10-nfs	 -k

# install java on all nodes
taktuk -l root -f <( uniq $OAR_NODE_FILE ) broadcast exec [ "apt update && apt install default-jre -y" ] 

# launch master node
taktuk -f <( uniq master_node ) broadcast exec [ $TAKTUK_MASTER ]
