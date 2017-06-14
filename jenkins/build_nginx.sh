#!/bin/sh

set -e

cd deploy/docker_images
./build_one.sh dockerhub.internal:5000 nginx
cd -
