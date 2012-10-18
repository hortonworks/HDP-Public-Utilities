# Prep Cluster
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
cd /root
mkdir hdp && cd hdp
vi Hostdetail.txt
wget --no-check-certificate https://github.com/pcodding/HDPSETools/zipball/master -O tools.zip
unzip tools.zip
mv pc*/Installation/*.sh .
chmod u+x *.sh
rm -f tools.zip
rm -rf pc*
ssh-keygen
./distribute_ssh_keys.sh /root/.ssh/id_rsa.pub
vi /etc/fstab
vi /etc/selinux/config
./run_command.sh 'cat /etc/fstab'
./copy_file.sh /etc/fstab /etc
./copy_file.sh /etc/selinux/config /etc/selinux/
./run_command.sh 'chkconfig --del iptables'
./run_command.sh 'service iptables stop'
./run_command.sh 'iptables -vnL'
./run_command.sh 'yum -y erase mysql-libs'
./run_command.sh 'yum -y install net-snmp net-snmp-utils ntpd'
./run_command.sh 'reboot'
./run_command.sh 'service ntpd start'
./pre_install_check.sh > out
# rpm -Uvh http://public-repo-1.hortonworks.com/HDP-1.1.0.15/repos/centos6/hdp-release-1.1.0.15-1.el6.noarch.rpm
# yum install epel-release
# yum install hmc
# service hmc start