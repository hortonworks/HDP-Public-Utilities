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
read -p "This is going to remove software, users, and directories...are you sure you want to proceed [y|n]" SURE
if [ $SURE == "y" ]; then
	./run_command.sh 'killall java'
	# Cleanup stock package
	./run_command.sh 'yum -y erase ruby ruby-irb ruby-libs ruby-shadow ruby-rdoc ruby-augeas rubygems libselinux-ruby ruby-devel libganglia libconfuse hdp_mon_ganglia_addons ganglia-gmond postgresql-server postgresql postgresql-libs ganglia-gmond-python ganglia ganglia-gmetad ganglia-web ganglia-devel httpd mysql mysql-server mysqld'
	
	./copy_file.sh cleanup_script.sh /tmp
	./run_command.sh "bash /tmp/cleanup_script.sh"
fi