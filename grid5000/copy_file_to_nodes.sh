# move file to every node

if [ $# -ne 2 ]; then
    echo "Usage: ./copy_file_to_nodes.sh <file> <destination>"
    exit 1
fi
# check if $1 exists
if [ ! -f $1 ]; then
    echo "$1 does not exist"
    exit 1
fi
for node in $(cat ~/oar_node_file); do
    scp $1 root@$node:$2
done