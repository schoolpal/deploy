#!/bin/sh

yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce

#sed -i 's/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd --registry-mirror=https:\/\/docker.mirrors.ustc.edu.cn --insecure-registry=bj.dinner3000.com:5000/g' /usr/lib/systemd/system/docker.service
systemctl daemon-reload

systemctl enable docker
systemctl start docker

docker run hello-world

yum -y install epel-release
yum -y install python-pip
#curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
#chmod a+x get-pip.py && ./get-pip.py
pip install docker-compose

