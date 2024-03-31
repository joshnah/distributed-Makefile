# Distributed makefile
This repository builds a distributed make command with Spark and NFS on the network of grid5000
## Connect on grid5000 
```bash
ssh login@access.grid5000.fr
ssh grenoble
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


Clone this repository to your frontend/~ directory

## Image with spark
Image with spark is only available on site Grenoble grid5000.

!!!! Le program scala will produce the time execution file in the ~/executionTime.txt  !!!!
## Experiments

Reserve nodes and deploy image with spark
```bash
distributed-Makefile/grid5000/setup_make.sh <number of nodes> 
```

Run a specific experiment:
```bash
distributed-Makefile/grid5000/distributed-Makefile/grid5000/experiments run_experiment_matrix.sh  <number of iteration>
```

```bash
distributed-Makefile/grid5000/experiments run_experiment_premier.sh  <number of iteration>
```

```bash
distributed-Makefile/grid5000/experiments run_experiment_premier_small.sh  <number of iteration>
```

Results are available in these files:
- matrix_result.txt
- premier_result.txt
- premier_result_small.txt


### Run NFS performance measures:
You need to install the package `ggplot2` first in order to generate the plot.
```bash
~$ R
> install.packages("ggplot2")
> yes
> yes
> q()
```
And you can run the following script `~/distributed-Makefile/grid5000/measures/nfs/generate_latency_nfs_plots.sh`, `chmod u+x` this file if you don't have permission.



## Other scripts


Reserve nodes and deploy image with spark
```bash
distributed-Makefile/grid5000/deploy-spark.sh <nb_executors> <cores_per_executor> <memory_per_executor>
```

Deploy spark on the nodes:
```
./deploy-spark.sh nb_executors cores_per_executor  memory_per_executor 
```

Submit a makefile to compile:
```bash
distributed-Makefile/grid5000/submit-job.sh <Makefile>
```
Stop spark:
grid5000/stop-spark.sh
```

## UI Spark on local machine
To achieve this, we need a ssh tunnel to access the spark web interface. The spark web interface is available on the master node on port 8080. The spark master UI is available on port 7077. The spark worker UI 1 is available on port 8081. Spark UI application is available on port 4040.

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
