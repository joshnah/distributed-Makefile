# Initial OAR submission
SUBMISSION_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d '{"resources": "nodes='$1'", "types": ["deploy"], "command": "sleep 3600"}' "https://api.grid5000.fr/stable/sites/grenoble/jobs")
job_uid=$(echo "$SUBMISSION_RESPONSE" | jq -r '.uid')

echo "Job submitted. UID: $job_uid"

# Loop to check the state
while true; do
    # Check the state of the job
    JOB_RESPONSE=$(curl -s "https://api.grid5000.fr/stable/sites/grenoble/jobs/$job_uid")
    JOB_STATE=$(echo "$JOB_RESPONSE" | jq -r '.state')

    # Print the current state
    echo "Current job state: $JOB_STATE"

    # Check if the state is "running"
    if [ "$JOB_STATE" == "running" ]; then
        echo "Job is now running."
        # Get the node list
        NODES=$(echo "$JOB_RESPONSE" | jq -r '.assigned_nodes[]')
        echo "Nodes: $NODES"
        # save the node list into a file
        echo "$NODES" > ~/oar_node_file
        # save first node into master file
        cat ~/oar_node_file | head -n 1 > ~/master_node
        # save other nodes into worker file
        cat ~/oar_node_file | tail -n +2 > ~/worker_nodes
        break
    fi

    # Sleep for 3 seconds before checking again
    sleep 3
done



# Deploy the environment

kadeploy3 -u tiphan -f ~/oar_node_file debian10-nfs-spark
