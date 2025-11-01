#!/bin/bash

dbs_param=("postgres" "mysql")

check_db_param()
{
    for db in "${dbs_param[@]}"; do
        if [[ "$db" == "$1" ]]; then
        return 0
        fi
    done
    return 1
}

usage_create()      #гайд по команде create
{
cat << EOF
Создание изолированного экземпляра базы данных

USAGE:
    $SCRIPT_NAME create TYPE PROJECT PASSWORD

ПАРАМЕТРЫ:
    TYPE          Тип базы данных (postgres, mysql)
    PROJECT       Имя проекта/экземпляра
    PASSWORD      Пароль для базы данных

EOF
}

usage_start()       #гайд по команде start
{
    cat << EOF
Запуск существующего экземпляра базы данных

USAGE:
    $SCRIPT_NAME start [OPTIONS]

ОПЦИИ:
    -p, --project NAME       Имя проекта для запуска
    -h, --help               Показать эту справку

EOF
}

usage_stop()        #гайд по команде stop
{
    cat << EOF
Остановка экземпляра базы данных

USAGE:
    $SCRIPT_NAME stop [OPTIONS]

ОПЦИИ:
    -p, --project NAME       Имя проекта для остановки
    -h, --help               Показать эту справку

EOF
}

usage_delete()      #гайд по команде delete
{
    cat << EOF
Удаление экземпляра базы данных

USAGE:
    $SCRIPT_NAME delete [OPTIONS]

ОПЦИИ:
    -p, --project NAME       Имя проекта для удаления
    -h, --help               Показать эту справку

EOF
}

usage_full()        #полный гайд по командам
{
    cat << EOF
Менеджер изолированных баз данных

USAGE:
    $SCRIPT_NAME COMMAND [OPTIONS]

КОМАНДЫ:
    create    Создать новый экземпляр базы данных
    start     Запустить существующий экземпляр
    stop      Остановить экземпляр
    delete    Удалить экземпляр
    backup    Резервное копирование экземпляра

EOF
}

usage_backup()      #гайд по команде backup
{
 cat << EOF
Резервное копирование экземпляра базы данных

USAGE:
    $SCRIPT_NAME backup PROJECT BACKUP_PATH

ПАРАМЕТРЫ:
    PROJECT      Имя проекта для резервного копирования
    BACKUP_PATH  Путь для сохранения резервной копии

EOF
}

#логика
case "$1" in

    #create type_db name_db password_db
    "create")

    if [ $# -ne 4 ]; then
    echo "The parameters are specified incorrectly"
    usage_create
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
    usage_start
    exit 1
    fi
    #логика start
    ;;

    #stop name_db
    "stop")

    if [ $# -ne 2 ]; then
    echo "The parameters are specified incorrectly"
    usage_stop
    exit 1
    fi
    #логика stop
    ;;

    #delete name_db
    "delete")

    if [ $# -ne 2 ]; then
    echo "The parameters are specified incorrectly"
    usage_delete
    exit 1
    fi
    #логика delete
    ;;

    #backup name_db path_to_save_backup
    "backup")

    if [ $# -ne 3 ]; then
    echo "The parameters are specified incorrectly"
    usage_backup
    exit 1
    fi
    #логика backup
    ;;

    *)
    echo "No params" 
    usage_full
    ;;
esac