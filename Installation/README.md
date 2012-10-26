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
# Downloading from client machine

* wget --no-check-certificate https://github.com/hortonworks/HDP-Public-Utilities/zipball/master -O tools.zip
* unzip tools.zip
* mv hortonworks-HDP\*/Installation/\*.sh .
* chmod u+x *.sh

# SE Tool Command examples

## Run Command

Look at hostname resolution on all nodes

`./run_command.sh 'hostname -f'`

## Copy file

`./copy_file.sh /etc/selinux/config /etc/selinux`

## Distribute SSH Keys

`./distribute_ssh_keys.sh /root/.ssh/id_dsa.pub`

## Kick Nodes

`./kick_nodes.sh`