#!/bin/bash
mkdir /root/hdp && cd /root/hdp
if [ -d /root/hdp ]; then
	yum -y install wget unzip
	wget --no-check-certificate https://github.com/hortonworks/HDP-Public-Utilities/zipball/master -O tools.zip
	if [ -f tools.zip ]; then
		unzip tools.zip
		mv hortonworks-HDP*/Installation/*.sh .
		chmod u+x *.sh
	fi
fi