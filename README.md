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


## Scripts
Reserve nodes:
```bash 
oarsub -t deploy -I -l nodes=2,walltime=2
```
Deploy spark on the nodes:
```
grid5000/deploy-spark.sh
```

Deploy spark and submit a job:
```
grid5000/deploy-run.sh <makefile>
```


Submit a job:
```bash
grid5000/submit.sh <makefile>
```

Stop spark:
```
grid5000/stop-spark.sh
```

## UI Spark on local machine

To achieve this, we need a ssh tunnel to access the spark web interface. The spark web interface is available on the master node on port 8080. The spark master UI is available on port 7077. The spark worker UI 1 is available on port 8081.

```bash
grid5000/ssh-tunnel.sh <spark-master> <spark-worker>
```

To clean up the ssh tunnel:
```bash
grid5000/clean-up.sh
```
## Local development

```bash
sbt "run -m local -f <makefile>"  # submit a job locally
```
