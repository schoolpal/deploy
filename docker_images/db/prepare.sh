#!/bin/sh

set -e

WORKDIR=$( cd `dirname $0`; pwd )

cd ${WORKDIR}
mkdir -p schema
cp -fv ../../../data/*schema*.sql schema/

mkdir -p data
cp -fv ../../../data/*data*.sql data/

