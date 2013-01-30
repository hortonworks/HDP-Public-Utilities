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
# limitations under the License.
read -p "This is going to remove software, users, and directories...are you sure you want to proceed [y|n]" SURE
if [ $SURE == "y" ]; then
	./run_command.sh 'killall java'
	./run_command.sh 'yum -y erase ruby ruby-irb ruby-libs ruby-shadow ruby-rdoc ruby-augeas rubygems libselinux-ruby ruby-devel libganglia libconfuse hdp_mon_ganglia_addons ganglia-gmond postgresql-server postgresql postgresql-libs ganglia-gmond-python ganglia ganglia-gmetad ganglia-web ganglia-devel httpd mysql mysql-server mysqld'
	./run_command.sh 'yum -y erase hadoop-hive hadoop-hbase hadoop-0.20-jobtracker hadoop-zookeeper hadoop-0.20 hadoop-0.20-datanode hadoop-0.20-namenode hadoop-hbase-master hadoop-0.20-native hadoop-pig hadoop-0.20-conf-pseudo hadoop-0.20-secondarynamenode hadoop-zookeeper-server hadoop-0.20-tasktracker oozie oozie-client flume flume-master flume-node sqoop sqoop-metastore hue sqoop-metastore bsub hue-filebrowser hue-useradmin hue hue-help hue-jobbrowser hue-about hue-beeswax hue-proxy hue-server hue-shell hue-plugins cloudera-hue-mysql hue-common'
	./run_command.sh 'killall java'
	./run_command.sh 'rm -rf /etc/hadoop /etc/hbase /etc/hcatalog /etc/hive /etc/ganglia /etc/httpd /etc/nagios /etc/oozie /etc/nagios /etc/sqoop /etc/hue /etc/flume'
	./run_command.sh 'rm -rf /var/run/zookeeper /var/run/hadoop /var/run/hbase /var/run/ganglia /var/run/zookeeper /var/run/templeton /var/run/oozie /var/run/hive /var/run/hue /var/run/sqoop'
	./run_command.sh 'rm -rf /var/log/zookeeper /var/log/hadoop /var/log/nagios /var/log/hbase /var/log/hive /var/log/templeton /var/log/oozie /var/log/flume /var/log/hadoop* /var/log/sqoop'
	./run_command.sh 'rm -rf /var/zookeeper /usr/lib/hive /var/tmp/oozie /usr/lib/oozie /var/lib/hadoop* /var/lib/mysql'
	./run_command.sh 'userdel -r puppet'
	./run_command.sh 'userdel -r ambari_qa'
	./run_command.sh 'userdel -r hadoop_deploy'
	./run_command.sh 'userdel -r rrdcached'
	./run_command.sh 'userdel -r zookeeper'
	./run_command.sh 'userdel -r mapred'
	./run_command.sh 'userdel -r hdfs'
	./run_command.sh 'userdel -r hive'
	./run_command.sh 'userdel -r oozie'
	./run_command.sh 'userdel -r flume'
	./run_command.sh 'userdel -r hbase'
	./run_command.sh 'userdel -r sqoop'
	./run_command.sh 'rm -rf /var/lib/hive /usr/lib/hadoop'
	./run_command.sh 'rm /etc/yum.repos.d/Cloudera*'
	SCRIPTFILE=/tmp/$RANDOM
	echo "ls -la | egrep \"flume|hadoop|hive|pig\" | awk '{ print \"alternatives --remove \" \$9 \" \" \$11; }' | bash" > $SCRIPTFILE
	./copy_file.sh $SCRIPTFILE /tmp
	./run_command.sh "bash $SCRIPTFILE"
fi