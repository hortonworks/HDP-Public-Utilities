#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
if [ $# -eq 1 ]; then
	export REPO_FILTER='Cloudera'
	#export REPO_FILTER='Updates-ambari-1.x|HDP-UTILS-1.1.0.15|HDP-1.2.0|AMBARI-1.x'
	export PATHS=( /etc /var/log /var/run /usr/lib /var/lib /var/tmp /tmp/ /var )
	export PACKAGES=(`yum list | egrep -E "$REPO_FILTER" | awk '{ print $1; }' | grep -v '^[0-9]'`)
	export PROJECT_NAMES=( hadoop* hadoop hbase hcatalog hive ganglia nagios oozie sqoop hue zookeeper mapred hdfs flume puppet ambari_qa hadoop_deploy rrdcached hcat ambari-server ambari-agent)
	export PROJECT_REGEX=`echo ${PROJECT_NAMES[@]} | sed 's/ /|/g'`
	echo $PROJECT_REGEX

	# Erase packages found from repo list
	if [ ${#PACKAGES[@]} -gt "0" ]; then
		yum -y erase ${PACKAGES[@]};
	else
		echo "No packages to erase"
	fi
	
	# Erase packages that are typical, in the event the repolist filter is not adequate to dynamically deteremine packages
	#yum -y erase hadoop-hive hadoop-hbase hadoop-0.20-jobtracker hadoop-zookeeper hadoop-0.20 hadoop-0.20-datanode hadoop-0.20-namenode hadoop-hbase-master hadoop-0.20-native hadoop-pig hadoop-0.20-conf-pseudo hadoop-0.20-secondarynamenode hadoop-zookeeper-server hadoop-0.20-tasktracker oozie oozie-client flume flume-master flume-node sqoop sqoop-metastore hue sqoop-metastore bsub hue-filebrowser hue-useradmin hue hue-help hue-jobbrowser hue-about hue-beeswax hue-proxy hue-server hue-shell hue-plugins cloudera-hue-mysql hue-common cloudera-hadoop-lzo cloudera-cdh zookeeper bigtop-utils bigtop-jsvc cloudera-manager cloudera-manager-repository cloudera-manager-agent cloudera-manager-plugins cloudera-manager-daemons cdh3-repository

	# Erase alternatives
	cd /etc/alternatives
	for name in `ls | egrep "$PROJECT_REGEX"`; do
		for path in `alternatives --display $name | grep priority | awk '{print $1}'`; do
			alternatives --remove $name $path
		done
	done

	for project in ${PROJECT_NAMES[@]}; do
		# Erase fs entries
		for base_path in ${PATHS[@]} ; do
			if [ -d $base_path/$project ] ; then
				rm -rf $base_path/$project
			fi
		done
	
		# Remove users
		cat /etc/passwd | grep $project > /dev/null
		if [ $? -eq 0 ]; then
			userdel -r $project
		fi
	done

	# Removing repo's
	cd /etc/yum.repos.d && egrep $REPO_FILTER *.repo | awk -F: '{ print $1; }' | sort -u | xargs -n 1 rm -f

	# Remove CMF files
	if [ -d /usr/lib64/cmf ]; then
		rm -rf /usr/lib64/cmf
	fi

	#Remove PostgreSQL database files
	if [ -d /var/lib/pgsql ]; then
		rm -rf /var/lib/pgsql
	fi
	
	#Remove MySQL database files
	if [ -d /var/lib/mysql ]; then
		rm -rf /var/lib/mysql
	fi

else
	echo "You're not going to want to run this directly, please run the ./clean_hosts.sh script"
fi