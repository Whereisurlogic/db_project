#!/bin/bash

dbs_type=("postgres" "mysql")
SCRIPT_NAME=$(basename "$0")

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

# Считывание пароля с безопасным вводом
read_password() {
    local prompt="$1"
    local password
    
    while true; do
        read -s -p "$prompt" password
        echo
        if [ -z "$password" ]; then
            echo "Пароль не может быть пустым. Попробуйте снова." >&2
        else
            read -s -p "Повторите пароль: " password2
            echo
            if [ "$password" = "$password2" ]; then
                echo "$password"
                return 0
            else
                echo "Пароли не совпадают. Попробуйте снова." >&2
            fi
        fi
    done
}

# PARAMS: $1 - db_type, $2 - db_name, $3 - pwd, $4 port; RETURNS: compose-file with folowing name "$1-$2-compose.yml", container name
create_compose() {
    local name_compose="$1-$2-compose.yml"

    if [ "${dbs_type[0]}" = "$1" ]; then
        cat > "$name_compose" << 'EOF'
services:
  postgres-db:
    image: postgres:latest
EOF
        cat >> "$name_compose" << EOF
    container_name: $2
    environment:
      POSTGRES_USER: '$2'
      POSTGRES_PASSWORD: '$3'
      POSTGRES_DB: '$2'
    ports:
      - "$4:5432"
    volumes:
      - ./$2:/var/lib/postgresql/data
    networks:
      - $2-net

networks:
  $2-net:
    driver: bridge
EOF

    elif [ "${dbs_type[1]}" = "$1" ]; then
        cat > "$name_compose" << 'EOF'
services:
  mysql-db:
    image: mysql:latest
EOF
        cat >> "$name_compose" << EOF
    container_name: $2
    environment:
      MYSQL_USER: '$2'
      MYSQL_PASSWORD: '$3'
      MYSQL_ROOT_PASSWORD: '$3'
      MYSQL_DATABASE: '$2'
    ports:
      - "$4:3306"
    volumes:
      - ./$2:/var/lib/mysql
    networks:
      - $2-net

networks:
  $2-net:
    driver: bridge
EOF

    else
        echo "Неизвестный тип БД: $1"
        return 1
    fi
}

# RETURNS: 0 if container exists, 1 if not
check_db_exists()
{
    if docker ps -aq -f name="^$1$" 2>/dev/null | grep -q .; then
        return 0  # контейнер существует
    else
        return 1  # контейнер не существует
    fi
}

# Create db with following params: $1 name, $2 pwd, $3 type
create_db()
{
    local container_name=$1

    if check_db_exists "$container_name"; then
        echo "Контейнер с таким именем уже существует"
        exit 1
    fi

    local free_port=$(find_free_port)
    if [ $? -ne 0 ]; then
        echo "$free_port"
        exit 1
    fi

    echo "Создаем БД $container_name типа $3 на порту $free_port..."
    
    if create_compose $3 $container_name "$2" $free_port; then
        echo "Compose файл создан"
        
        docker compose -f "$3-$1-compose.yml" up -d

        if [ $? -eq 0 ]; then
            echo "Контейнер собран успешно!"
            echo "Имя контейнера: $container_name"
            echo "Порт подключения: $free_port"
            echo "Тип БД: $3"
            echo "Имя БД: $container_name"
            echo "Пользователь: $container_name"
            echo "Пароль: ********"
            
            # Даем время контейнеру запуститься
            sleep 2
            
            # Проверяем статус
            if docker ps -f name="^$container_name$" | grep -q "Up"; then
                echo "Статус: Контейнер запущен и работает"
            else
                echo "Статус: Контейнер создан, но возможно не запустился"
                echo "Проверьте логи: docker logs $container_name"
            fi
        else
            echo "Ошибка при сборке контейнера"
            echo "Проверьте логи Docker"
        fi
    
        rm -f "$3-$1-compose.yml"
    else
        echo "Ошибка при создании compose файла"
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
    $SCRIPT_NAME create TYPE PROJECT

ПАРАМЕТРЫ:
    TYPE          Тип базы данных (${dbs_type[@]})
    PROJECT       Имя проекта/экземпляра

ПРИМЕЧАНИЕ:
    Пароль будет запрошен интерактивно с скрытым вводом

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
    if ! check_db_exists "$1"; then
        echo "Нет контейнера с именем \"$1\" для запуска."
        exit 1
    fi

    # Проверяем, запущен ли контейнер уже
    if docker inspect -f "{{.State.Running}}" "$1" 2>/dev/null | grep -q "true"; then
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
    if ! check_db_exists "$1"; then
        echo "Нет контейнера с именем \"$1\" для остановки."
        exit 1
    fi

    # Проверяем, остановлен ли контейнер уже
    if docker inspect -f "{{.State.Running}}" "$1" 2>/dev/null | grep -q "false"; then
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

    echo "Введите пароль для базы данных $3:"
    db_password=$(read_password "Пароль: ")
    
    create_db "$3" "$db_password" "$2"
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
    
    if ! check_db_exists "$2"; then
        echo "Нет контейнера с таким именем!"
        exit 1
    fi

    echo "Останавливаем контейнер $2..."
    docker stop "$2" >/dev/null 2>&1

    echo "Удаляем контейнер $2..."
    if docker rm "$2" >/dev/null 2>&1; then
        echo "Контейнер $2 успешно удален"
        # Удаляем папку с данными, если она существует
        if [ -d "./$2" ]; then
            rm -rf "./$2"
            echo "Папка с данными ./$2 удалена"
        fi
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
    
    if ! check_db_exists "$2"; then
        echo "Нет контейнера с таким именем! $2"
        exit 1
    fi

    if [ ! -d "$3" ] || [ ! -w "$3" ]; then
        echo "$3 не существует или нет прав на запись"
        exit 1
    fi

    # Определяем тип БД по образу контейнера
    image_name=$(docker inspect "$2" --format='{{.Config.Image}}' 2>/dev/null)
    time=$(date +%Y-%m-%d_%H-%M-%S)

    if [[ $image_name == *"postgres"* ]]; then
        echo "Создаем бэкап PostgreSQL контейнера $2..."
        docker exec "$2" pg_dump -U "$2" "$2" > "$3/${2}_${time}.sql"
        if [ $? -eq 0 ]; then
            echo "Бэкап успешно создан: $3/${2}_${time}.sql"
        else
            echo "Не удалось сделать бэкап PostgreSQL"
            rm -f "$3/${2}_${time}.sql"
            exit 1
        fi
    elif [[ $image_name == *"mysql"* ]]; then
        echo "Создаем бэкап MySQL контейнера $2..."
        # Используем bash -c для безопасной передачи пароля
        docker exec "$2" bash -c 'mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --single-transaction '"$2" > "$3/${2}_${time}.sql"
        
        if [ $? -eq 0 ]; then
            echo "Бэкап успешно создан: $3/${2}_${time}.sql"
        else
            echo "Не удалось сделать бэкап MySQL"
            rm -f "$3/${2}_${time}.sql"
            exit 1
        fi
    else
        echo "Неизвестный тип базы данных в контейнере $2"
        exit 1
    fi
    ;;

    *)
    usage_full
    ;;
esac
