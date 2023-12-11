if [ -z "$1" ]
then
    ssh $(cat ~/master_node) "/opt/spark-3.5.0-bin-hadoop3/bin/spark-submit /opt/spark-3.5.0-bin-hadoop3/distributed-makefile_2.12-0.1.0-SNAPSHOT.jar -m spark://$(cat ~/master_node):7077"
else
    ssh $(cat ~/master_node) "/opt/spark-3.5.0-bin-hadoop3/bin/spark-submit /opt/spark-3.5.0-bin-hadoop3/distributed-makefile_2.12-0.1.0-SNAPSHOT.jar -m spark://$(cat ~/master_node):7077 -f $1"
fi