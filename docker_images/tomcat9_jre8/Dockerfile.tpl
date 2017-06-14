FROM $$_DOCKER_HUB_$$supervisor

########################## Install necessary tools ################################
RUN yum -y update
RUN yum -y install wget net-tools java-1.8.0-openjdk-devel

######################### Install tomcat #########################################
# Prepare environment 
ENV JAVA_HOME /usr/lib/jvm/java
ENV CATALINA_HOME /tomcat 
ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin:$CATALINA_HOME/scripts

# Install Tomcat
ENV TOMCAT_MAJOR 9
ENV TOMCAT_VERSION 9.0.0.M20

#http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.0.M20/bin/apache-tomcat-9.0.0.M20.tar.gz
ENV APACHE_SITE archive.apache.org
RUN wget -q http://${APACHE_SITE}/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
 tar -xvf apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
 rm apache-tomcat*.tar.gz && \
 mv apache-tomcat* ${CATALINA_HOME}

COPY init.sh /tmp/
RUN /tmp/init.sh

#VOLUME ${CATALINA_HOME}/webapps
EXPOSE 8080

