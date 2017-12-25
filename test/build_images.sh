#!/bin/sh
set -e

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)
DEPLOY_ROOT=${WORK_DIR}/../
REPOS_DIR=${DEPLOY_ROOT}/repos

DOCKER_VOLUME=/opt/docker-volume
VOLUME_LOGS=logs

VOLUME_DIRS="${VOLUME_LOGS}"

IMAGE_DIR_NGINX=${WORK_DIR}/nginx
IMAGE_DIR_TOMCAT=${WORK_DIR}/tomcat

GIT_REPO_TPL=https://github.com/schoolpal/_NAME_.git
GIT_REPOS=(web-static web-service data)

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

TS=`TZ=Asia/Shanghai date +%Y%m%d%H%M%S`
function docker_build(){
    cd $1
    docker build -t schoolpal/$2:${TS} . 
    docker tag schoolpal/$2:${TS} schoolpal/$2:latest
    docker login --username=dinner3000 --password=1234abcd
    docker push schoolpal/$2:${TS}
    docker push schoolpal/$2:latest
    docker logout
    cd -
}

############################ Main process #################################

echo -n "Create volume dirs ... "
mkdir -p ${DOCKER_VOLUME}
cd ${DOCKER_VOLUME}
for D in ${VOLUME_DIRS[*]}; do
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

echo "Build web-static ... "
npm_build "web-static"

echo "Build web-service ... "
mvn_build "web-service"

#echo "Deploy static files ... "
rm -rfv ${IMAGE_DIR_NGINX}/public || true
cp -rfv ${REPOS_DIR}/web-static/public ${IMAGE_DIR_NGINX}/public

#echo "Deploy service files ... "
rm -rfv ${IMAGE_DIR_TOMCAT}/*.war || true
cp -rfv ${REPOS_DIR}/web-service/target/*.war ${IMAGE_DIR_TOMCAT}/

#echo "Build docker images ... "
docker_build "${IMAGE_DIR_NGINX}" "nginx"
docker_build "${IMAGE_DIR_TOMCAT}" tomcat
