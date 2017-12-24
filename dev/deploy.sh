#!/bin/sh

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)
DEPLOY_ROOT=${WORK_DIR}/../
REPOS_DIR=${DEPLOY_ROOT}/repos

DOCKER_VOLUME=/opt/docker-volume

VOLUME_INITSQL=init-sql
VOLUME_WEBAPPS=webapps
VOLUME_HTML=html
VOLUME_CONF=conf
VOLUME_LOGS=logs
VOLUME_NGINXCONF=nginx.conf

VOLUME_DIRS="${VOLUME_INITSQL} ${VOLUME_WEBAPPS} ${VOLUME_HTML} ${VOLUME_CONF} ${VOLUME_LOGS}"

GIT_REPO_TPL=https://github.com/schoolpal/_NAME_.git
GIT_REPOS=(web-static web-service data)

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

function npm_build(){
    cd ${REPOS_DIR}/$1
    npm install
    npm run build
    cd -
}

function mvn_build(){
    cd ${REPOS_DIR}/$1
    mvn clean package -Pdocker
    cd -
}

function deploy_static(){
    rm -rfv $2/*
    cp -rfv ${REPOS_DIR}/$1/build/* $2/
}

function deploy_service(){
	rm -rfv $2/*
    cp -rfv ${REPOS_DIR}/$1/target/*.war $2
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
mkdir -p ${REPOS_DIR}
cd ${REPOS_DIR}
for R in ${GIT_REPOS[*]}; do
    echo " => ${R}"
    git_update "${R}"
done

set -e
echo "Build web-static ... "
npm_build "web-static"

echo "Build web-service ... "
mvn_build "web-service"
set +e

echo "Deploy static files ... "
deploy_static "web-static" "${DOCKER_VOLUME}/${VOLUME_HTML}"

echo "Deploy service files ... "
deploy_service "web-service" "${DOCKER_VOLUME}/${VOLUME_WEBAPPS}"

echo "Deploy config files ... "
rm -rf ${DOCKER_VOLUME}/${VOLUME_INITSQL}/*.sql
cp -fv ${REPOS_DIR}/data/*.sql ${DOCKER_VOLUME}/${VOLUME_INITSQL}/
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
docker-compose -p schoolpal down
#docker-compose pull
docker-compose -p schoolpal up -d
