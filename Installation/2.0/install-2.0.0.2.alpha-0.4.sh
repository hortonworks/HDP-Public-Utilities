#!/bin/sh

#
# Scripted Hortonworks Data Platform 2.0 Alpha 2 based on manual installation
# Author: Jean-Philippe Player, based on HDP 1.x script
# Changes
#   - 0.7 Fix WebHDFS, Add support for WebHCat, HBase in Yarn
#   - 0.6 Add support for HUE [todo]
#   - 0.5 Add support for Hive 0.11 [todo]
#   - 0.4 Added support for Tez
#   - 0.3 Clean up
#   - 0.2 Added support for multiple nodes, deploy password-less ssh, create local repository
#   - 0.1 First Release. Ported to HDP2 for single host, with support for YARN.

# THIS IS FOR CENTOS 6 ONLY

HDFS_NAMENODE="node1.hadoop"
HDFS_SECONDARY="node1.hadoop"
HDFS_DATANODES="node2.hadoop,node3.hadoop,node4.hadoop"
YARN_RESOURCEMANAGER="node1.hadoop"
YARN_NODEMANAGERS="$HDFS_DATANODES"
HIVE_HOST="node1.hadoop"
HBASE_MASTER="node1.hadoop"
HBASE_REGIONSERVERS="$HDFS_DATANODES"
OOZIE_HOST="node1.hadoop"
ZOOKEEPER_QUORUM="node1.hadoop"
TEZ_HOST="node1.hadoop"
CLIENTS=""

#Set PROMPT=yes to prompt user between sections, PROMPT=no will not stop for anything.
PROMPT="yes"

FORCE_REPO="false"
while getopts ":f" opt; do
    case $opt in
        f)
        FORCE_REPO="true"
        ;;
    esac
done

#
# Experimental
#

PROPAGATE_IDENTITY="true"
ROOT_PASSWORD="hadoop"

#MIRROR_HOST must point to the machine running this script
CREATE_LOCAL_REPO="true"
MIRROR_HOST=`hostname -f`
MIRROR_DIR="/var/www/html/mirror"
MIRROR_HTTP="$MIRROR_HOST/mirror"

#
# Internal
#

ALL_HOSTS=`echo "$HDFS_NAMENODE,$HDFS_SECONDARY,$HDFS_DATANODES,$YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS,$ZOOKEEPER_QUORUM" | tr ',' '\n' | sort | uniq | tr '\n' ',' | sed s'/,$//'`
ALL_HOSTS_LIST=`echo $ALL_HOSTS | tr ',' '\n'`
ALL_OTHER_HOSTS=`echo $ALL_HOSTS | sed -e 's/'"$MIRROR_HOST"'\,*//' | sed s'/,$//'`
ALL_OTHER_HOSTS_LIST=`echo $ALL_OTHER_HOSTS | tr ',' '\n'`
#
# Helper function
#
function waitp(){
    if [ $PROMPT == "yes" ]; then
        read -p "$1. Press [ENTER] key to continue..."
    else
        echo "$1"
        sleep 3
    fi
}
#
# These must match the location used by the RPMs
#
HADOOP_LIB_DIR="/usr/lib/hadoop"
YARN_LIB_DIR="/usr/lib/hadoop-yarn"
MAPRED_LIB_DIR="/usr/lib/hadoop-mapreduce"
HIVE_LIB_DIR="/usr/lib/hive"
#These should be added to the helper scripts
TEZ_LOG_DIR="/var/log/tez"
TEZ_PID_DIR="/var/run/tez"
TEZ_HOME="/usr/lib/tez"
TEZ_CONF_DIR="/etc/tez/conf"

#
# Download RPM repo configuration
#
waitp "Downloading RPM repo configuration . . ."
cd /etc/yum.repos.d/
curl -O http://public-repo-1.hortonworks.com/HDP-2.0.0.2/repos/centos6/hdp.repo

#
# Set up pdsh
#
yum -y install pdsh

