#!/bin/sh -x

if [ -z $1 ]; then
	echo "Usage: $0 [COMMAND]"
	exit 0
fi

WORK_DIR=$( cd `dirname $0`; pwd )
HTML_DIR=/opt/schoolpal/src/site/target

function set_options(){

	NAME=$1
	DOCKERHUB=bj.dinner3000.com:5000/

	if [ "$1" = "nginx" ]; then
		VOLUMN="-v ${HTML_DIR}:/usr/share/nginx/html:ro"
	else
		VOLUMN=""
	fi

	if [ "$1" = "redis" ]; then
		IMAGE=redis-singleton
	elif [ "$1" = "nginx" ]; then
		IMAGE=nginx-dev
	else
		IMAGE=$1
	fi

	if [ "$1" = "redis" ]; then
		PORT=""
	elif [ "$1" = "db" ]; then
		PORT=""
		LINK=""
	elif [ "$1" = "web" ]; then
		PORT="-p 7180:8080"
		LINK="--link db:db --link redis:redis"
	elif [ "$1" = "nginx" ]; then
		PORT="-p 71:80"
		LINK="--link web:web"
	else
		PORT=""
		LINK=""
	fi
}

if [ "$1" == "remove" ]; then 
	for component in redis db web nginx; do
		docker rm -f ${component}
	done
elif [ "$1" == "start" ]; then 
	for component in redis db web nginx; do
		docker start ${component}
	done
elif [ "$1" == "stop" ]; then 
	for component in nginx web db redis; do
		docker stop ${component}
	done
elif [ "$1" == "pull" ]; then 
	for component in redis db web nginx; do
		docker pull ${DOCKERHUB}${IMAGE}:latest
	done
elif [ "$1" == "run" ]; then 
	for component in redis db web nginx; do
		docker run -d --restart=always ${PORT} ${LINK} ${VOLUMN} --name ${NAME} ${DOCKERHUB}${IMAGE}:latest
	done
else
	echo "Invalid command"
	exit 0
fi


