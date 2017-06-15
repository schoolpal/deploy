#!/bin/sh

set -e

WORKDIR=$( cd `dirname $0`; pwd )

cd ${WORKDIR}
cp -rf ../../../web/src/site/target/*.war ./
cp -rf ../../../wechat/target/*.war ./

