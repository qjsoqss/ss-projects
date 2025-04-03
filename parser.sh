#!/bin/bash

path_file=$1

process_pids() {
    local pid_array=($(awk '/\[pid/{print $5}' "$path_file" | sed 's/]//' | sort -u))
    
    for i in "${pid_array[@]}"; do
        local temp_pid_info=$(awk "/$i/" "$path_file")
        if [[ "$temp_pid_info" =~ (ERROR|Failed|Timeout) ]]; then
            pid_array=("${pid_array[@]/$i}")  
            echo "Pid $i Failed"
        fi
    done

    echo "${#pid_array[@]} Pids"
}

process_passwords() {
    local passwords=($(grep -E "'(admin_pass|softdbpass)' => '" "$path_file" | awk -F"'" '{print $(NF-1)}' | sort))

    for i in "${passwords[@]}"; do

        echo "Password: $i"
        
        if [[ ${#i} -lt 8 ]]; then
            echo "Password is short"
        elif [[ ! "$i" =~ [A-Z] ]]; then
            echo "Capital letter is absent"
        elif [[ ! "$i" =~ [a-z] ]]; then
            echo "Lower letter is absent"
        elif [[ ! "$i" =~ [0-9] ]]; then
            echo "Number is absent"
        elif [[ ! "$i" =~ [^a-zA-Z0-9] ]]; then
            echo "Special character is absent"
        else
            echo "Password is robust"
        fi
    done
}

process_pids
process_passwords
