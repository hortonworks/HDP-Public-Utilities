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
if [ $# -ne 1 ]; then
	echo "Please pass the command to run as the first argument.  Use single quotes if the command takes multiple arguments itself"
else
	for host in `cat Hostdetail.txt`; do
	  echo -e "${txtbld}\n######################################################"
	  echo -e "# Running command $1 on Host: $host"
	  echo "######################################################${txtrst}"
	  ssh root@$host COMMAND="'$1'" 'bash -s' << 'END'
	        $COMMAND
END
	done
fi