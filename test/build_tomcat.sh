#!/bin/sh
set -e

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)
DEPLOY_ROOT=${WORK_DIR}/../
REPOS_DIR=${DEPLOY_ROOT}/repos

PROJECT_NAME=schoolpal
TS=`TZ=Asia/Shanghai date +%Y%m%d%H%M%S`

GIT_REPO_TPL=https://github.com/${PROJECT_NAME}/_NAME_.git
GIT_REPOS=(web-service data)

DOCKER_REPO=${PROJECT_NAME}
DOCKER_USER=dinner3000
DOCKER_PASS=1234abcd

TOMCAT_IMG_NAME=tomcat

TOMCAT_IMG_DIR=${WORK_DIR}/tomcat

############################ Functions #################################
function git_update(){
    if [ ! -d $1 ]; then
        REPO=`echo "${GIT_REPO_TPL}" | sed "s/_NAME_/"$1"/g"`
        git clone ${REPO}
        git checkout dev || true
    else
	cd $1
	git pull --rebase -v
	git checkout dev || true
	cd ..
    fi
}

function mvn_build(){
    cd ${REPOS_DIR}/$1
    mvn clean package -Pdocker
    cd -
}

function docker_build(){
    cd $1
    docker build -t ${PROJECT_NAME}/$2:${TS} . 
    docker tag ${PROJECT_NAME}/$2:${TS} ${PROJECT_NAME}/$2:latest
    docker push ${PROJECT_NAME}/$2:${TS}
    docker push ${PROJECT_NAME}/$2:latest
    cd -
}

############################ Main process #################################

echo "Get latest source code ... "
mkdir -p ${REPOS_DIR}
cd ${REPOS_DIR}
for R in ${GIT_REPOS[*]}; do
    echo " => ${R}"
    git_update "${R}"
done

echo "Build web-service ... "
mvn_build "web-service"

echo "Deploy service files ... "
rm -rf ${TOMCAT_IMG_DIR}/*.war || true
cp -rfv ${REPOS_DIR}/web-service/target/*.war ${TOMCAT_IMG_DIR}/

echo "Build docker images ... "
docker login --username=${DOCKER_USER} --password=${DOCKER_PASS}
docker_build "${TOMCAT_IMG_DIR}" ${TOMCAT_IMG_NAME}
docker logout
