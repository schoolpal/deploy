#!/bin/sh

set -e

RUNNING_CONTAINER=$(docker ps -qf "name=schoolpal_testbed")
if [ ! -z ${RUNNING_CONTAINER} ]; then
	docker stop ${RUNNING_CONTAINER}
	docker rm ${RUNNING_CONTAINER}
fi
docker run -d --restart=always -p 7180:8080 --name schoolpal_testbed dockerhub.internal:5000/schoolpal_testbed

