#!/bin/sh
set -e

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)
DEPLOY_ROOT=${WORK_DIR}/../
REPOS_DIR=${DEPLOY_ROOT}/repos

DOCKER_VOLUME=/opt/docker-volume
VOLUME_INITSQL=init-sql
VOLUME_DATA=data
VOLUME_LOGS=logs

VOLUME_DIRS="${VOLUME_INITSQL} ${VOLUME_DATA} ${VOLUME_LOGS}"

PROJECT_NAME=schoolpal

GIT_REPO_TPL=https://github.com/${PROJECT_NAME}/_NAME_.git
GIT_REPOS=(web-static web-service data)

DOCKER_COMPOSE_FILE_TPL=${WORK_DIR}/docker-compose.tpl.yml
DOCKER_COMPOSE_FILE=${WORK_DIR}/docker-compose.yml

############################ Functions #################################
#None

############################ Main process #################################

echo -n "Create volume dirs ... "
mkdir -p ${DOCKER_VOLUME}
cd ${DOCKER_VOLUME}
for D in ${VOLUME_DIRS[*]}; do
#    echo ${D}
    mkdir -p ${D}
done
echo "done"

echo -n "Generate docker-compose file ... "
cat ${DOCKER_COMPOSE_FILE_TPL} | \
sed 's/_VOLUME_LOGS_/'$(echo "${DOCKER_VOLUME}/${VOLUME_LOGS}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_DATA_/'$(echo "${DOCKER_VOLUME}/${VOLUME_LOGS}" | sed 's/\//\\\//g')'/g' | \
#sed 's/_VOLUME_INITSQL_/'$(echo "${DOCKER_VOLUME}/${VOLUME_INITSQL}" | sed 's/\//\\\//g')'/g' \
 > ${DOCKER_COMPOSE_FILE}
echo "done"

echo "Start docker-compose ... "
cd ${WORK_DIR}
docker-compose -p ${PROJECT_NAME} down
docker-compose -p ${PROJECT_NAME} up -d
