#!/bin/sh

set -e

if [ -z $1 ]; then
	echo "Usage: $0 [JENKINS_WAR]"
	exit 0
fi

JENKINS_WAR=$1
SCRIPT_DIR=$(cd `dirname $0`; pwd)
JENKINS_HOME=${SCRIPT_DIR}/${JENKINS_WAR%.*}
JENKINS_LOG=${JENKINS_HOME}/log
JENKINS_PID=${JENKINS_HOME}/pid

export JENKINS_HOME
mkdir -p ${JENKINS_HOME}
while [ 1 ]; do
	if [ -f ${JENKINS_PID} ]; then
		PID=`cat ${JENKINS_PID}`
		RUNNING=`ps -p $PID -h |wc -l`
	else
		RUNNING=`ps -auxwh |grep "java -jar ${JENKINS_WAR}" |grep -v grep |wc -l`
	fi
	if [ "$RUNNING" -ne "1" ]; then
		echo "Not running, restart ... "
		echo "++++++++++++++++++++++++++++++++++++" >> ${JENKINS_LOG}
		nohup java -jar ${JENKINS_WAR} >> ${JENKINS_LOG} 2>&1 &
		echo "$!" > ${JENKINS_PID}
	else
		echo "Running"
	fi
	sleep 5
done
