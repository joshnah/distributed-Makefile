if [ $# -lt 2 ]
then
    printf 'help: %s <NR_NODES> <WALLTIME_SPEC> ' $(basename $0)
    exit 1
fi

oarsub  -I -l nodes=$1,walltime=$2
# -I: interactive mode
# -l: resource specification
# -t: job type