#
# Setup password-less ssh if not present
#
ERROR=$(pdsh -w "$ALL_HOSTS" "echo hello" 2>&1 >/dev/null)
if [ "$ERROR" != "" ]; then
    echo "Password-less ssh not enabled for all hosts, or hosts unreachable."
    echo "=======ERROR======="
    echo "$ERROR"
    echo "==================="
    
    if [ ! -z "$PROPAGATE_IDENTITY" ] && [ "$PROPAGATE_IDENTITY" == "true" ]
        then
         
    KEY="~/.ssh/id_rsa.pub ~/.ssh/id_rsa"
    if [ ! -f ~/.ssh/id_rsa.pub ] || [ ! -f  ~/.ssh/id_rsa ]; then
        echo "public or private key not found at $KEY"
        echo "* please create it with "ssh-keygen -t rsa" *"
        echo "* to login to the remote host without a password, don't give the key you create with ssh-keygen a password! *"
        exit
    fi
    echo "WARNING: Propagating identity is enabled. Propagating identity to all hosts."
    echo "Press CTRL-C now to stop."
    waitp
    # Install sshpass
    rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
    yum -y install sshpass
    rm -f /etc/yum.repos.d/*rpmforge*
    yum clean all
    # Use the root password
#    for host in $ALL_OTHER_HOSTS_LIST; do
     for host in $ALL_HOSTS_LIST; do
        # TODO Is there a better to accept the original fingerprint that this dummy echo hello ? 
        sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no root@${host} "echo hello"
        sshpass -p "$ROOT_PASSWORD" ssh-copy-id root@${host}
    done
    else
        echo "ERROR: Check error above. You may need to setup password-less ssh manually"
        echo "or set this script to PROPAGATE_IDENTITY=true"
        exit
    fi
fi

#
# Create local repository (if not exists)
#
# TODO: BUG: we are downloading HDP twice here

if [ $CREATE_LOCAL_REPO=="true" ]; then

if [ ! -d "$MIRROR_DIR" ] || [ $FORCE_REPO == "true" ]; then
# Setup httpd
waitp "Setting up local repository"
yum -y install httpd
chkconfig httpd on
service httpd start
yum -y install yum-utils createrepo
mkdir -p "$MIRROR_DIR"
cd "$MIRROR_DIR"
reposync -r HDP-2.0.0.2
reposync -r HDP-UTILS-1.1.0.15
createrepo /var/www/html/mirror/HDP-2.0.0.2
createrepo /var/www/html/mirror/HDP-UTILS-1.1.0.15
#Java
mkdir -p "$MIRROR_DIR/ARTIFACTS"
cd "$MIRROR_DIR/ARTIFACTS"
if [ ! -e "$MIRROR_DIR/ARTIFACTS/jdk-6u31-linux-x64.bin" ]; then
    curl -O http://public-repo-1.hortonworks.com/ARTIFACTS/jdk-6u31-linux-x64.bin
fi
if [ ! -e "$MIRROR_DIR/ARTIFACTS/mysql-connector-java-5.1.18.zip" ]; then
    curl -O http://public-repo-1.hortonworks.com/ARTIFACTS/mysql-connector-java-5.1.18.zip
fi
# Download all dependencies into misc repo
waitp "Downloading all dependencies locally."
yum -y install yum-downloadonly
mkdir -p "$MIRROR_DIR/dependencies"
ALL_PACKAGES="pdsh yum-plugin-priorities hadoop hadoop-hdfs hadoop-libhdfs hadoop-yarn hadoop-mapreduce  hadoop-client openssl snappy snappy-devel hadoop-lzo lzo lzo-devel hadoop-lzo-native mysql-server hive hcatalog pig zookeeper hbase tez"
yum install $ALL_PACKAGES -y --downloadonly --downloaddir=$MIRROR_DIR/dependencies
createrepo "$MIRROR_DIR/dependencies"
fi

echo "Setting yum repository mirror to  $MIRROR_DIR . . ."
sed -i 's;public-repo-1.hortonworks.com/HDP-2.0.0.2/repos/centos6;'"$MIRROR_HTTP/HDP-2.0.0.2"';g' /etc/yum.repos.d/hdp.repo 
sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/hdp.repo
sed -i 's;public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.15/repos/centos6;'"$MIRROR_HTTP/HDP-UTILS-1.1.0.15"';g' /etc/yum.repos.d/hdp.repo 
cat > /etc/yum.repos.d/dependencies.repo << EOF
[dependencies]
name=Hortonworks Data Platform Dependencies - HDP-2.0.0.2
baseurl=http://TODO_PATH_TO_REPOSITORY
gpgcheck=0
enabled=1
priority=1
EOF
sed -i 's;TODO_PATH_TO_REPOSITORY;'"$MIRROR_HTTP/dependencies"';g' /etc/yum.repos.d/dependencies.repo 
#
# Deploy repository to all hosts
#
waitp "Deploying repository to all other hosts"
for host in $ALL_OTHER_HOSTS_LIST; do
    scp -o StrictHostKeyChecking=no /etc/yum.repos.d/hdp.repo root@$host:/etc/yum.repos.d
    scp -o StrictHostKeyChecking=no /etc/yum.repos.d/dependencies.repo root@$host:/etc/yum.repos.d
done
fi

#
# Set up yum priorities.
#
waitp "Setting up yum priorities on all hosts."
pdsh -w $ALL_HOSTS "yum -y install yum-plugin-priorities"

#
# Set up pdsh on all hosts (to make pdcp work)
#

if [ "$ALL_OTHER_HOSTS" != "" ]; then
waitp "Deploying pdsh to all hosts"
pdsh -w $ALL_OTHER_HOSTS "yum -y install pdsh"
fi

#
# Install JDK 1.6.0_31
#
VERSION="none"
if [ -e /usr/bin/java ]; then
    VERSION=`java -version 2>&1 | grep 'java version' | awk '{ print substr($3, 2, length($3)-2); }'`
fi
if [ $VERSION != "1.6.0_31" ]
    then    
waitp "Installing JDK 1.6.0_31 . . ."
# TODO: handle non-local repo case
# Push java to each host
echo "Deploying Java to all hosts . . ."
pdsh -w $ALL_HOSTS "mkdir -p /usr/java"
pdcp -w $ALL_HOSTS "$MIRROR_DIR/ARTIFACTS/jdk-6u31-linux-x64.bin" /usr/java
pdsh -w $ALL_HOSTS "cd /usr/java; chmod +x jdk-6u31-linux-x64.bin; ./jdk-6u31-linux-x64.bin -noregister < <(echo N)"
pdsh -w $ALL_HOSTS "rm -f /usr/java/default; ln -s /usr/java/jdk1.6.0_31 /usr/java/default"
pdsh -w $ALL_HOSTS "rm -f /usr/bin/java; ln -s /usr/java/default/bin/java /usr/bin/java"
# Put JAVA_HOME in the environment on vm startup
pdsh -w $ALL_HOSTS 'echo "export JAVA_HOME=/usr/java/default" > /etc/profile.d/java.sh'
pdsh -w $ALL_HOSTS 'echo "export PATH=$JAVA_HOME/bin:$PATH" >> /etc/profile.d/java.sh'
fi

#
# Download helper files
#

HELPER_FILE_DIR="/opt/hdp_manual_install_rpm_helper_files-2.0.0.22"
waitp "Downloading helper files . . ."
cd /opt
curl -O http://public-repo-1.hortonworks.com/HDP-2.0.0.2/tools/hdp_manual_install_rpm_helper_files-2.0.0.22.tar.gz
tar xfz hdp_manual_install_rpm_helper_files-2.0.0.22.tar.gz
source $HELPER_FILE_DIR/scripts/directories.sh
source $HELPER_FILE_DIR/scripts/usersAndGroups.sh

# NO LONGER NECESSARY ?
if [ ]
    then
#
# Create Hadoop group and system users
#
echo "Creating Hadoop group . . ."
groupadd $HADOOP_GROUP
echo "Creating Hadoop system accounts . . ."
useradd -g $HADOOP_GROUP $HDFS_USER
useradd -g $HADOOP_GROUP $MAPRED_USER
useradd -g $HADOOP_GROUP $HIVE_USER
useradd -g $HADOOP_GROUP $PIG_USER
useradd -g $HADOOP_GROUP hcat
useradd -g $HADOOP_GROUP $TEMPLETON_USER
useradd -g $HADOOP_GROUP $HBASE_USER
useradd -g $HADOOP_GROUP $ZOOKEEPER_USER
useradd -g $HADOOP_GROUP $OOZIE_USER
sleep 3
clear
fi

#
# Substitute directory names in directories.sh
#
echo "Creating directory names . . ."
cd $HELPER_FILE_DIR/scripts
echo "Setting NameNode data directory to /hadoop/hdfs/nn . . ."
sed -i  's/TODO-LIST-OF-NAMENODE-DIRS/\/hadoop\/hdfs\/nn/g' ./directories.sh
echo "Setting DataNode data directory to /hadoop/hdfs/dn . . ."
sed -i  's/TODO-LIST-OF-DATA-DIRS/\/hadoop\/hdfs\/dn/g' ./directories.sh
echo "Setting Secondary NameNode data directory to /hadoop/hdfs/snn . . ."
sed -i  's/TODO-LIST-OF-SECONDARY-NAMENODE-DIRS/\/hadoop\/hdfs\/snn/g' ./directories.sh
echo "Setting YARN temporary data directory to /hadoop/yarn/tmp . . ."
sed -i  's/TODO-LIST-OF-YARN-LOCAL-DIRS/\/hadoop\/yarn\/tmp/g' ./directories.sh
echo "Setting YARN log directory to /var/log/hadoop/yarn . . ."
sed -i  's;TODO-LIST-OF-YARN-LOG-DIRS;/var/log/hadoop/yarn;g' ./directories.sh
# Workarounds
echo "MAPRED_LOG_DIR=\"/var/log/hadoop/mapred\"" >> ./directories.sh
echo "HBASE_PID_DIR=\"/var/run/hbase\"" >> ./directories.sh

#echo "Setting MapReduce data directory to /hadoop/mapred . . ."
#sed -i 's/TODO-LIST-OF-MAPRED-DIRS/\/hadoop\/mapred/g' ./directories.sh
echo "Setting ZooKeeper data directory to /hadoop/zookeeper/data . . ."
# There is a typo in the file reflected below
sed -i 's/TODO-ZOOKEPPER-DATA-DIR/\/hadoop\/zookeeper\/data/g' ./directories.sh
source ./directories.sh

#
# Install Hadoop core
#
waitp "Downloading and installing Hadoop core . . ."
pdsh -w $ALL_HOSTS "yum -y install hadoop hadoop-hdfs hadoop-libhdfs hadoop-yarn hadoop-mapreduce  hadoop-client openssl"
echo "Downloading and installing Snappy . . ."
pdsh -w $ALL_HOSTS "yum -y install snappy snappy-devel"
pdsh -w $ALL_HOSTS "ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native"
echo "Downloading and installing LZO . . ."
pdsh -w $ALL_HOSTS "yum -y install hadoop-lzo lzo lzo-devel hadoop-lzo-native"

echo "Creating Hadoop core directories . . ."
# Namenode
pdsh -w $HDFS_NAMENODE "mkdir -p $DFS_NAME_DIR"
pdsh -w $HDFS_NAMENODE "chown -R $HDFS_USER:$HADOOP_GROUP $DFS_NAME_DIR"
pdsh -w $HDFS_NAMENODE "chmod -R 755 $DFS_NAME_DIR"
# Secondary
pdsh -w $HDFS_SECONDARY "mkdir -p $FS_CHECKPOINT_DIR"
pdsh -w $HDFS_SECONDARY "chown -R $HDFS_USER:$HADOOP_GROUP $FS_CHECKPOINT_DIR"
pdsh -w $HDFS_SECONDARY "chmod -R 755 $FS_CHECKPOINT_DIR"
# Datanodes
pdsh -w $HDFS_DATANODES "mkdir -p $DFS_DATA_DIR"
pdsh -w $HDFS_DATANODES "chown -R $HDFS_USER:$HADOOP_GROUP $DFS_DATA_DIR"
pdsh -w $HDFS_DATANODES "chmod -R 750 $DFS_DATA_DIR"
# All HDFS hosts
pdsh -w $HDFS_NAMENODE,$HDFS_NAMENODE,$HDFS_DATANODES "mkdir -p $HDFS_LOG_DIR"
pdsh -w $HDFS_NAMENODE,$HDFS_NAMENODE,$HDFS_DATANODES "chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_LOG_DIR"
pdsh -w $HDFS_NAMENODE,$HDFS_NAMENODE,$HDFS_DATANODES "chmod -R 755 $HDFS_LOG_DIR"
pdsh -w $HDFS_NAMENODE,$HDFS_NAMENODE,$HDFS_DATANODES "mkdir -p $HDFS_PID_DIR"
pdsh -w $HDFS_NAMENODE,$HDFS_NAMENODE,$HDFS_DATANODES "chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_PID_DIR"
pdsh -w $HDFS_NAMENODE,$HDFS_NAMENODE,$HDFS_DATANODES "chmod -R 755 $HDFS_PID_DIR"

# All YARN hosts
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "mkdir -p $YARN_LOG_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOG_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "chmod -R 755 $YARN_LOG_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "mkdir -p $YARN_PID_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "chown -R $YARN_USER:$HADOOP_GROUP $YARN_PID_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "chmod -R 755 $YARN_PID_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "mkdir -p $YARN_LOCAL_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOCAL_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "chmod -R 755 $YARN_LOCAL_DIR"
#No longer needed
if [ ] 
    then
mkdir -p $MAPREDUCE_LOCAL_DIR
chown -R $MAPRED_USER:$HADOOP_GROUP $MAPREDUCE_LOCAL_DIR
chmod -R 755 $MAPREDUCE_LOCAL_DIR
fi

# MAPRED AM
#mkdir -p $HADOOP_MAPRED_LOG_DIR
#chown -R $MAPRED_USER:$HADOOP_GROUP $HADOOP_MAPRED_LOG_DIR
#chmod -R 755 $HADOOP_MAPRED_LOG_DIR
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "mkdir -p $MAPRED_LOG_DIR"
#workaround
#chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_LOG_DIR
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "chown -R $YARN_USER:$HADOOP_GROUP $MAPRED_LOG_DIR"
pdsh -w $YARN_RESOURCEMANAGER,$YARN_NODEMANAGERS "chmod -R 755 $MAPRED_LOG_DIR"
#mkdir -p $MAPRED_PID_DIR
#chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_PID_DIR
#chmod -R 755 $MAPRED_PID_DIR

echo "Editing Hadoop core configuration files . . ."
cd $HELPER_FILE_DIR/configuration_files/core_hadoop
sed -i "s/TODO-NAMENODE-HOSTNAME/$HDFS_NAMENODE/g" ./core-site.xml
sed -i 's;TODO-FS-CHECKPOINT-DIR;'"$FS_CHECKPOINT_DIR"';g' ./core-site.xml
sed -i 's;TODO-DFS-NAME-DIR;'"$DFS_NAME_DIR"';g' ./hdfs-site.xml
sed -i 's;TODO-DFS-DATA-DIR;'"$DFS_DATA_DIR"';g' ./hdfs-site.xml
sed -i "s/TODO-NAMENODE-HOSTNAME/$HDFS_NAMENODE/g" ./hdfs-site.xml
sed -i "s/TODO-SECONDARYNAMENODE-HOSTNAME/$HDFS_SECONDARY/g" ./hdfs-site.xml

#Single node only
if [ ] #if count(ALL_HOSTS = 1 then)
    then
sed -i '75i<property>' ./hdfs-site.xml
sed -i '76i<name>dfs.replication</name>' ./hdfs-site.xml
sed -i '77i<value>1</value>' ./hdfs-site.xml
sed -i '78i</property>' ./hdfs-site.xml
fi

# YARN
sed -i "s/TODO-RMNODE-HOSTNAME/$YARN_RESOURCEMANAGER/g" ./yarn-site.xml
sed -i 's;TODO-YARN-LOCAL-DIR;'"$YARN_LOCAL_DIR"';g' ./yarn-site.xml
sed -i 's;TODO-YARN-LOG-DIR;'"$YARN_LOG_DIR"';g' ./yarn-site.xml

# MR v1 on YARN
sed -i "s/TODO-RMNODE-HOSTNAME/$YARN_RESOURCEMANAGER/g" ./mapred-site.xml

#sed -i 's;TODO-MAPRED-LOCAL-DIR;'"$MAPREDUCE_LOCAL_DIR"';g' ./mapred-site.xml
#sed -i "s/TODO-JTNODE-HOSTNAME/$FQDN/g" ./mapred-site.xml
#sed -i 's;TODO-MAPRED-LOCAL-DIR;'"$MAPREDUCE_LOCAL_DIR"';g' ./mapred-site.xml
#sed -i 's/TODO-HADOOP-GROUP/$HADOOP_GROUP/g' ./mapred-site.xml
#sed -i 's;TODO-MAPRED-LOCAL-DIR;'"$MAPREDUCE_LOCAL_DIR"';g' ./taskcontroller.cfg

sed -i 's/-XX:NewSize=[0-9*m|G]*/-XX:NewSize=64m/g' ./hadoop-env.sh
sed -i 's/-XX:MaxNewSize=[0-9*m|G]*/-XX:MaxNewSize=64m/g' ./hadoop-env.sh
sed -i 's/-Xmx[0-9*m|G]*/-Xmx512m/g' ./hadoop-env.sh
sed -i 's/-Xms[0-9*m|G]*/-Xms512m/g' ./hadoop-env.sh

