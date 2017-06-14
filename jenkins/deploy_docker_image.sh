#!/bin/sh

if [ -z $4 ]; then 
    echo "Usage: $0 [DOCKER_HUB] [IMAGE] [PORT] [NAME] [LINKS]"
    exit 0
fi

DOCKER_HUB=$1
IMAGE=$2
PORT=$3
NAME=$4
if [ ! -z "$5" ]; then
    LINKS="$5"
fi

docker rm -f ${NAME}
docker pull ${DOCKER_HUB}/${IMAGE}:latest
docker run -d --restart=always -p ${PORT} ${LINKS} --name ${NAME} ${DOCKER_HUB}/${IMAGE}:latest
docker ps -a
