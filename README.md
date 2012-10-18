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
HDPSETools
==========

This is a common place for simple tools that the field engineering team @ [Hortonworks](http://hortonworks.com).  These tools are community supported, and meant to be used as simple utilities and informal reference.  The current tools that are in the repo are:

## Installation

 - pre\_install\_check.sh -- Shell script used to gather information about all nodes in the cluster before the cluster is installed.  It will check for: OS/Arch, CPU, RAM, disk free space, iptables status, SELinux status, host file contents, pre-req rpm packages, and potentially conflicting rpm packages.

## Reference

The reference directory is an easy place to put helpful commands for different projects.

## Utilities

These utilities are for those that are lazy about typing.  These are just wrapper scripts that you can use to connect to and copy data in and out of EC2 instances.