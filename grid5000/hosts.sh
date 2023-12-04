#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <master_hostname> <worker_hostname>"
    exit 1
fi

echo "127.0.0.1 $1" >> /etc/hosts
echo "127.0.0.1 $2" >> /etc/hosts
