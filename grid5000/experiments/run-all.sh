folder=$(pwd)/$(dirname "${BASH_SOURCE[0]}")   
NB_ATTEMPTS=10
# run experiment with each number of nodes on arguments
for nb_nodes in "$@" 
do
    $folder/../setup_make.sh $nb_nodes
    $folder/run_experiment_matrix.sh $NB_ATTEMPTS
    $folder/run_experiment_premier_small.sh $NB_ATTEMPTS
    $folder/run_experiment_premier.sh $NB_ATTEMPTS
    echo "$nb_nodes" >> result
    echo matrix_result.txt" >> result
    cat matrix_result.txt >> result
    echo premier_result_small.txt" >> result
    cat premier_result_small.txt >> result
    oardel $(cat ~/job_uid)

done