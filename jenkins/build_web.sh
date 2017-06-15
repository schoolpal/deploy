#!/bin/sh

set -e

MVN=/opt/maven/bin/mvn

cd web/src/site
${MVN} -Dmaven.test.skip=true -Pdocker clean package
cd -
cd wechat
${MVN} -Dmaven.test.skip=true -Pdocker clean package
cd -

cd deploy/docker_images
./build_one.sh dockerhub.internal:5000 web
cd -
