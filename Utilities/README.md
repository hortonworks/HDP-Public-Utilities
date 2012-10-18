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
# General Utilities

Contains general utilities for working with HDP or EC2.

## EC2 Utilities

Because I don't want to type `ssh -i /path/to/keypair.pem hostname` every time I need to access an EC2 instance, I've created these scripts to simplify the process:

* ec2 - This utility is used to SSH into an ec2 instance by just specifying the hostname e.g. `ec2 hostname`
* ec2cp - This utility is used to SCP files to/from an ec2 instance e.g. `ec2cp /tmp/file hostname@/tmp`
* ec2sftp - This utility is used to SFTP files to/from an ec2 instance e.g. `ec2sftp hostname`

### Setup

Download the scripts including the `config.sh`.  Edit the `config.sh` with the path to your EC2 keypair, then but the scripts in your `PATH`.  I place my scripts in `~/scripts`.