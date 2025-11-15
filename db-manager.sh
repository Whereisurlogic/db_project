#!/bin/bash

dbs_type=("postgres" "mysql")

# RETURNS True if container exits, else False
check_db_exits()
{
    #$() - ожидание вывода ответа команды
    # ^ - начало имени файла $1 - подставляемый параметр $ - часть регулярного выражения, конца имени. Тем самым мы будем искать конкретное имя
    if [ $(docker ps -aq -f name=^$1$) ]; then
    return 1
    else return 0
    fi
}

#Create db with following params: $1 name, $2 pwd, $3 type
create_db()
{
    name_compose="$3-$1-compose.yml";
    container_name="$3-$1";

    check_db_exits "container_name";
}


# Проверка прав
check_sudo()
{
    if [[ $EUID -ne 0 ]]; then
    echo "Необходимы права root"
    exit 1
    fi
}

check_db_type()
{
    for db in "${dbs_type[@]}"; do
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


case "$1" in

    #create type_db name_db password_db
    "create")

    if [ $# -ne 4 ]; then
    echo "Параметры указаны неправильно"
    usage_create
    exit 1
    fi

    if ! check_db_param "$2"; then
    echo "Не удается найти этот тип базы данных. Правильные типы: ${dbs_type[*]}"
    exit 1
    fi
    
    if check_db_exits "$3"; then
    echo "Контейнер с таким именем уже существует"
    exit 1
    fi
    ;;


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