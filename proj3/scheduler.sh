#!/bin/bash

NUMBER_OF_VMS=3
SERVER_NAME=$(hostname)
tmp=$(hostname)
my_num=${tmp: -1}
current_date=$(date '+%Y-%m-%d_%H-%M-%S')
date=$(date '+%Y-%m-%d')
message="Created by ${SERVER_NAME} at ${current_date}"

remote_file="data/log_by_${SERVER_NAME}_${date}.log"

for i in $(seq 1 $NUMBER_OF_VMS); do
    HOST="vm${i}.vmnet"

    ssh-keyscan -H $HOST >> ~/.ssh/known_hosts 2>/dev/null

    if [ "$i" -eq "$my_num" ]; then
        continue
    fi

    ssh -i ~/id_ed25519 sftpuser@$HOST "
        mkdir -p data
        if [ -f $remote_file ]; then
            echo '${message}' >> $remote_file
        else
            echo '${message}' > $remote_file
        fi
    "
done
