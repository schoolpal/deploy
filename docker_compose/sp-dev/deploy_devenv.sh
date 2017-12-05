#!/bin/sh -x

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)
DEPLOY_ROOT=$(cd "$(dirname "$0")/../../"; pwd)
DOCKER_VOLUME=/opt/docker-volume

VOLUME_INITSQL=init-sql
VOLUME_WEBAPPS=webapps
VOLUME_HTML=html
VOLUME_CONF=conf
VOLUME_LOGS=logs
VOLUME_NGINXCONF=nginx.conf
VOLUME_DIRS=(${VOLUME_INITSQL} ${VOLUME_WEBAPPS} ${VOLUME_HTML} ${VOLUME_CONF} ${VOLUME_LOGS})

GIT_REPO_TPL=https://github.com/schoolpal/_NAME_.git
GIT_REPOS=(web-service data)

DOCKER_COMPOSE_FILE_TPL=${WORK_DIR}/docker-compose.tpl.yml
DOCKER_COMPOSE_FILE=${WORK_DIR}/docker-compose.yml

exit 0

############################ Functions #################################
function git_update(){
    if [ ! -f $1 ]; then
        REPO=echo "${GIT_REPO_TPL}" | sed 's/_NAME_/$1/g'
        git clone ${REPO}
    else
        git pull ${REPO}
    fi
}

function mvn_build(){
    cd ${DEPLOY_ROOT}/$1
    mvn clean package
    cd -
}

function deploy_war(){
    cp -rf ${DEPLOY_ROOT}/$1/target/*.war $2
}

function deploy_files(){
    cp -rf ${DEPLOY_ROOT}/$1/target/$2/* $3/
}

############################ Main process #################################
#Create sub-dirs
cd ${DOCKER_VOLUME}
for D in ${VOLUME_DIRS[*]}; do
    mkdir -p ${D}
done
cd -

#Get latest source code
cd ${DEPLOY_ROOT}
for R in ${GIT_REPOS[*]}; do
    git_update "${R}"
done
cd -

#Deploy config files
cp ${DEPLOY_ROOT}/data/*.sql ${DOCKER_VOLUME}/${VOLUME_INITSQL}/
cp ${WORK_DIR}/nginx.conf ${DOCKER_VOLUME}/${VOLUME_NGINXCONF}

#Build web-service
mvn_build "web-service"
deploy_files "web-service" "web" "${DOCKER_VOLUME}/web-service"

#Generate docker-compose file
sed 's/_VOLUME_HTML_/${VOLUME_HTML}/g' | \
sed 's/_VOLUME_NGINXCONF_/${VOLUME_NGINXCONF}/g' | \
sed 's/_VOLUME_WEBAPPS_/${VOLUME_WEBAPPS}/g' | \
sed 's/_VOLUME_LOGS_/${VOLUME_LOGS}/g' | \
sed 's/_VOLUME_INITSQL_/${VOLUME_INITSQL}/g' | \
sed 's/_VOLUME_HTML_/${VOLUME_HTML}/g' | \
${DOCKER_COMPOSE_FILE_TPL} > ${DOCKER_COMPOSE_FILE}

#docker-compose pull
#docker-compose up -d
