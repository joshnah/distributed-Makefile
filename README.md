edt# Distributed makefile

## Dependencies

- [sbt](https://www.scala-sbt.org/index.html) for compiling, running, packaging our Scala project
Install spark on your front-end:

## Connect on grid5000 
```bash
ssh login@access.grid5000.fr
cd grenoble
```
## (On local terminal) Copy Files on grid5000
```bash
scp ./grid5000/deploy.sh login@access.grid5000.fr:grenoble
scp ./grid5000/reserve.sh login@access.grid5000.fr:grenoble
```
## Setup 
```bash
sbt
package
```

## Deploy on grid5000
```bash
wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz && tar zxvf spark-3.5.0-bin-hadoop3.tgz
```
Reserve nodes on grid5000, deploy spark on nodes and create a tunnel to access the spark web interface:

```
./reserve.sh 2 01:00:00  # 2 nodes for 1 hours
./deploy.sh
```


## Submit a job from a client outside grid5000

Add hosts into your /etc/hosts file
```
sudo echo "127.0.0.1 <master_hostname>" >> /etc/hosts
```
SSH tunnel to access the spark web interface
```
./ssh-tunnel.sh <spark-master-ip> <spark-worker-ip>
```
Submit a job
```
JAVA_HOME=/usr;spark-submit \
--class "Main" \
--deploy-mode cluster \
--master <master> \
--conf "spark.executor.extraJavaOptions=--add-exports java.base/sun.nio.ch=ALL-UNNAMED" \
--conf "spark.driver.extraJavaOptions=--add-exports java.base/sun.nio.ch=ALL-UNNAMED" \
< JAR file > \
-m <master> \
-f <makefile>

Examples: 
JAVA_HOME=/usr;spark-submit \
--class "Main" \
--deploy-mode cluster \
--master spark://dahu-2.grenoble.grid5000.fr:7077 \
--conf "spark.executor.extraJavaOptions=--add-exports java.base/sun.nio.ch=ALL-UNNAMED" \
--conf "spark.driver.extraJavaOptions=--add-exports java.base/sun.nio.ch=ALL-UNNAMED" \
--conf "spark.executorEnv.JAVA_HOME=/usr" \
--conf "spark.driverEnv.JAVA_HOME=/usr" \
/home/tiphan/distributed-makefile_2.12-0.1.0-SNAPSHOT.jar \
-m "spark://dahu-2.grenoble.grid5000.fr:7077" \
-f /home/tiphan/Makefile
``````


Clean up the hosts file and the ssh tunnel
```
sudo ./clean-up.sh
```
## Scheduling a program

```
sbt package

spark-submit --class "Main"  --master 'local[2]' target/scala-2.12/distributed-makefile_2.12-0.1.0-SNAPSHOT.jar -f <path_to_file> 
```
