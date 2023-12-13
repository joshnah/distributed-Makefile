#!/bin/bash
# Script to reserve nodes, deploy the environment and compile the makefile
if [ $# -ne 2 ]; then
    echo "Usage: ./deploy-run.sh <nb_nodes> <absolute_path_to_make_file>"
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

# Deploy Spark
$folder/deploy-spark.sh 1

# Submit the job
$folder/submit-job.sh $2