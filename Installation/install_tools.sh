#!/bin/bash
mkdir /root/hdp 2>/dev/null
if [ -d /root/hdp ]; then
	cd /root/hdp
	yum -y install wget unzip
	wget --no-check-certificate https://github.com/hortonworks/HDP-Public-Utilities/zipball/master -O tools.zip
	if [ -f tools.zip ]; then
		unzip tools.zip
		mv hortonworks-HDP*/Installation/*.sh .
		chmod u+x *.sh
	fi
else
	echo "Could not find or create the /root/hdp directory"
fi