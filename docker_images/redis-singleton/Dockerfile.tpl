FROM $$_DOCKER_HUB_$$supervisor

RUN yum install epel-release -y && \
    yum install wget redis net-tools -y

COPY init.sh ${REDIS_DIR}/
RUN ${REDIS_DIR}/init.sh

VOLUME /redis/data-singleton

EXPOSE 6379

