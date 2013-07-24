#!/bin/bash
# Install R on HDP
# Author: Paul Codding <paul@hortonworks.com>
# IMPORTANT: Please make sure you update the path to the .tar.gz files 
# referenced below to the actual path on your cluster!
# 
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
export RMR_PATH=/root/hdp/r/rmr2_2.0.2.tar.gz
export RHDFS_PATH=/root/hdp/r/rhdfs_1.0.5.tar.gz
export RCPP_PATH=/root/hdp/r/Rcpp_0.9.15.tar.gz

if [ -f $RMR_PATH ] && [ -f $RHDFS_PATH ] && [ -f /usr/lib/hadoop/bin/hadoop-config.sh ] && [ ! -f /usr/bin/R ]; then 
	echo "Installing R"
else
	echo "Please install HDP and download rmr, rhdfs, rhbase and make sure R is not already installed.  If you've already downloaded those projects and R is not installed check the *_PATH variables in this script"
	exit 1
fi

# Setup the required R environmental variables for interacting with Hadoop
cat > /etc/profile.d/r.sh <<END
. /usr/lib/hadoop/bin/hadoop-config.sh --config /etc/hadoop/conf
export HADOOP_CMD=/usr/bin/hadoop
export HADOOP_STREAMING=/usr/lib/hadoop/contrib/streaming/hadoop-streaming-1.0.3.15.jar
END

# Source the profile
. /etc/profile.d/r.sh

# Install R from epel
yum -y install R
yum -y install curl-devel

# Validate R
R --version | grep "2.15"

# Install projects and their dependencies
if [ $? -eq 0 ]; then
	echo 'options(repos=structure(c(CRAN="http://cran.stat.ucla.edu")))' >> /root/.Rprofile
	Rscript -e 'install.packages("RJSONIO");'
	if [ $? -eq 0 ]; then
		Rscript -e 'install.packages("itertools");'
		if [ $? -eq 0 ]; then
			Rscript -e 'install.packages("digest");'
			if [ $? -eq 0 ]; then
				R CMD INSTALL Rcpp $RCPP_PATH
				Rscript -e 'install.packages("functional")'
				Rscript -e 'install.packages("RCurl")'
				Rscript -e 'install.packages("httr")'
				Rscript -e 'install.packages("plyr")'
				if [ $? -eq 0 ]; then
					R CMD INSTALL rmr2 $RMR_PATH
					R CMD javareconf
					Rscript -e 'install.packages("rJava");'
					if [ $? -eq 0 ]; then
						R CMD INSTALL rhdfs $RHDFS_PATH
					fi
					#R CMD INSTALL rhbase $RHBASE_PATH
				fi
			fi
		fi
	fi
fi