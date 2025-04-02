#!/bin/bash

path_file=$1

pid_array=($(awk '/\[pid/{print $5}' "$path_file" | sed 's/]//' | sort -u))
for i in "${pid_array[@]}"; do
    temp_pid_info=$(awk "/$i/" $path_file)
    if [[ "$temp_pid_info" =~ (ERROR|Failed|Timeout) ]]; then
        pid_array=("${pid_array[@]/$i}")  
        echo "Pid $i Failed"
    fi
done
echo "${#pid_array[@]} Pids" 
