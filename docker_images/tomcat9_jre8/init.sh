#!/bin/sh

#Create tomcat config
USER_CONF=${CATALINA_HOME}/conf/tomcat-users.xml
SERV_CONF=${CATALINA_HOME}/conf/server.xml
CXT_CONF=${CATALINA_HOME}/conf/context.xml
MGR_CONF=${CATALINA_HOME}/webapps/manager/META-INF/context.xml

PASS="123456"

sed -i -r 's/<\/tomcat-users>//' ${USER_CONF}
cat >> ${USER_CONF} <<EOF
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<user username="admin" password="${PASS}" roles="manager-gui,manager-script,manager-jmx,admin-gui,admin-script"/>
</tomcat-users>
EOF

sed -i -r "s/<\/Context>//" ${CXT_CONF}
cat >> ${CXT_CONF} <<EOF
<Valve className="org.apache.catalina.valves.RemoteAddrValve" allow=".*" />
</Context>
EOF

sed -i -r "s/allow=\".*\"/allow=\".*\"/" ${MGR_CONF}

########################## Create supervisor config ###############################
SUPERVISORD_DIR=/etc/supervisor.d
SUPERVISORD_CONF=${SUPERVISORD_DIR}/tomcat.conf
mkdir -p ${SUPERVISORD_DIR}
cat > ${SUPERVISORD_CONF} <<EOF
[supervisord]
nodaemon=true
[program:tomcat]
command=/tomcat/bin/catalina.sh run
EOF
