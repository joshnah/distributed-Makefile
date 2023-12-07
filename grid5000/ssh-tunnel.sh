if [ $# -ne 2 ]; then
    echo "Usage: $0 <spark-master-ip> <spark-worker-ip>"
    exit 1
fi
ssh tiphan@access.grid5000.fr -N -f -L 8080:$1:8080
ssh tiphan@access.grid5000.fr -N -f -L 7077:$1:7077
ssh tiphan@access.grid5000.fr -N -f -L 8081:$2:8081
ssh tiphan@access.grid5000.fr -N -f -L 4040:$1:4040
