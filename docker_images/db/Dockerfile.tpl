FROM $$_DOCKER_HUB_$$mariadb

WORKDIR /tmp

COPY schema /tmp/schema
COPY data /tmp/data
COPY init.sh /tmp/

RUN /tmp/init.sh

