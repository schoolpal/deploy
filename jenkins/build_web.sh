#!/bin/sh

set -e

MVN=/opt/maven/bin/mvn

cd src/site
${MVN} -Dmaven.test.skip=true -Pdocker clean package
cd -

cd deploy/docker_images
./build_one.sh dockerhub.internal:5000 web
cd -
