#!/bin/sh

set -e

WORKDIR=$( cd `dirname $0`; pwd )

cd ${WORKDIR}
cp -rf ../../../src/site/target/*.war ./

