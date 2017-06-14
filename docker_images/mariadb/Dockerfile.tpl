FROM $$_DOCKER_HUB_$$supervisor

# Prepare environment 
RUN yum install wget tar libaio net-tools -y

# Install mariadb
ENV MARIADB_HOME /mariadb
RUN wget -q https://mirrors.tuna.tsinghua.edu.cn/mariadb/mariadb-10.1.22/bintar-linux-x86_64/mariadb-10.1.22-linux-x86_64.tar.gz && \
    tar zxf mariadb-10.1.22-linux-x86_64.tar.gz && \
    rm mariadb-*.tar.gz && \
    mv mariadb-* ${MARIADB_HOME}

COPY init.sh ${MARIADB_HOME}/
RUN ${MARIADB_HOME}/init.sh

#VOLUME ${MARIADB_HOME}/data

EXPOSE 3306
