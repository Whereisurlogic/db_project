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

    #create type_db name_db password_db
    "create")

    if [ $# -ne 4 ]; then
    echo "The parameters are specified incorrectly"
    #тут нужен гайд по команде create
    exit 1
    fi

    if ! check_db_param "$2"; then
    echo "Can't find this type of db. Correct types: ${dbs_param[*]}"
    exit 1
    fi;;


    #start name_db
    "start")

    if [ $# -ne 2 ]; then
    echo "The parameters are specified incorrectly"
    #тут нужен гайд по команде start
    exit 1
    fi
    #логика start
    ;;

    #stop name_db
    "stop")

    if [ $# -ne 2 ]; then
    echo "The parameters are specified incorrectly"
    #тут нужен гайд по команде stop
    exit 1
    fi
    #логика stop
    ;;

    #delete name_db
    "delete")

    if [ $# -ne 2 ]; then
    echo "The parameters are specified incorrectly"
    #тут нужен гайд по команде delete
    exit 1
    fi
    #логика delete
    ;;

    #backup name_db path_to_save_backup
    "backup")

    if [ $# -ne 3 ]; then
    echo "The parameters are specified incorrectly"
    #тут нужен гайд по команде delete
    exit 1
    fi
    #логика delete
    ;;

    *)
    echo "No params" 
    #тут нужен полный гайд по командам
    ;;
esac


    





    
