#!/bin/sh

set -e

MVN=/opt/maven/bin/mvn

cd src/site
${MVN} -Dmaven.test.skip=true clean package
cd -

cd deploy/docker_image
./build.sh dev-0.2 ${BUILD_NUMBER}
cd -
