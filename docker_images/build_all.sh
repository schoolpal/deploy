#!/bin/sh

function run(){
  echo $1
  $1
}

if [ -z $1 ]; then 
  echo "Usage: $0 [DOCKER_HUB_HOSTNAME]"
  exit 1
fi

DOCKER_HUB=$1
#IMAGE_NAMES="supervisor sshd redis-singleton mariadb tomcat9_jre8"
IMAGE_NAMES="supervisor redis-singleton mariadb tomcat9_jre8 nginx"

for NAME in ${IMAGE_NAMES}; do
    ./build_one.sh ${DOCKER_HUB} ${NAME}
done