# Workaround: NEED TO FIX THE BAD HEALTH CHECK: port 50060 instead of 8042
sed -i "s/50060/8042/g" ./health_check

echo "$HDFS_DATANODES" | tr ',' '\n' > "$HADOOP_CONF_DIR/slaves"

waitp "Deploying Hadoop core configuration files . . ."
pdsh -w $ALL_HOSTS "rm -rf $HADOOP_CONF_DIR"
pdsh -w $ALL_HOSTS "mkdir -p $HADOOP_CONF_DIR"
pdcp -w $ALL_HOSTS ./* "$HADOOP_CONF_DIR"
pdsh -w $ALL_HOSTS "chmod a+x $HADOOP_CONF_DIR"
pdsh -w $ALL_HOSTS "chown -R $HDFS_USER:$HADOOP_GROUP $HADOOP_CONF_DIR/../"
pdsh -w $ALL_HOSTS "chmod -R 755 $HADOOP_CONF_DIR/../"


#workarounds
pdsh -w $ALL_HOSTS "ln -s $HADOOP_LIB_DIR/libexec $YARN_LIB_DIR/"
pdsh -w $ALL_HOSTS "ln -s $HADOOP_LIB_DIR/libexec $MAPRED_LIB_DIR/"
#TODO: HOW DO I SPECIFY THE LOG DIRECTION FOR MR ON YARN ???
# THIS SHOULD NOT BE NECESSARY
pdsh -w $ALL_HOSTS "ln -s $MAPRED_LOG_DIR $MAPRED_LIB_DIR/logs"
#yarn.nodemanager.remote-app-log-dir (set to /tmp/logs instead of /app-logs)
# OR CREATE FOLDER app-logs for YARN in HDFS

#
# Boot up HDFS
#
waitp "Formatting HDFS . . ."
pdsh -w $HDFS_NAMENODE 'su hdfs -c "echo Y| hdfs namenode -format"'
waitp "Starting HDFS . . ."
pdsh -w $HDFS_NAMENODE 'su hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh start namenode"'
pdsh -w $HDFS_DATANODES 'su hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh start datanode"'
pdsh -w $HDFS_SECONDARY 'su hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh start secondarynamenode"'
echo "Creating base folders in HDFS . . ."
pdsh -w $HDFS_NAMENODE 'su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/hdfs"'
pdsh -w $HDFS_NAMENODE 'su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /tmp"'
pdsh -w $HDFS_NAMENODE 'su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -chmod +wt /tmp"'

#
# Boot up YARN
#
waitp "Finishing YARN installation and MRv1 . . ."
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /mapred/history/done_intermediate"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chmod -R 1777 /mapred/history/done_intermediate"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /mapred/history/done"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chmod -R 1777 /mapred/history/done"
# notice yarn owns this folder. MR will not work because of permissions otherwise (to verify)
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chown -R yarn /mapred"
# This is a workaround for MR1 on YARN. Remove or alter config.
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /app-logs"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chown -R yarn /app-logs"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chmod -R +wt /app-logs"

pdsh -w $YARN_RESOURCEMANAGER 'su yarn -c "/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh start resourcemanager"'
pdsh -w $YARN_NODEMANAGERS 'su yarn -c "/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh start nodemanager"'
pdsh -w $YARN_RESOURCEMANAGER 'su yarn -c "/usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh start historyserver"'

#
# Download MySQL and install
#
waitp "Downloading MySQL . . ."
yum -y install mysql-server
echo "Starting MySQL . . ."
chkconfig mysqld on
service mysqld start
echo "Creating MySQL root account . . ."
mysqladmin -u root password 'mysql'
echo "Creating MySQL hive account . . ."
mysql -u root --password=mysql -e "CREATE USER 'hive'@'%' IDENTIFIED BY 'hive'"
mysql -u root --password=mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%'"
mysql -u root --password=mysql -e "DELETE FROM mysql.user WHERE user = ''"
mysql -u root --password=mysql -e "flush privileges"

#
# Install Hive and HCatalog
#
waitp "Downloading and installing Hive and HCatalog . . ."
pdsh -w $HIVE_HOST 'yum -y install hive hcatalog'
echo "Creating Hive directories . . ."
pdsh -w $HIVE_HOST "mkdir -p $HIVE_LOG_DIR"
pdsh -w $HIVE_HOST "chown -R $HIVE_USER:$HADOOP_GROUP $HIVE_LOG_DIR"
pdsh -w $HIVE_HOST "chmod 755 -R $HIVE_LOG_DIR"
echo "Editing Hive configuration files . . ."
cd $HELPER_FILE_DIR/configuration_files/hive
sed -i "s/TODO-HIVE-MYSQL-SERVER/$HIVE_HOST/g" ./hive-site.xml
sed -i 's/TODO-HIVE-MYSQL-PORT/3306/g' ./hive-site.xml
sed -i 's/TODO-HIVE-DATABASE-NAME/hive/g' ./hive-site.xml
sed -i 's/TODO-HIVE-METASTORE-USER-NAME/hive/g' ./hive-site.xml
sed -i 's/TODO-HIVE-METASTORE-USER-PASSWD/hive/g' ./hive-site.xml
sed -i "s/TODO-HIVE-METASTORE-SERVER-HOST/$HIVE_HOST/g" ./hive-site.xml
# There is an incorrect JAR file name in hive-env.sh.  Correct it as shown above.
# TODO: make this regexp more generic
sed -i 's/hcatalog-0.4.0.14.jar/hcatalog-core.jar/g' ./hive-env.sh
sed -i 's/1024/512/g' ./hive-env.sh
echo "Creating HCatalog configuration file . . ."
touch ./hcat-env.sh
echo "HCAT_PID_DIR=/var/run/hcatalog/" > ./hcat-env.sh
echo "HCAT_LOG_DIR=/var/log/hcatalog" >> ./hcat-env.sh
echo "HCAT_CONF_DIR=/etc/hcatalog/conf/" >> ./hcat-env.sh
echo "USER=hcat" >> ./hcat-env.sh
echo "METASTORE_PORT=9933" >> ./hcat-env.sh
echo "HADOOP_HOME=/usr/lib/hadoop" >> ./hcat-env.sh
echo "Deploying Hive configuration files . . ."
pdsh -w $HIVE_HOST "rm -rf $HIVE_CONF_DIR"
pdsh -w $HIVE_HOST "mkdir -p $HIVE_CONF_DIR"
pdcp -w $HIVE_HOST $HELPER_FILE_DIR/configuration_files/hive/hive* $HIVE_CONF_DIR
pdsh -w $HIVE_HOST "chown -R $HIVE_USER:$HADOOP_GROUP $HIVE_CONF_DIR/../"
pdsh -w $HIVE_HOST "chmod -R 755 $HIVE_CONF_DIR/../"
echo "Deploying HCatalog configuration files . . ."
pdsh -w $HIVE_HOST "rm -rf /etc/hcatalog/conf"
pdsh -w $HIVE_HOST "mkdir -p /etc/hcatalog/conf"
pdcp -w $HIVE_HOST $HELPER_FILE_DIR/configuration_files/hive/hcat* /etc/hcatalog/conf/
pdsh -w $HIVE_HOST "chown -R $HIVE_USER:$HADOOP_GROUP /etc/hcatalog/conf/"
pdsh -w $HIVE_HOST "chmod -R 755 /etc/hcatalog/conf/"
echo "Installing MySQL JDBC driver . . ."
# The following is recommended by the doc but is really bad: installed lots of bad dependencies (in particular an older version of Java)
# yum install mysql-connector-java-5.0.8-1
# DO THIS INSTEAD
#curl -O http://public-repo-1.hortonworks.com/ARTIFACTS/mysql-connector-java-5.1.18.zip
/usr/java/default/bin/jar xvf "$MIRROR_DIR/ARTIFACTS/mysql-connector-java-5.1.18.zip"
pdcp -w $HIVE_HOST ./mysql-connector-java-5.1.18/mysql-connector-java-5.1.18-bin.jar "$HIVE_LIB_DIR/lib/."
pdsh -w $HIVE_HOST "chmod 644 $HIVE_LIB_DIR/lib/*mysql*.jar"
su hdfs -c "hadoop fs -mkdir -p /apps/hive/warehouse"
su hdfs -c "hadoop fs -chown -R hive:hdfs /apps/hive"
su hdfs -c "hadoop fs -mkdir /user/$HIVE_USER"
su hdfs -c "hadoop fs -chown $HIVE_USER:$HIVE_USER /user/$HIVE_USER"
# BOOT UP
su $HIVE_USER -c "nohup hive --service metastore>$HIVE_LOG_DIR/hive.out 2>$HIVE_LOG_DIR/hive.log &"

#
# Tez AM for Hive
#

HADOOP_TEZ_COPY="/etc/hadoop-tez/conf"
HIVE_JAR_DIR="/apps/hive/tez-ampool-jars"
HIVE_HOME="/usr/lib/hive"

waitp "Installing Tez for Hive."
pdsh -w $TEZ_HOST,$YARN_NODEMANAGERS "yum -y install tez"
# 1. Enable Tez AM Globally
sed -i  's;<value>yarn</value>;<value>yarn-tez</value>;g' $HADOOP_CONF_DIR/mapred-site.xml
sed -i  's;</configuration>;;g' $HADOOP_CONF_DIR/mapred-site.xml
cat >> $HADOOP_CONF_DIR/mapred-site.xml << EOF
<property> 
 <name>mapreduce.application.classpath</name> 
 <value>/usr/lib/tez/*,/usr/lib/tez/lib/*</value> 
 <description>Classpath for MapReduce applications.</description> 
</property>
<property> 
 <name>yarn.app.mapreduce.am.scheduler.reuse.enable</name> 
 <value>true</value> 
 <description>Enable container reuse across task attempts. Default is
 set to false.</description> 
</property>
<property> 
 <name>yarn.app.mapreduce.am.scheduler.reuse.max-attempts-percontainer</name> 
 <value>-1</value> 
 <description>Defines number of task attempts to be run on a single
 container before the container is
 released. To disable this limit, set the value of this
 property to -1.</description> 
</property> 
</configuration>
EOF
echo 'export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:/usr/lib/tez/*:/usr/lib/tez/lib/*' >> $HADOOP_CONF_DIR/hadoop-env.sh
# 2. Config folder for use by Hive
mkdir -p $HADOOP_TEZ_COPY
cp -Rf $HADOOP_CONF_DIR/* "$HADOOP_TEZ_COPY"
chown -R $HIVE_USER:$HADOOP_GROUP $HADOOP_TEZ_COPY
chmod -R 755 $HADOOP_TEZ_COPY
# 3. Enable Tez for Hive
#export HADOOP_CONF="$HADOOP_TEZ_COPY"
waitp "Loading Tez library files to hdfs://$HIVE_JAR_DIR"
echo "Ensuring that the namenode is not in safe mode"
su hdfs -c "hdfs dfsadmin -safemode wait"
su hdfs -c "hadoop fs -mkdir -p $HIVE_JAR_DIR"
su hdfs -c "hadoop fs -put $HIVE_HOME/lib/hive*.jar $HIVE_JAR_DIR"
su hdfs -c "hadoop fs -chown -R $HIVE_USER:$HADOOP_GROUP $HIVE_JAR_DIR"
su hdfs -c "hadoop fs -chmod -R 755 $HIVE_JAR_DIR"
echo "export HADOOP_HOME=/usr/lib/hadoop" >> $TEZ_CONF_DIR/tez-env.sh
sed -i  's;</configuration>;;g' $TEZ_CONF_DIR/tez-ampool-site.xml
cat >> $TEZ_CONF_DIR/tez-ampool-site.xml << EOF
<property> 
 <name>tez.ampool.address</name> 
 <value>TODO_TEZ_HOST:10030</value> 
 <description>Address on which to run the ClientRMProtocol proxy.</description> 
</property>
<property> 
 <name>tez.ampool.mr-am.memory-allocation-mb</name> 
 <value>1536</value> 
 <description>Memory to use when launching the lazy MR AM.</description> 
</property>
<property> 
 <name>tez.ampool.mr-am.queue-name</name> 
 <value>default</value> 
 <description>Queue to which the Lazy MRAM is to be submitted to.</description> 
</property>
 
<property> 
 <name>tez.ampool.ws.port</name> 
 <value>12999</value> 
 <description>Port to use for AMPoolService status.</description> 
</property>
<property> 
 <name>tez.ampool.am-pool-size</name> 
 <value>1</value> 
 <description>Minimum size of AM Pool.</description> 
</property> 
<property> 
 <name>tez.ampool.max.am-pool-size</name> 
 <value>5</value> 
 <description>Maximum size of AM Pool.</description> 
</property> 
<property> 
 <name>tez.ampool.launch-new-am-after-app-completion</name> 
 <value>true</value> 
 <description>This property determines the time to launch new AM. 
 If set to true, new AM is launched after an existing AM in
 the pool completes execution. Otherwise,
 AM is launched as soon as a job is assigned to an AM from the pool.</description> 
</property>
<property> 
 <name>tez.ampool.max-am-launch-failures</name> 
 <value>2</value> 
 <description>Number of launch failures to account for unassigned AMs
 before shutting down AMPoolService.</description> 
</property>
<property>
 <name>tez.ampool.mr-am.job-jar-path</name> 
 <value>
 /apps/hive/tez-ampool-jars/hive-builtins-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-cli-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-common-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-contrib-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-exec-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-hbase-handler-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-hwi-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-jdbc-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-metastore-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-pdk-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-serde-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-service-0.10.0.22.jar,/apps/hive/tez-ampool-jars/hive-shims-0.10.0.22.jar
 </value> 
  <description>Location of the Hive JAR files on HDFS.</description> 
 </property> 
 <property> 
  <name>tez.ampool.tmp-dir-path</name> 
  <value>/tmp/ampoolservice/</value> 
  <description>Local filesystem path for staging local data used by
  AMPoolClient/AMPoolService.</description> 
 </property>
 <property> 
  <name>tez.ampool.am.staging-dir</name> 
  <value>/tmp/tez/ampool/staging/</value> 
  <description>Path on HDFS used by AMPoolService to upload lazy-mr-am
  config.</description> 
 </property>
 </configuration>
EOF
sed -i  's;TODO_TEZ_HOST;'"$TEZ_HOST"';g' $TEZ_CONF_DIR/tez-ampool-site.xml
sed -i  's;</configuration>;;g' $TEZ_CONF_DIR/lazy-mram-site.xml
cat >> $TEZ_CONF_DIR/lazy-mram-site.xml << EOF
<property> 
 <name>yarn.app.mapreduce.am.lazy.prealloc-container-count</name> 
 <value>1</value> 
 <description>Number of containers to pre-allocate after starting up. To
 use preallocation, the value for this property must be set to a non-zero
 value.</description> 
</property>
</configuration>
EOF
# deploy
pdcp -w $YARN_NODEMANAGERS $TEZ_CONF_DIR/* $TEZ_CONF_DIR
pdsh -w $YARN_NODEMANAGERS "mkdir -p $HADOOP_TEZ_COPY"
pdcp -w $YARN_NODEMANAGERS $HADOOP_TEZ_COPY/* $HADOOP_TEZ_COPY
# Boot up
echo "Starting pool of Tez AMs for Hive use."
su - hive -c "$TEZ_HOME/sbin/tez-daemon.sh start ampoolservice"

#
# Install WebHCat
# THIS PART HAS NOT YET BEEN MIGRATED ?? MAYBE THE FOLDER IS MISSING
# ALSO NEED VARIABLES IN directries.sh
#
if [ ]
    then
echo "Downloading and installing Templeton . . ."
yum -y install hcatalog webhcat-tar-hive webhcat-tar-pig
echo "Creating WebHCat directories . . ."
mkdir -p $WEBHCAT_LOG_DIR
chown -R $WEBHCAT_USER:$HADOOP_GROUP $WEBHCAT_LOG_DIR
chmod 755 -R $WEBHCAT_LOG_DIR
mkdir -p $WEBHCAT_PID_DIR
chown -R $WEBHCAT_USER:$HADOOP_GROUP $WEBHCAT_PID_DIR
chmod -R 755 $WEBHCAT_PID_DIR
# TODO TODO TODO - get the proper webhcat scripts for here
#cd $HELPER_FILE_DIR/configuration_files/templeton
#sed -i 's/TODO-HIVE-MYSQL-PORT/3306/g' ./templeton-site.xml
echo "Deploying WebHCat configuration files . . ."
rm -rf $WEBHCAT_CONF_DIR
mkdir -p $WEBHCAT_CONF_DIR
cp $HELPER_FILE_DIR/configuration_files/templeton/* $WEBHCAT_CONF_DIR
chown -R $WEBHCAT_USER:$HADOOP_GROUP $WEBHCAT_CONF_DIR
chmod -R 755 $WEBHCAT_CONF_DIR
# OLD ?
#ln -s /usr/share/templeton/templeton-0.1.4.16.jar /usr/share/templeton/templeton.jar
sleep 3
#clear
fi

#
# Install Pig
#
waitp "Downloading and installing Pig . . ."
yum -y install pig
echo "Creating Pig directories . . ."
mkdir -p $PIG_LOG_DIR
chown -R $PIG_USER:$HADOOP_GROUP $PIG_LOG_DIR
chmod 755 -R $PIG_LOG_DIR
echo "Deploying Pig configuration files . . ."
rm -rf $PIG_CONF_DIR
mkdir -p $PIG_CONF_DIR
cp $HELPER_FILE_DIR/configuration_files/pig/* $PIG_CONF_DIR
chown -R $PIG_USER:$HADOOP_GROUP $PIG_CONF_DIR/../
chmod -R 755 $PIG_CONF_DIR/../
sleep 3
#clear

#
# Install Sqoop
#
if [ ]
    then
waitp "Downloading and installing Sqoop . . ."
yum -y install sqoop
echo "Deploying Sqoop configuration files . . ."
rm -rf $SQOOP_CONF_DIR
mkdir -p $SQOOP_CONF_DIR
cp $HELPER_FILE_DIR/configuration_files/sqoop/* $SQOOP_CONF_DIR
chmod a+x $SQOOP_CONF_DIR/
chmod -R 755 $SQOOP_CONF_DIR/../
sleep 3
#clear
fi


#
# Install Oozie
#
if [ ]; then
waitp "Downloading and installing Oozie . . ."
yum -y install oozie extjs
/usr/lib/oozie/bin/oozie-setup.sh -hadoop 0.20.200 /usr/lib/hadoop -extjs /usr/share/HDP-oozie/ext-2.2.zip
echo "Creating Oozie directories . . ."
mkdir -p $OOZIE_DATA
chown -R $OOZIE_USER:$HADOOP_GROUP $OOZIE_DATA
chmod -R 755 $OOZIE_DATA
mkdir -p $OOZIE_LOG_DIR
chown -R $OOZIE_USER:$HADOOP_GROUP $OOZIE_LOG_DIR
chmod -R 755 $OOZIE_LOG_DIR
mkdir -p $OOZIE_PID_DIR
chown -R $OOZIE_USER:$HADOOP_GROUP $OOZIE_PID_DIR;
chmod -R 755 $OOZIE_PID_DIR
echo "Editing Oozie configuration files . . ."
cd $HELPER_FILE_DIR/configuration_files/oozie
sed -i "s/TODO-OOZIE-SERVER/$OOZIE_HOST/g" ./oozie-site.xml
sed -i 's;TODO-OOZIE-DATA-DIR;'"$OOZIE_DATA"';g' ./oozie-site.xml
# In oozie-env.sh, the log directory replacement marker has the underscore
sed -i 's;TODO-OOZIE-LOG_DIR;'"$OOZIE_LOG_DIR"';g' ./oozie-env.sh
sed -i 's;TODO-OOZIE-PID-DIR;'"$OOZIE_PID_DIR"';g' ./oozie-env.sh
sed -i 's;TODO-OOZIE-DATA-DIR;'"$OOZIE_DATA"';g' ./oozie-env.sh
echo "Deploying Oozie configuration files . . ."
rm -rf $OOZIE_CONF_DIR
mkdir -p $OOZIE_CONF_DIR
cp $HELPER_FILE_DIR/configuration_files/oozie/* $OOZIE_CONF_DIR
chown -R $OOZIE_USER:$HADOOP_GROUP $OOZIE_CONF_DIR/../
chmod -R 755 $OOZIE_CONF_DIR/../
#clear
fi

#
# Install HBase and ZooKeeper
#
yum -y install zookeeper hbase
waitp "Creating HBase directories . . ."
mkdir -p $HBASE_LOG_DIR
chown -R $HBASE_USER:$HADOOP_GROUP $HBASE_LOG_DIR
chmod -R 755 $HBASE_LOG_DIR
mkdir -p $HBASE_PID_DIR
chown -R $HBASE_USER:$HADOOP_GROUP $HBASE_PID_DIR
chmod -R 755 $HBASE_PID_DIR
echo "Creating ZooKeeper directories . . ."
mkdir -p $ZOOKEEPER_LOG_DIR
chown -R $ZOOKEEPER_USER:$HADOOP_GROUP $ZOOKEEPER_LOG_DIR
chmod -R 755 $ZOOKEEPER_LOG_DIR
mkdir -p $ZOOKEEPER_PID_DIR
chown -R $ZOOKEEPER_USER:$HADOOP_GROUP $ZOOKEEPER_PID_DIR
chmod -R 755 $ZOOKEEPER_PID_DIR
mkdir -p $ZOOKEEPER_DATA_DIR
chown -R $ZOOKEEPER_USER:$HADOOP_GROUP $ZOOKEEPER_DATA_DIR
chmod -R 755 $ZOOKEEPER_DATA_DIR
echo "Editing HBase configuration files . . ."
cd $HELPER_FILE_DIR/configuration_files/hbase
sed -i "s/TODO-HBASE-NAMENODE-HOSTNAME/$HDFS_NAMENODE/g" ./hbase-site.xml
sed -i "s/TODO-HBASEMASTER-HOSTNAME/$HBASE_MASTER/g" ./hbase-site.xml
sed -i "s/TODO-ZOOKEEPERQUORUM-SERVERS/$ZOOKEEPER_QUORUM/g" ./hbase-site.xml
sed -i 's/-Xmx[0-9*m|G]*/-Xmx512m/g' ./hbase-env.sh
echo "Editing ZooKeeper configuration files . . ."
cd $HELPER_FILE_DIR/configuration_files/zookeeper
sed -i '/^dataDir/ c\dataDir='"$ZOOKEEPER_DATA_DIR"'' ./zoo.cfg
ZOOKEEPER1=`echo ZOOKEEPER_QUORUM | tr ',' '\n' | sed -n '1 p'`
ZOOKEEPER2=`echo ZOOKEEPER_QUORUM | tr ',' '\n' | sed -n '2 p'`
ZOOKEEPER3=`echo ZOOKEEPER_QUORUM | tr ',' '\n' | sed -n '3 p'`
sed -i "s/TODO-ZOOKEEPER-SERVER-1/$ZOOKEEPER1/g" ./zoo.cfg
if [ "$ZOOKEEPER2" == "" ]; then
    sed -i '/TODO-ZOOKEEPER-SERVER-2/d' ./zoo.cfg
