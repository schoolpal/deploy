#!/bin/bash
set -e

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)
DEPLOY_ROOT=${WORK_DIR}/../
REPOS_DIR=${DEPLOY_ROOT}/repos

DOCKER_VOLUME=~/docker-volume

VOLUME_INITSQL=init-sql
VOLUME_DATA=data
VOLUME_LOGS=logs
VOLUME_DIRS="${VOLUME_INITSQL} ${VOLUME_DATA} ${VOLUME_LOGS}"

PORT_NGINX=80
PORT_TOMCAT=8080
PORT_REDIS=6379
PORT_MYSQL=3306

PROJECT_NAME=schoolpal
REFRESH_DATABASE="N"

DOCKER_COMPOSE_FILE_TPL=${WORK_DIR}/docker-compose.tpl.yml
DOCKER_COMPOSE_FILE=${WORK_DIR}/docker-compose.yml

############################ Check options #################################
#Auto-generated by http://getoptgenerator.dafuer.es/

# Define help function
function help(){
    echo "schoolpal-deploy - For schoolpal deploy script";
    echo "Usage example:";
    echo "schoolpal-deploy [(-h|--help)] [(-v|--docker-volume) string] [(-n|--nginx-port) integer] [(-t|--tomcat-port) integer] [(-r|--redis-port) integer] [(-m|--mysql-port) integer] [(-p|--project-name) string] [--refresh-database]";
    echo "Options:";
    echo "-h or --help: Displays this information.";
    echo "-v or --docker-volume string: Root path of docker volumes, default: ~/docker-volume.";
    echo "-n or --nginx-port integer: Nginx port mapping, default: 80.";
    echo "-t or --tomcat-port integer: Tomcat port mapping, default: 8080.";
    echo "-r or --redis-port integer: Redis port mapping, default: 6379.";
    echo "-m or --mysql-port integer: Mysql port mapping, default: 3306.";
    echo "-p or --project-name string: Docker-compose project name, default: schoolpal.";
    echo "--refresh-database: Reset and restore database with standard data.";
    exit 1;
}
 
# Execute getopt
ARGS=$(getopt -o "hv:n:t:r:m:p:" -l "help,docker-volume:,nginx-port:,tomcat-port:,redis-port:,mysql-port:,project-name:,refresh-database" -n "schoolpal-deploy" -- "$@");
 
#Bad arguments
if [ $? -ne 0 ];
then
    help;
fi
 
eval set -- "$ARGS";
 
while true; do
    case "$1" in
        -h|--help)
            shift;
            help;
            ;;
        -v|--docker-volume)
            shift;
                    if [ -n "$1" ]; 
                    then
                        DOCKER_VOLUME="$1";
                        shift;
                    fi
            ;;
        -n|--nginx-port)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PORT_NGINX="$1";
                        shift;
                    fi
            ;;
        -t|--tomcat-port)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PORT_TOMCAT="$1";
                        shift;
                    fi
            ;;
        -r|--redis-port)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PORT_REDIS="$1";
                        shift;
                    fi
            ;;
        -m|--mysql-port)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PORT_MYSQL="$1";
                        shift;
                    fi
            ;;
        -p|--project-name)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PROJECT_NAME="$1";
                        shift;
                    fi
            ;;
        --refresh-database)
            shift;
                    REFRESH_DATABASE="Y";
            ;;
 
        --)
            shift;
            break;
            ;;
    esac
done

############################ Functions #################################
function self_update(){
    cd ${WORK_DIR}
    echo "Check self-update ... "
    OUT_OF_DATE=`git remote show origin |grep "out of date" |grep dev` || true
    if [ ! -z "${OUT_OF_DATE}" ]; then
        git pull
        echo "Re-execute ... "
        exec $0 "$@" &
        exit 0
    else
        echo "No update, continue ... "
    fi
    cd -
}

############################ Main process #################################
self_update

echo -n "Create volume dirs ... "
mkdir -p ${DOCKER_VOLUME}
cd ${DOCKER_VOLUME}
for D in ${VOLUME_DIRS[*]}; do
    mkdir -p ${D}
done
echo "done"

echo -n "Generate docker-compose file ... "
if [ -f ${DOCKER_COMPOSE_FILE} ]; then
    echo "already exits, skip. (delete it if you want to re-generate)"
else
    if [ ${REFRESH_DATABASE} == "Y" ]; then
        VOLUME_INITSQL_LINE=" - $(echo "${DOCKER_VOLUME}/${VOLUME_INITSQL}" | sed 's/\//\\\//g'):/docker-entrypoint-initdb.d:ro"
    else
        VOLUME_INITSQL_LINE=""
    fi
    cat ${DOCKER_COMPOSE_FILE_TPL} | \
    sed 's/_PORT_NGINX_/'${PORT_NGINX}'/g' | \
    sed 's/_PORT_TOMCAT_/'${PORT_TOMCAT}'/g' | \
    sed 's/_PORT_REDIS_/'${PORT_REDIS}'/g' | \
    sed 's/_PORT_MYSQL_/'${PORT_MYSQL}'/g' | \
    sed 's/_VOLUME_LOGS_/'$(echo "${DOCKER_VOLUME}/${VOLUME_LOGS}" | sed 's/\//\\\//g')'/g' | \
    sed 's/_VOLUME_DATA_/'$(echo "${DOCKER_VOLUME}/${VOLUME_DATA}" | sed 's/\//\\\//g')'/g' | \
    sed 's/_VOLUME_INITSQL_/'${VOLUME_INITSQL_LINE}'/g' \
    > ${DOCKER_COMPOSE_FILE}
    echo "done"
fi

echo "Start docker-compose ... "
cd ${WORK_DIR}
docker-compose pull
docker-compose -p ${PROJECT_NAME} down
docker-compose -p ${PROJECT_NAME} up -d
