#!/bin/bash

dbs_type=("postgres" "mysql")


# PARAM $1 - имя контейнера
delete_net() {

    local name-net="$1-net"

}

find_free_port() {
    local port
    
    for port in {5000..6000}; do
        
        if ! nc -z localhost $port >/dev/null 2>&1; then
            
            if ! docker ps -a --format "table {{.Ports}}" | grep -q ":${port}->"; then
                echo $port
                return 0
            fi
        fi
    done
    echo "Не удалось найти свободный порт" >&2
    return 1
}

# PARAMS: $1 - db_type, $2 - db_name, $3 - pwd, $4 port; RETURNS: compose-file with folowing name "$1-$2-compose.yml", container name
create_compose() {
    local name_compose="$1-$2-compose.yml"

    if [ "${dbs_type[0]}" = "$1" ]; then
        local type="${dbs_type[0]}"

        cat > "$name_compose" << EOF
services:
 $2-db:
  image: $type:latest
  container_name: $2
  environment:
   POSTGRES_USER: $2
   POSTGRES_PASSWORD: $3
   POSTGRES_DB: $2
  ports:
   - "$4:5432"
  volumes:
   - /var/lib/docker/volumes/$2:/var/lib/postgresql
  networks:
   - $2-net

networks:
 $2-net:
  driver: bridge
EOF


    elif [ "${dbs_type[1]}" = "$1" ]; then
        local type="${dbs_type[1]}"
        cat > "$name_compose" << EOF
services:
 $2-db:
  image: $type:latest
  container_name: $2
  environment:
   MYSQL_USER: $2
   MYSQL_PASSWORD: $3
   MYSQL_ROOT_PASSWORD: $3
   MYSQL_DATABASE: $2
  ports:
   - ":$4:3306"
  volumes:
   - /var/lib/docker/volumes/$2:/var/lib/mysql
  networks:
   - $2-net

networks:
 $2-net:
  driver: bridge
  name: $2-net
EOF

    else
        echo "Неизвестный тип БД: $1"
        return 1
    fi

}


# RETURNS True if container exits, else False
check_db_exits()
{
    #$() - ожидание вывода ответа команды
    # ^ - начало имени файла $1 - подставляемый параметр $ - часть регулярного выражения, конца имени. Тем самым мы будем искать конкретное имя
    if [ $(docker ps -aq -f name="^$1$") ]; then
    return 1
    else return 0
    fi
}

