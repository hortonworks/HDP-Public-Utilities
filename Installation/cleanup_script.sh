#!/bin/bash

HDP_1_3_COMPONENTS=(hadoop* hadoop hbase hcatalog hive ganglia nagios oozie sqoop hue zookeeper mapred hdfs flume puppet ambari_qa hadoop_deploy rrdcached hcat ambari-server ambari-agent pig)

HDP_2_0_COMPONENTS=(yarn hive-hcatalog hive-webhcat webhcat storm storm-slider-client knox bigtop*)
HDP_2_1_COMPONENTS=(falcon ranger tez)
HDP_2_2_COMPONENTS=(kafka slider)
HDP_2_3_COMPONENTS=(spark ambari-metrics)

function debug() {
   echo "REPO_FILTER = $REPO_FILTER"
   
   echo "COMPONENTS TO BE REMOVED"
   for project in ${PROJECT_NAMES[@]}; do
      echo $project
   done

   echo "PROJECT_REGEX = $PROJECT_REGEX"
}

function removePackages() {
   # Erase packages found from repo list
   PACKAGES=(`yum list | egrep -E "$REPO_FILTER" | awk '{ print $1; }' | grep -v '^[0-9]'`)

   if [ ${#PACKAGES[@]} -gt "0" ]; then
      yum -y erase "${PACKAGES[@]}";
   else
      PACKAGES=(hadoop-hive hadoop-hbase hadoop-0.20-jobtracker hadoop-zookeeper hadoop-0.20 hadoop-0.20-datanode hadoop-0.20-namenode hadoop-hbase-master hadoop-0.20-native hadoop-pig hadoop-0.20-conf-pseudo hadoop-0.20-secondarynamenode hadoop-zookeeper-server hadoop-0.20-tasktracker oozie oozie-client flume flume-master flume-node sqoop sqoop-metastore hue sqoop-metastore bsub hue-filebrowser hue-useradmin hue hue-help hue-jobbrowser hue-about hue-beeswax hue-proxy hue-server hue-shell hue-plugins cloudera-hue-mysql hue-common cloudera-hadoop-lzo cloudera-cdh zookeeper bigtop-utils bigtop-jsvc cloudera-manager cloudera-manager-repository cloudera-manager-agent cloudera-manager-plugins cloudera-manager-daemons cdh3-repository)
      yum -y erase "${PACKAGES[@]}";
      echo "Erasing Default Packages"
   fi
}

function removeServiceAccounts() {
   for project in ${PROJECT_NAMES[@]}; do
      cat /etc/passwd | grep "$project" > /dev/null
      if [ $? -eq 0 ]; then
          userdel -r "$project"
      fi

   done
}

function removeAlternatives() {
   if [ -d /etc/alternative ]; then
      cd /etc/alternatives
        for name in `ls | egrep "$PROJECT_REGEX"`; do
          for path in `alternatives --display $name | grep priority | awk '{print $1}'`; do
             alternatives --remove $name $path
          done
        done
   fi
}

function removeFiles() {
  
  PATHS=( /etc /var/log /var/run /usr/lib /var/lib /var/tmp /tmp/ /var )
           
  for project in ${PROJECT_NAMES[@]}; do
     # Erase fs entries
     for base_path in ${PATHS[@]} ; do
        if [ -d "$base_path/$project" ] ; then
           rm -rf $base_path/$project
        fi
     done
  done
}

function removeCMF() {
   if [ -d /usr/lib64/cmf ]; then
      rm -rf /usr/lib64/cmf
   fi
}

function removePostgreSQL() {
   if [ -d /var/lib/pgsql ]; then
      rm -rf /var/lib/pgsql
   fi
}

function removeMySQL() {
   if [ -d /var/lib/mysql ]; then
      rm -rf /var/lib/mysql
   fi
}

function removeRepos() {
  if [ -d /etc/yum.repos.d ]; then
    cd /etc/yum.repos.d && egrep $REPO_FILTER *.repo | awk -F: '{ print $1; }' | sort -u | xargs -n 1 rm -f
  fi
}

#############################################################
#
# Main function. 
# 
# Determine which compoents need to be removed based on the 
# current installation type.
#############################################################

if [ $# -lt 1 ]
then
  echo "Usage : $0 cleanup_script <HADOOP INSTALL>"
  exit
fi

case $1 in
   Cloudera)  
        export REPO_FILTER='Cloudera'
        PROJECT_NAMES=("${HDP_1_3COMPONENTS[@]}") 
        ;;
   
    HDP-1.3)
        export REPO_FILTER='Updates-ambari-1.x|HDP-UTILS-1.1.0.15|HDP-1.2.0|AMBARI-1.x'
        PROJECT_NAMES=("${HDP_1_3COMPONENTS[@]}") 
        ;;
        
    HDP-2.0)
        export REPO_FILTER='Updates-ambari-1.4.1.25|HDP-UTILS-1.1.0.16|HDP-2.0.6|ambari-1.x'
        PROJECT_NAMES=("${HDP_1_3COMPONENTS[@]}") 

        for p in ${HDP_2_0_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done
        ;;

    HDP-2.1)
        export REPO_FILTER='Updates-ambari-1.6.1|HDP-UTILS-1.1.0.17|HDP-2.1|ambari-1.x'
        PROJECT_NAMES=("${HDP_1_3COMPONENTS[@]}") 

        for p in ${HDP_2_0_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done

        for p in ${HDP_2_1_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done
        ;;

    HDP-2.2)
        export REPO_FILTER='Updates-ambari-1.7.0|HDP-UTILS-1.1.0.20|HDP-2.2|ambari-1.x'

        PROJECT_NAMES=("${HDP_1_3COMPONENTS[@]}") 

        for p in ${HDP_2_0_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done

        for p in ${HDP_2_1_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done

        for p in ${HDP_2_2_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done
        ;;
    
    HDP-2.3)
        export REPO_FILTER='Ambari-2.1.0 - Updates|HDP-UTILS-1.1.0.20|HDP-2.3|Ambari-2.x'

        PROJECT_NAMES=("${HDP_1_3COMPONENTS[@]}") 

        for p in ${HDP_2_0_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done

        for p in ${HDP_2_1_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done

        for p in ${HDP_2_2_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done

        for p in ${HDP_2_3_COMPONENTS[@]}; do
           PROJECT_NAMES+=($p)
        done
        ;;
    
    *)  
        echo "You must provide a valid value for HADOOP DISTRO, e.g. Cloudera, HDP-1.3, HDP-2.0, etc"
        exit -1;

esac

export PATHS=( /etc /var/log /var/run /usr/lib /var/lib /var/tmp /tmp/ /var )
export PROJECT_REGEX=`echo ${PROJECT_NAMES[@]} | sed 's/ /|/g'`

if [ -n "$DEBUG_FLAG" ]; then
  debug
else
   removePackages
   removeAlternatives
   removeFiles
   removeServiceAccounts
   removeRepos
   removeCMF
   removePostgreSQL
   removeMySQL
fi


