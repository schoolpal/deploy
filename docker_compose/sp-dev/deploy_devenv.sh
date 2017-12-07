#!/bin/sh

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
VOLUME_DIRS="${VOLUME_INITSQL} ${VOLUME_WEBAPPS} ${VOLUME_HTML} ${VOLUME_CONF} ${VOLUME_LOGS}"

GIT_REPO_TPL=https://github.com/schoolpal/_NAME_.git
GIT_REPOS=(web-service data)

DOCKER_COMPOSE_FILE_TPL=${WORK_DIR}/docker-compose.tpl.yml
DOCKER_COMPOSE_FILE=${WORK_DIR}/docker-compose.yml


############################ Functions #################################
function git_update(){
    if [ ! -d $1 ]; then
        REPO=`echo "${GIT_REPO_TPL}" | sed "s/_NAME_/"$1"/g"`
        git clone ${REPO}
	git checkout dev
    else
	cd $1
	git pull --rebase -v
	git checkout dev
	cd ..
    fi
}

function mvn_build(){
    cd ${DEPLOY_ROOT}/$1
    mvn clean package -Pdocker
    cd -
}

function deploy_service(){
#    rm -rfv $3/$2
#    cp -rfv ${DEPLOY_ROOT}/$1/target/$2 $3/
    cp -rfv ${DEPLOY_ROOT}/$1/target/*.war $2
}

function deploy_static(){
    rm -rfv $3/*
    mkdir -p $3/web
    cp -rfv ${DEPLOY_ROOT}/$1/target/$2/html $3/web/
    cp -rfv ${DEPLOY_ROOT}/$1/target/$2/html/* $3/
    cp -rfv ${DEPLOY_ROOT}/$1/target/$2/ajax_ut $3/web/
    cp -rfv ${DEPLOY_ROOT}/$1/target/$2/ajax_ut $3/
}

############################ Main process #################################

echo -n "Create volume dirs ... "
mkdir -p ${DOCKER_VOLUME}
cd ${DOCKER_VOLUME}
for D in ${VOLUME_DIRS[*]}; do
#    echo ${D}
    mkdir -p ${D}
done
echo "done"

echo "Get latest source code ... "
cd ${DEPLOY_ROOT}
for R in ${GIT_REPOS[*]}; do
    echo " => ${R}"
    git_update "${R}"
done

echo "Build web-service ... "
mvn_build "web-service"

echo "Deploy services ... "
deploy_service "web-service" "${DOCKER_VOLUME}/${VOLUME_WEBAPPS}"

echo "Deploy static files ... "
deploy_static "web-service" "web" "${DOCKER_VOLUME}/${VOLUME_HTML}"

echo "Deploy config files ... "
rm -rf ${DOCKER_VOLUME}/${VOLUME_INITSQL}/*.sql
cp -fv ${DEPLOY_ROOT}/data/*.sql ${DOCKER_VOLUME}/${VOLUME_INITSQL}/
cp -fv ${WORK_DIR}/nginx.conf ${DOCKER_VOLUME}/${VOLUME_CONF}/${VOLUME_NGINXCONF}

echo -n "Generate docker-compose file ... "
cat ${DOCKER_COMPOSE_FILE_TPL} | \
sed 's/_VOLUME_HTML_/'$(echo "${DOCKER_VOLUME}/${VOLUME_HTML}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_NGINXCONF_/'$(echo "${DOCKER_VOLUME}/${VOLUME_CONF}/${VOLUME_NGINXCONF}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_WEBAPPS_/'$(echo "${DOCKER_VOLUME}/${VOLUME_WEBAPPS}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_LOGS_/'$(echo "${DOCKER_VOLUME}/${VOLUME_LOGS}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_INITSQL_/'$(echo "${DOCKER_VOLUME}/${VOLUME_INITSQL}" | sed 's/\//\\\//g')'/g' \
 > ${DOCKER_COMPOSE_FILE}
echo "done"

echo "Start docker-compose ... "
cd ${WORK_DIR}
docker-compose down
#docker-compose pull
docker-compose up -d
