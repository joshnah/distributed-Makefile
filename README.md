edt# Distributed makefile


## Connect on grid5000 
```bash
ssh login@access.grid5000.fr
cd grenoble
```
Or you can add the following lines in your ~/.ssh/config file:
```bash
Host g5k
  User <username>
  Hostname access.grid5000.fr
  ForwardAgent no

Host *.g5k
  User <username>
  ProxyCommand ssh g5k -W "$(basename %h .g5k):%p"
  ForwardAgent no
```
Then you can connect to grid5000 with the following command:
```bash
ssh <site>.g5k
```

Source: https://www.grid5000.fr/w/Getting_Started


## Deploy on grid5000

Connect to your one of the grid5000 frontend and clone the repository

```bash
wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz && tar zxvf spark-3.5.0-bin-hadoop3.tgz
```



Reserve nodes on grid5000, deploy spark on nodes and create a tunnel to access the spark web interface:

```
grid5000/reserve.sh 2 01:00:00  # 2 nodes for 1 hours
grid5000/deploy.sh
```

## Usage of make
```
usage: make [-h] [-f <makefile path>] [-m <spark master url>] [target...]

  -h                     print this help
  -f <makefile path>     specify the path to the makefile [default: Makefile]
  -m <spark master url>  specify the spark master url [default: spark disabled]
  target...              target names to run first [default: all]
```

## Submit a job from a client inside grid5000

Set up the environment variables:
```bash
export SPARK_HOME=/home/<username>/spark-3.5.0-bin-hadoop3
export PATH=$PATH:$SPARK_HOME/bin
```

Submit a job:
```bashtarget/scala-2.12/distributed-makefile_2.12-0.1.0-SNAPSHOT.jar
spark-submit distributed-makefile_2.12-0.1.0-SNAPSHOT.jar -m <master_address> -f <makefile>

Example: 

spark-submit distributed-makefile_2.12-0.1.0-SNAPSHOT.jar -m spark://"$(cat master_node)":7077 -f <makefile>
```

## Local development

```bash
sbt "run -m local -f <makefile>"  # submit a job locally
```


## UI Spark on local machine

To achieve this, we need a ssh tunnel to access the spark web interface. The spark web interface is available on the master node on port 8080. The spark master node is available on port 7077. The spark worker node is available on port 8081.

```bash
grid5000/ssh-tunnel.sh <spark-master> <spark-worker>
```

To clean up the ssh tunnel:
```bash
grid5000/clean-up.sh
```
## Submit a job from a client outside grid5000 (not recommended)

Add hosts into your /etc/hosts file

```bash
sudo echo "127.0.0.1 <master_hostname>" >> /etc/hosts
```

SSH tunnel to access the spark web interface
```bash
./ssh-tunnel.sh <spark-master-ip> <spark-worker-ip>
```
Submit a job
```bash
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
```bash
./clean-up.sh
sudo sed -i '/grid5000/d' /etc/hosts
```
