#!/bin/bash
set -eo pipefail

#ENV settings
HOME=/mariadb
CONF=${HOME}/etc/my.cnf
DATA=${HOME}/data
PORT=3306
SOCK=/tmp/mysql.sock

USER=mysql
GROUP=mysql

PASS="123456"

export PATH=$PATH:${HOME}/bin

#Create mysqld config file
mkdir -p ${HOME}/etc
cat > ${CONF} << EOF 
[mysqld]
port=${PORT} 
socket=${SOCK}
datadir=${HOME}/data
loose-innodb_data_file_path = ibdata1:100M
loose-innodb_file_per_table
log-basename=mysqld
general-log
EOF
#slow-query-log-file=/var/

groupadd ${GROUP}
useradd -g ${GROUP} ${USER}
chown -R root ${HOME}
chown -R ${USER} ${DATA}

echo 'Initializing database'
${HOME}/scripts/mysql_install_db --defaults-file=${CONF} --user=${USER} --basedir=${HOME}
echo 'Database initialized'

mysqld --defaults-file=${CONF} --user=${USER} --basedir=${HOME} &
pid="$!"

mysql=( mysql --protocol=socket -uroot -hlocalhost --socket="${SOCK}" )

for i in {30..0}; do
	if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
		break
	fi
	echo 'MySQL init process in progress...'
	sleep 1
done
if [ "$i" = 0 ]; then
	echo >&2 'MySQL init process failed.'
	exit 1
fi

if [ -z "$MYSQL_INITDB_SKIP_TZINFO" ]; then
	# sed is for https://bugs.mysql.com/bug.php?id=20545
	mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
fi

"${mysql[@]}" <<-EOSQL
	-- What's done in this file shouldn't be replicated
	--  or products like mysql-fabric won't work
	SET @@SESSION.SQL_LOG_BIN=0;

	DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost') ;

	SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${PASS}') ;
	GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;

	CREATE USER 'root'@'%' IDENTIFIED BY '${PASS}' ;
	GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;

	FLUSH PRIVILEGES ;
EOSQL

if ! kill -s TERM "$pid" || ! wait "$pid"; then
	echo >&2 'MySQL init process failed.'
	exit 1
fi

echo "export PATH=\$PATH:${HOME}/bin" > /etc/profile.d/mysql.sh
chmod a+x /etc/profile.d/mysql.sh

########################## Create supervisor config ###############################
SUPERVISORD_DIR=/etc/supervisor.d
SUPERVISORD_CONF=${SUPERVISORD_DIR}/mariadb.conf
mkdir -p ${SUPERVISORD_DIR}
cat > ${SUPERVISORD_CONF} <<EOD
[supervisord]
nodaemon=false
[program:mariadb]
command=${HOME}/bin/mysqld_safe --defaults-file=${CONF} --user=${USER}
EOD
