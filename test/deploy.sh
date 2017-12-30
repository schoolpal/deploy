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

PROJECT_NAME=schoolpal

DOCKER_COMPOSE_FILE_TPL=${WORK_DIR}/docker-compose.tpl.yml
DOCKER_COMPOSE_FILE=${WORK_DIR}/docker-compose.yml

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
if [ ! -f ${DOCKER_COMPOSE_FILE} ]; then
    cat ${DOCKER_COMPOSE_FILE_TPL} | \
    sed 's/_VOLUME_LOGS_/'$(echo "${DOCKER_VOLUME}/${VOLUME_LOGS}" | sed 's/\//\\\//g')'/g' | \
    sed 's/_VOLUME_DATA_/'$(echo "${DOCKER_VOLUME}/${VOLUME_DATA}" | sed 's/\//\\\//g')'/g' \
    > ${DOCKER_COMPOSE_FILE}
    echo "done"
else
    echo -n "already exits, skip. (delete it if you want to re-generate)"
fi

echo "Start docker-compose ... "
cd ${WORK_DIR}
docker-compose pull
docker-compose -p ${PROJECT_NAME} down
docker-compose -p ${PROJECT_NAME} up -d
