#!/bin/sh

set -e

mkdir /var/run/sshd

#Create ssh keys
ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 
ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''

#Change sshd config
sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config
sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config

#Set root password
echo "root:123456" |chpasswd

########################## Create supervisor config ###############################
SUPERVISORD_DIR=/etc/supervisor.d
SUPERVISORD_CONF=${SUPERVISORD_DIR}/sshd.conf
mkdir -p ${SUPERVISORD_DIR}
cat > ${SUPERVISORD_CONF} <<EOF
[supervisord]
nodaemon=true
[program:sshd]
command=/usr/sbin/sshd -D
EOF
