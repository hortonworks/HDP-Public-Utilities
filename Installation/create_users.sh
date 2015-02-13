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
if [ ! -f users.txt ]; then
	echo "Please create a file named users.txt containing user names to be created"
else
	for user in `cat users.txt`; do
		./run_command.sh "useradd -g 100 $user"
		/usr/lib/hadoop/sbin/hadoop-create-user.sh $user
		su hdfs -c "hadoop fs -mkdir /user/$user"
		su hdfs -c "hadoop fs -chown $user /user/$user"
	done
fi
