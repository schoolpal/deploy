#!/bin/sh

NAME=jenkins
VOLUME_HOME=/opt/docker-volume/jenkins

docker run -dP  --restart=always --name ${NAME} -v ${VOLUME_HOME}:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock --group-add=$(stat -c %g /var/run/docker.sock) -e JAVA_OPTS=-Dorg.jenkinsci.plugins.gitclient.GitClient.untrustedSSL=true jenkins:latest
#--add-host dockerhub.internal:172.17.0.1 i
