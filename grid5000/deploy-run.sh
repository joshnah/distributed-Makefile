echo Usage: ./deploy-run.sh \<path to makefile\>

# deploy
kadeploy3 -u tiphan -f $OAR_NODE_FILE   debian10-nfs-spark

folder=$(dirname "${BASH_SOURCE[0]}")

$folder/deploy-spark.sh

# submit the job
$folder/submit-job.sh $1