else
    sed -i "s/TODO-ZOOKEEPER-SERVER-2/$ZOOKEEPER2/g" ./zoo.cfg
fi
if [ "$ZOOKEEPER3" == "" ]; then
    sed -i '/TODO-ZOOKEEPER-SERVER-3/d' ./zoo.cfg
else
    sed -i "s/TODO-ZOOKEEPER-SERVER-3/$ZOOKEEPER3/g" ./zoo.cfg
fi
echo "Deploying HBase configuration files . . ."
rm -rf $HBASE_CONF_DIR
mkdir -p $HBASE_CONF_DIR
cp $HELPER_FILE_DIR/configuration_files/hbase/* $HBASE_CONF_DIR
chmod a+x $HBASE_CONF_DIR/
chown -R $HBASE_USER:$HADOOP_GROUP $HBASE_CONF_DIR/../
chmod -R 755 $HBASE_CONF_DIR/../
echo "Deploying ZooKeeper configuration files . . ."
rm -rf $ZOOKEEPER_CONF_DIR
mkdir -p $ZOOKEEPER_CONF_DIR
cp $HELPER_FILE_DIR/configuration_files/zookeeper/* $ZOOKEEPER_CONF_DIR
chmod a+x $ZOOKEEPER_CONF_DIR/
chown -R $ZOOKEEPER_USER:$HADOOP_GROUP $ZOOKEEPER_CONF_DIR/../
chmod -R 755 $ZOOKEEPER_CONF_DIR/../
#clear

#
# Install and configure startup scripts
#
if [ ]; then
echo "Deploying startup scripts . . ."
cd /opt
tar -zxvf ./init-scripts.tar.gz
cd init-scripts
# For DataNode on NameNode, we get rid of the secure DN startup...
sed -i '31iHADOOP_SECURE_DN_USER=""' ./hadoop-datanode
cp ./hadoop-* ./zookeeper ./hbase-* ./hive-* ./templeton-server ./hcatalog-server /etc/init.d/
chkconfig hadoop-namenode on
chkconfig hadoop-secondarynamenode on
chkconfig hadoop-jobtracker on
chkconfig hadoop-historyserver on
chkconfig hadoop-datanode on
chkconfig hadoop-tasktracker on
chkconfig oozie off
#clear
fi

#
# Start all services
#
if [ ]; then
echo "Starting Hadoop core ..."
service hadoop-namenode start
service hadoop-secondarynamenode start
service hadoop-datanode start
service hadoop-resourcemanager start
service hadoop-nodemanager start
service hadoop-historyserver start
#service hadoop-tasktracker start
fi

#
# Create HDFS directories
#
echo "Creating HDFS directories . . ."
su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/templeton"
su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -chown -R templeton:templeton /user/templeton"
su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /apps/templeton"
su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -chown -R templeton:users /apps/templeton"
su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -chmod -R 755 /apps/templeton"
su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /apps/hbase"
su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -chown -R hbase /apps/hbase"
sleep 3
#clear

#
# Rebooting machine
#
#echo "Rebooting . . ."
#reboot

#
# Ready
#
echo "======================================"
echo "Done. Ready to play . . ."
echo "Namenode http://$HDFS_NAMENODE:50070"
echo "YARN http://$YARN_RESOURCEMANAGER:8088"
#echo "HUE http://$HUE_HOST:8080"
echo "======================================"
