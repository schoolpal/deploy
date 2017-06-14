#!/bin/sh

function run(){
  echo $1
  $1
}

if [ -z $2 ]; then 
  echo "Usage: $0 [DOCKER_HUB_HOSTNAME] [IMAGE_NAME]"
  exit 1
fi

DOCKER_HUB=$1
IMAGE_NAME=$2

  echo "##################################################################################"
  echo "########################### ${IMAGE_NAME} #######################################"
  echo "##################################################################################"
  run "cd ${IMAGE_NAME}"
  sed 's/\$\$_DOCKER_HUB_\$\$/'${DOCKER_HUB}'\//g' Dockerfile.tpl > Dockerfile
  if [ -f prepare.sh -a -x prepare.sh ]; then 
    echo "Run prepare.sh"
    ./prepare.sh; 
  fi
  docker build -t ${DOCKER_HUB}/${IMAGE_NAME} . && docker push ${DOCKER_HUB}/${IMAGE_NAME}
  run "rm -f Dockerfile"
