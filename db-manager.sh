#!/bin/bash

dbs_param=("postgres" "mysql")

#Create db with following params: $1 name, $2 pwd, $3 type
create_db()
{
    name_compose="$3-$1-compose.yml";

    if [[ -f "$name_compose" ]]; then
        echo "База данных с такими же параметрами уже существует. Переменуйте"
        exit 1
    fi
}


# Проверка прав
check_sudo()
{
    if [[ $EUID -ne 0 ]]; then
    echo "Необходимы права root"
    exit 1
    fi
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

usage_create()      #гайд по команде create
{
cat << KEFTEME
Создание изолированного экземпляра базы данных

ИСПОЛЬЗОВАНИЕ:
    $SCRIPT_NAME create TYPE PROJECT PASSWORD

ПАРАМЕТРЫ:
    TYPE          Тип базы данных (postgres, mysql)
    PROJECT       Имя проекта/экземпляра
    PASSWORD      Пароль для базы данных

KEFTEME
}

usage_start()       #гайд по команде start
{
    cat << KEFTEME
Запуск существующего экземпляра базы данных

ИСПОЛЬЗОВАНИЕ:
    $SCRIPT_NAME start [ПАРАМЕТРЫ]

ПАРАМЕТРЫ:
    PROJECT NAME       Имя проекта для запуска

KEFTEME
}

usage_stop()        #гайд по команде stop
{
    cat << KEFTEME
Остановка экземпляра базы данных

ИСПОЛЬЗОВАНИЕ:
    $SCRIPT_NAME stop [ПАРАМЕТРЫ]

ПАРАМЕТРЫ:
    PROJECT NAME       Имя проекта для остановки

KEFTEME
}

usage_delete()      #гайд по команде delete
{
    cat << KEFTEME
Удаление экземпляра базы данных

ИСПОЛЬЗОВАНИЕ:
    $SCRIPT_NAME delete [ПАРАМЕТРЫ]

ПАРАМЕТРЫ:
    PROJECT NAME       Имя проекта для удаления

KEFTEME
}

usage_full()        #полный гайд по командам
{
    cat << KEFTEME
Менеджер изолированных баз данных

ИСПОЛЬЗОВАНИЕ:
    $SCRIPT_NAME КОМАНДА [ПАРАМЕТРЫ]

КОМАНДЫ:
    create    Создать новый экземпляр базы данных
    start     Запустить существующий экземпляр
    stop      Остановить экземпляр
    delete    Удалить экземпляр
    backup    Резервное копирование экземпляра

KEFTEME
}

usage_backup()      #гайд по команде backup
{
 cat << KEFTEME
Резервное копирование экземпляра базы данных

ИСПОЛЬЗОВАНИЕ:
    $SCRIPT_NAME backup PROJECT BACKUP_PATH

ПАРАМЕТРЫ:
    PROJECT      Имя проекта для резервного копирования
    BACKUP_PATH  Путь для сохранения резервной копии

KEFTEME
}

check_sudo

#логика
case "$1" in

    #create type_db name_db password_db
    "create")

    if [ $# -ne 4 ]; then
    echo "Параметры указаны неправильно"
    usage_create
    exit 1
    fi

    if ! check_db_param "$2"; then
    echo "Не удается найти этот тип базы данных. Правильные типы: ${dbs_param[*]}"
    exit 1
    fi;;


    #start name_db
    "start")

    if [ $# -ne 2 ]; then
    echo "Параметры указаны неправильно"
    usage_start
    exit 1
    fi
    #логика start
    ;;

    #stop name_db
    "stop")

    if [ $# -ne 2 ]; then
    echo "Параметры указаны неправильно"
    usage_stop
    exit 1
    fi
    #логика stop
    ;;

    #delete name_db
    "delete")

    if [ $# -ne 2 ]; then
    echo "Параметры указаны неправильно"
    usage_delete
    exit 1
    fi
    #логика delete
    ;;

    #backup name_db path_to_save_backup
    "backup")

    if [ $# -ne 3 ]; then
    echo "Параметры указаны неправильно"
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