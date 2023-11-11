# Distributed makefile

## Dependencies

- [sbt](https://www.scala-sbt.org/index.html) for compiling, running, packaging our Scala project
Install spark on your front-end:


## Deploy on grid5000
```bash
wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz && tar zxvf spark-3.5.0-bin-hadoop3.tgz
```
Reserve nodes on grid5000, deploy spark on nodes and create a tunnel to access the spark web interface:

```
./reserve.sh 2 01:00:00  # 2 nodes for 1 hours
./deploy.sh
ssh tiphan@access.grid5000.fr -N -f  -L 8080:$ip_master_node:8080
```
