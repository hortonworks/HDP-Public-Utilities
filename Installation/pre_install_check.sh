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
TPUT='tput -T xterm-color'
txtund=$(${TPUT} sgr 0 1)          # Underline
txtbld=$(${TPUT} bold)             # Bold
txtrst=$(${TPUT} sgr0)             # Reset

for host in `cat Hostdetail.txt`; do
  echo -e "${txtbld}\n######################################################"
  echo -e "# Checking Host: $host"
  echo "######################################################${txtrst}"
  ssh root@$host 'bash -s' << 'END'
  function printHeading() {
    echo -e "\n${txtund}[*] $1 \n######################################################${txtrst}"
  }
  PREREQS=( yum rpm ssh curl wget ntpd )
  POSSIBLE_CONFLICTS=( ruby postgresql nagios ganglia ganglia-gmetad libganglia libconfuse cloudera cdh mapr hadoop httpd apache2 http-server )
  CONFLICTING_CONF_DIRS=( /etc/hadoop /etc/hbase /etc/hcatalog /etc/hive /etc/flume /etc/ganglia /etc/httpd /etc/nagios /etc/oozie /etc/sqoop /etc/hue /etc/flume)
  CONFLICTING_RUN_DIRS=( /var/run/zookeeper /var/run/hadoop /var/run/hbase /var/run/ganglia /var/run/zookeeper /var/run/templeton /var/run/oozie /var/run/hive /var/run/hue /var/run/sqoop)
  CONFLICTING_LOG_DIRS=( /var/log/zookeeper /var/log/hadoop /var/log/nagios /var/log/hbase /var/log/hive /var/log/templeton /var/log/oozie /var/log/flume /var/log/hadoop* /var/log/sqoop )
  CONFLICTING_USERS=( postgres puppet ambari_qa hadoop_deploy rrdcached apache zookeeper mapred hdfs hbase hive hcat mysql nagios oozie sqoop flume hbase)
  CONFLICTING_PACKAGES=( ambari hadoop* hbase hcatalog hive ganglia nagios oozie sqoop hue zookeeper mapred hdfs flume)
  CONFLICTING_LIB_DIRS=( /var/lib/hadoop* /usr/lib/oozie /usr/lib/hive)
  CONFLICTING_OS_DETECTION_FILES=( /etc/debian_version /etc/debian_version /etc/gentoo-release /etc/fedora-release /etc/mandriva-release /etc/mandrake-release /etc/meego-release /etc/arch-release /etc/oracle-release /etc/enterprise-release /etc/ovs-release /etc/vmware-release /etc/bluewhite64-version /etc/slamd64-version /etc/slackware-version /etc/alpine-release )
  REPOS=( HDP-1 HDP-UTILS epel)
  printHeading "Checking Processors"
  cat /proc/cpuinfo  | grep 'model name' | awk -F': ' '{ print $2; }'
  printHeading "Checking RAM"
  cat /proc/meminfo  | grep MemTotal | awk '{ print $2/1024/1024 " GB"; }'
  printHeading "Checking disk space"
  df -h
  printHeading "List all PCI devices"
  lspci
  printHeading "Checking OS, arch, and kernel"
  cat /etc/issue.net | head -1 
  arch
  uname -a
  printHeading "Checking host files"
  cat /etc/hosts
  printHeading "Checking hostname"
  echo "hostname -f: `hostname -f`" 
  echo "hostname -i: `hostname -i`"
  printHeading "Checking iptables"
  iptables -vnL
  printHeading "Checking SELinux configuration"
  cat /etc/selinux/config | grep ^SELINUX
  printHeading "Listing yum repositories"
  yum repolist
  REPOLIST=`yum repolist`
  printHeading "List all installed yum packages"
  yum list installed
  printHeading "Looking for required repos"
  for repo in ${REPOS[@]}; do
  	echo -n "${repo} ... "
	echo $REPOLIST | grep ${repo} > /dev/null
	if [ $? -ne 0 ]; then
	  echo "Not Found!!"
	else
	  echo "Found"
	fi
  done
  printHeading "Checking for conflicting entries in /etc"
  for path in ${CONFLICTING_CONF_DIRS[@]}; do
	if [ -f ${path} ] || [ -d ${path} ]; then
		echo "Found ${path}!!"
	fi
  done
  printHeading "Checking for conflicting entries in /var/run"
  for path in ${CONFLICTING_RUN_DIRS[@]}; do
	if [ -f ${path} ] || [ -d ${path} ]; then
		echo "Found ${path}!!"
	fi
  done
  printHeading "Checking for conflicting entries in /log"
  for path in ${CONFLICTING_LOG_DIRS[@]}; do
	if [ -f ${path} ] || [ -d ${path} ]; then
		echo "Found ${path}!!"
	fi
  done
  printHeading "Checking for conflicting entries in /*/lib"
  for path in ${CONFLICTING_LIB_DIRS[@]}; do
	if [ -f ${path} ] || [ -d ${path} ]; then
		echo "Found ${path}!!"
	fi
  done
  printHeading "Checking for conflicting users in /etc/passwd"
  for user in ${CONFLICTING_USERS[@]}; do
	cat /etc/passwd | grep $user > /dev/null
	if [ $? -eq 0 ]; then
		echo "Found user: ${user}!!"
	fi
  done
  printHeading "Checking for conflicting misc directories"
  for package in ${CONFLICTING_PACKAGES[@]}; do
	find / -name "$package*" -type d
  done
  printHeading "Checking prereq packages"
  RPMS=`rpm -qa`
  for package in ${PREREQS[@]}; do
    echo -n "Looking for: $package - "
    echo $RPMS | grep $package > /dev/null
    if [ $? -eq 0 ]; then echo "found";  else echo "NOT FOUND!";  fi
  done
  for package in ${POSSIBLE_CONFLICTS[@]}; do
    echo -n "Looking for possible conflicting package: $package - "
    echo $RPMS | grep $package > /dev/null
    if [ $? -eq 0 ]; then echo "FOUND! `rpm -qa | grep $package`" ; else echo "not installed"; fi
  done
  printHeading "Checking for java processes"
  ps aux | grep java
  printHeading "Checking for listening Hadoop processes"
  netstat -natp | grep java
  printHeading "Checking for conflicting OS detection files"
  for file in ${CONFLICTING_OS_DETECTION_FILES[@]}; do
	if [ -f $file ]; then echo "FOUND! $file" ; else echo "not found"; fi
  done
END
done
