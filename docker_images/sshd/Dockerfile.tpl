FROM $$_DOCKER_HUB_$$supervisor

########################## Install necessary tools ################################
RUN yum -y update
RUN yum -y install wget passwd net-tools openssl ca-certificates

########################## Install sshd ###########################################
RUN yum -y install openssh-server openssh-clients

COPY init.sh /tmp/
RUN /tmp/init.sh

EXPOSE 22

