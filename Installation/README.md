<!--
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
# Tool Installation

## Options

### Installing using a script

Simply copy the contents of the install_tools.sh script and create a file on the server you wish to run it from, then execute the script.

### Downloading from client machine manually

* wget --no-check-certificate https://github.com/hortonworks/HDP-Public-Utilities/zipball/master -O tools.zip
* unzip tools.zip
* mv hortonworks-HDP\*/Installation/\*.sh .
* chmod u+x *.sh

## Setup
In order for the tools to know which nodes are to be used, a `Hostdetail.txt` files must be created that contains the fully qualified domain name of each server in the cluster.  This can be done by using the example below:

`vi /root/hdp/Hostdetail.txt`

	host1.hortonworks.local
	host2.hortonworks.local
	host3.hortonworks.local 

# Command Examples

## Pre Installation Check (HDP 1.2)

The pre-installation check will check for a number of missing or conflicting files, packages, and system settings.  It will also assist with troubleshooting installation issues if they arise.

`./pre_install_check_1.2.sh | tee report.txt`

This will run the pre installation check and output the progress to standard output and to the report.txt file.

## Run Command

Look at hostname resolution on all nodes

`./run_command.sh 'hostname -f'`

## Copy file

`./copy_file.sh /etc/selinux/config /etc/selinux`

## Distribute SSH Keys

`./distribute_ssh_keys.sh /root/.ssh/id_dsa.pub`

## Kick Nodes

`./kick_nodes.sh`

# Cleanup Scripts

Before running these scripts it's important to do the following:

* Backup configuration directories in /etc such as /etc/hadoop/conf
* Backup mysql/postgres databases if necessary as they will be uninstalled, and in the case of MySQL have the data directory wiped
