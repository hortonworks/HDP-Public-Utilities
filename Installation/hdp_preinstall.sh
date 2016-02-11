#To Run On a New Cluster
#pdsh -w ^./Hostdetail.txt 'mkdir /root/hdp'
#./copy_file.sh hdp_preinstall.sh /root/hdp/hdp_preinstall.sh
# Before running ./run_command.sh, change script and add -tty to ssh, since these are sudo commands
#./run_command.sh /root/hdp/hdp_preinstall.sh


############Disable PackageKit#######
sudo sh -c 'sed -i 's/enabled=1/enabled=0/g' /etc/yum/pluginconf.d/refresh-packagekit.conf'


#Prep script for install

#umask
#echo umask 0022 >> /etc/profile
sudo sh -c 'umask 0022'

#!/bin/bash
# VM SWAPPINESS TO 0
sudo sh -c 'sysctl -a |grep vm.swappiness'
sudo sh -c 'sysctl -w vm.swappiness=0'
sudo sh -c 'echo verify swappiness adjusted'
sudo sh -c 'echo cat /proc/sys/vm/swappiness output:'
sudo sh -c 'cat /proc/sys/vm/swappiness'


# time sync
sudo sh -c 'echo adjust ntpd'
sudo sh -c 'yum -y install ntp'
sudo sh -c 'sudo service ntpd start'
sudo sh -c 'sudo chkconfig ntpd on'
sudo sh -c 'sudo /etc/init.d/ntpd start'
sudo sh -c 'sudo chkconfig --list ntpd'

#Disabling Firewall
sudo sh -c 'echo "Disabling IP Tables"'
sudo sh -c 'sudo chkconfig iptables off'
sudo sh -c 'sudo /etc/init.d/iptables stop'
sudo sh -c 'sudo service iptables stop'

#Selinux adjustment
sudo sh -c 'echo "Selinux adjustment"'
sudo sh -c 'grep "SELINUX=" /etc/selinux/config'
sudo sh -c 'sudo setenforce 0'
#sed --in-place -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo sh -c 'sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config'
sudo sh -c 'sudo sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config'
sudo sh -c 'grep "SELINUX=" /etc/selinux/config'


echo ATTN: if SELINUX changed to disable please ensure you reboot the server. thx
echo

#Set file-max; no. of open files for single user
sudo sh -c 'echo "* soft nofile 200000" >> /etc/security/limits.conf'
sudo sh -c 'echo "* hard nofile 200000" >> /etc/security/limits.conf'
sudo sh -c 'echo "200000" >> /proc/sys/fs/file-max'
sudo sh -c  'echo "fs.file-max=65536" >> /etc/sysctl.conf'

#Set process-max
sudo sh -c 'echo "* soft nproc 8192" >> /etc/security/limits.conf'
sudo sh -c 'echo "* hard nproc 16384" >> /etc/security/limits.conf'
sudo sh -c 'echo "* soft nproc 16384" >> /etc/security/limits.d/90-nproc.conf'

#ulimit -Hn
#ulimit -Sn
#ulimit -Hu
#ulimit -Su

# ULIMITS to be set
sudo sh -c 'echo ULIMITS adjustments'
sudo sh -c 'echo "hdfs - nofile 32768" >> /etc/security/limits.conf'
sudo sh -c 'echo "mapred - nofile 32768" >> /etc/security/limits.conf'
sudo sh -c 'echo "hbase - nofile 32768" >> /etc/security/limits.conf'
sudo sh -c 'echo "hdfs - nproc 32768" >> /etc/security/limits.conf'
sudo sh -c 'echo "mapred - nproc 32768" >> /etc/security/limits.conf'
sudo sh -c 'echo "hbase - nproc 32768" >> /etc/security/limits.conf'
#

#Set ipv6 to disable
sudo sh -c 'echo "" >> /etc/sysctl.conf'
sudo sh -c 'echo "# disable ipv6" >> /etc/sysctl.conf'
sudo sh -c 'echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf'
sudo sh -c 'echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf'
sudo sh -c 'echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf'


sudo sh -c 'echo "NETWORKING_IPV6=no" >>  /etc/sysconfig/network'

sudo sh -c 'echo '#Disable Swappiness' >> /etc/sysctl.conf'
sudo sh -c 'echo 'vm.swappiness=0' >> /etc/sysctl.conf'


echo "Disabling THP"
sudo sh -c 'echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag'
sudo sh -c 'echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled'

echo "Permanently Disabling THP"
sudo sh -c 'echo "" >> /etc/rc.local'
sudo sh -c 'echo "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi" >> /etc/rc.local'
 