#Create db with following params: $1 name, $2 pwd, $3 type
create_db()
{
    local container_name=$1;

    if ! check_db_exits "$container_name"; then
    echo "Контейнер с таким именем уже существует"
    exit 1
    fi

    local free_port=$(find_free_port)

    if create_compose $3 $container_name $2 $free_port; then

    docker compose -f "$3-$1-compose.yml" up -d >/dev/null 2>&1


        if [ $? -eq 0 ]; then

        echo "Контейнер собран успешно!"
        echo "Имя контейнера: $container_name"
        echo "Порт подключения: $free_port:(порт по умолчанию для бд)"
        echo "Имя бд совпадает с именем контейнера"
        echo "Логин пользователя совпадает с именем контейнера"
        echo "Пароль: $2"
        

        
        else
        echo "Что-то пошло не так при сборке контейнера"
        fi
    
    rm -f "$3-$1-compose.yml"

    else

    echo "Что-то пошло не так при поиске сгенирированного compose файла"
    exit 0
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
    TYPE          Тип базы данных (${dbs_type[@]})
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

start_db() { # логика команды start
  if check_db_exits "$1"; then
    echo "Нет контейнера с именем \"$1\" для запуска."
    exit 1
  fi

  # Проверяем, запущен ли контейнер уже
  if docker inspect -f "{{.State.Running}}" "$1" | grep -q "true"; then
    echo "Контейнер \"$1\" уже запущен."
    exit 0
  fi

  echo "Запускаем контейнер \"$1\"..."
  if docker start "$1" >/dev/null 2>&1; then
    echo "Контейнер \"$1\" успешно запущен."
  else
    echo "Не удалось запустить контейнер \"$1\"."
    exit 1
  fi
}

stop_db() { # логика команды stop
    if check_db_exits "$1"; then
    echo "Нет контейнера с именем \"$1\" для остановки."
    exit 1
  fi

  # Проверяем, остановлен ли контейнер уже
  if docker inspect -f "{{.State.Running}}" "$1" | grep -q "false"; then
    echo "Контейнер \"$1\" уже остановлен."
    exit 0
  fi

  echo "Останавливаем контейнер \"$1\"..."
  if docker stop "$1" >/dev/null 2>&1; then
    echo "Контейнер \"$1\" успешно остановлен."
  else
    echo "Не удалось остановить контейнер \"$1\"."
    exit 1
  fi
}

case "$1" in

    #create type_db name_db
    "create")

    if [ $# -ne 3 ]; then
    echo "Параметры указаны неправильно"
    usage_create
    exit 1
    fi

    if ! check_db_type "$2"; then
    echo "Не удается найти данный ($2) тип базы данных. Правильные типы: ${dbs_type[*]}"
    exit 1
    fi

    read -sp "Введите пароль: " password_db #https://www.geeksforgeeks.org/linux-unix/bash-script-read-user-input/
    echo

    create_db $3 $password_db $2
    ;;


    #start name_db
    "start")
    if [ $# -ne 2 ]; then
    echo "Параметры указаны неправильно"
    usage_start
    exit 1
    fi

    start_db "$2"
    ;;

    #stop name_db
    "stop")

    if [ $# -ne 2 ]; then
    echo "Параметры указаны неправильно"
    usage_stop
    exit 1
    fi
    
    stop_db "$2"
    ;;

    #delete name_db
    "delete")

    if [ $# -ne 2 ]; then
    echo "Параметры указаны неправильно"
    usage_delete
    exit 1
    fi
    
    if check_db_exits "$2"; then
    echo "Нет контейнера с таким именем!"
    exit 1
    fi

    
    docker stop "$2" >/dev/null 2>&1


    if docker rm "$2" >/dev/null 2>&1; then
    docker volume prune -f >/dev/null 2>&1
    docker network prune -f >/dev/null 2>&1
    echo "Контейнер $2 успешно удален"
    else
    echo "Не удалось удалить контейнер $2"
    exit 1
    fi

    ;;

    #backup name_db path_to_save_backup
    "backup")

    if [ $# -ne 3 ]; then
    echo "Параметры указаны неправильно"
    usage_backup
    exit 1
    fi
    #логика backup
    
    if check_db_exits "$2"; then
    echo "Нет контейнера с таким именем! $2"
    exit 1
    fi


    if [ ! -d "$3" ]; then
    echo "$3 не существует такого пути"
    exit 1
    fi


    db_type=$(docker inspect "$2" --format='{{index .Config.Labels "com.docker.compose.service"}}')
    time=$(date +%Y-%m-%d_%H-%M-%S)

    if [ -n "$db_type" ]; then
        case "$db_type" in
            "postgres-db")
                docker exec "$2" pg_dump -U "$2" "$2" > "$3/${2}_${time}.sql"
            ;;
            "mysql-db")

            docker exec -i "$2" mysqldump -u root --single-transaction -p "$2" > "$3/${2}_${time}.sql" # --single-transaction - изолирует процесс 
            ;;
            *)
            echo "Неизвестный тип БД: $db_type"
            exit 1
            ;;
        esac

        if [ $? -eq 0 ]; then
        echo "Бэкап успешно создан: $3/${2}_${time}.sql"
        else
        echo "Не удалось сделать бекап"
        rm -f "$3/${2}_${time}.sql"
        exit 1
        fi

    fi

    ;;

    

    *)
    usage_full
    ;;
esac


#Забавно, что тут нет булевых типов данных. условные выражения проверяют выполнился ли код или нет. Т.е. 0 - это хорошо выполнился, 1 - что то не так.
#https://stackoverflow.com/questions/19670061/bash-if-false-returns-true-instead-of-false-why
