#!/bin/sh

WORK_DIR=$( cd `dirname $0`; pwd )

cd ${WORK_DIR}/../docker_compose/sp-test

docker-compose pull
docker-compose up -d
