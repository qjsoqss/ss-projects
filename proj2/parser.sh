#!/bin/bash

path_file=$1

process_pids() {
    local pid_array=($(awk '/\[pid/{print $5}' "$path_file" | sed 's/]//' | sort -u))
    local valid_pids=()
    local invalid_pids=()
    
    for i in "${pid_array[@]}"; do
        local temp_pid_info=$(awk "/$i/" "$path_file")
        if [[ "$temp_pid_info" =~ (ERROR|Failed|Timeout|Removed) ]]; then
            pid_array=("${pid_array[@]/$i}") 
            invalid_pids+=("$i") 
        else
            valid_pids+=("$i")
        fi
    done
    echo "Invalid Pids: ${#invalid_pids[@]}"
    echo "${#valid_pids[@]} Pids"
}

process_passwords() {
    local passwords=($(grep -E "'[a-z_]*pass' => '" "$path_file" | awk -F"'" '{print $(NF-1)}' | sort))
    local html_passwords=($(awk -F'value="' '/id="admin_pass"/ {print $2}' "$path_file" | cut -d '"' -f1))

    passwords+=("${html_passwords[@]}") 

    for i in "${passwords[@]}"; do

        echo "Password: $i"
        
        if [[ "${#i}" -lt 8 ]]; then
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
