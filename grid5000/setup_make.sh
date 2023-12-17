#!/bin/bash
# Script to reserve nodes, deploy the environment and compile a list of makefiles
if [ $# -eq 0 ]; then
    echo "Usage: ./deploy-run.sh <nb_nodes> <file containing makefiles paths>"
    exit 1
fi

# check if nb_nodes is > 2
if [ $1 -lt 2 ]; then
    echo "nb_nodes must be > 2"
    exit 1
fi


folder=$(dirname "${BASH_SOURCE[0]}")

# Reserve nodes and deploy image with kadeploy3
$folder/reserve-deploy.sh $1

# Copy the jar file to the nodes
$folder/copy_file_to_nodes.sh $folder/../distributed-makefile_2.12-0.1.0-SNAPSHOT.jar /opt/spark-3.5.0-bin-hadoop3/

# Deploy Spark
$folder/deploy-spark.sh

if [ ! -z "$2" ];
then
    $folder/submit-makefiles.sh $2
fi