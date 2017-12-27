#!/bin/bash
set -e

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)
DEPLOY_ROOT=${WORK_DIR}/../
REPOS_DIR=${DEPLOY_ROOT}/repos

PROJECT_NAME=schoolpal
TS=`TZ=Asia/Shanghai date +%Y%m%d%H%M%S`

GIT_REPO_TPL=https://github.com/${PROJECT_NAME}/_NAME_.git
GIT_REPOS=(web-static data)

DOCKER_REPO=${PROJECT_NAME}
DOCKER_USER=dinner3000
DOCKER_PASS=1234abcd

NGINX_IMG_NAME=nginx

NGINX_IMG_DIR=${WORK_DIR}/nginx

############################ Functions #################################
function git_update(){
    if [ ! -d $1 ]; then
        REPO=`echo "${GIT_REPO_TPL}" | sed "s/_NAME_/"$1"/g"`
        git clone ${REPO}
    fi
    cd $1
	git checkout dev || true
	git pull --rebase -v
	cd -
}

function npm_build(){
    cd ${REPOS_DIR}/$1
    npm install
    npm run build
    cd -
}

function docker_build(){
    cd $1
    docker build -t ${PROJECT_NAME}/$2:${TS} . 
    docker tag ${PROJECT_NAME}/$2:${TS} ${PROJECT_NAME}/$2:latest
    docker push ${PROJECT_NAME}/$2:${TS}
    docker push ${PROJECT_NAME}/$2:latest
    docker rmi -f ${PROJECT_NAME}/$2:${TS}
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

echo "Build web-static ... "
rm -rf ${REPOS_DIR}/web-static/build/*
npm_build "web-static"

echo "Deploy static files ... "
rm -rf ${NGINX_IMG_DIR}/public || true
cp -rfv ${REPOS_DIR}/web-static/build ${NGINX_IMG_DIR}/build

echo "Build docker images ... "
docker login --username=${DOCKER_USER} --password=${DOCKER_PASS}
docker_build "${NGINX_IMG_DIR}" "${NGINX_IMG_NAME}"
docker logout
