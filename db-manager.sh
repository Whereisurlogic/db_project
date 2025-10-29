#!/bin/bash

dbs_param=("postgres" "mysql")

#usage function
usage() {
    ec
}

check_db_param()
{
    for db in "${dbs_param[@]}"; do
        if [[ "$db" == "$1" ]]; then
        return 0
        fi
    done
    return 1
}


case "$1" in
    "create")

    if [ $# -ne 4 ]; then
    echo "One of the parameters is missing"
    exit 1
    fi

    if ! check_db_param "$2"; then
    echo "Can't find this type of db. Correct types: ${dbs_param[*]}"
    exit 1
    fi;;

    *)
    echo "No params"
esac


    





    
