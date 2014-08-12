#!/bin/bash
/usr/sbin/sshd

su hduser -c "$HADOOP_HOME/sbin/stop-dfs.sh"
su hduser -c "$HADOOP_HOME/sbin/stop-yarn.sh"

tail -f $HADOOP_HOME/logs/*
