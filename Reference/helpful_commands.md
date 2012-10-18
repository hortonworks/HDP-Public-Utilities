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
# References

## Master Services

### Name Node

* Start Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start namenode` as hdfs
* Stop Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR stop namenode` as hdfs
* Port: http://<host>:50070

### Secondary Name Node

* Start Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start secondarynamenode` as hdfs
* Stop Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR stop secondarynamenode` as hdfs
* Port: http://<host>:50070
	
### Data Node

* Start Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start datanode` as hdfs
* Stop Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR stop datanode` as hdfs
	
### Job Tracker

* Start Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start jobtracker` as mapred
* Stop Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR stop jobtracker` as mapred
* Port: http://<host>:50030
	
### Job History Server

* Start Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start historyserver` as mapred
* Stop Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR stop historyserver` as mapred
* Port: http://<host>:50090

### Task Tracker

* Start Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start tasktracker` as mapred
* Stop Script: `/usr/lib/hadoop/bin/hadoop-daemon.sh --config $HADOOP_CONF_DIR stop tasktracker` as mapred

	
# Useful Commands

## Terasort

* Gen: `/usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/hadoop-examples.jar teragen 100000000 /test/10gsort/input` as hdfs
* Smaller Gen: `/usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/hadoop-examples.jar teragen 1000000 /test/10gsort/input` as hdfs
* Sort: `/usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/hadoop-examples.jar terasort /test/10gsort/input /test/10gsort/output` as hdfs

## Format Name Node

* Format: `/usr/lib/hadoop/bin/hadoop namenode -format` as hdfs

## Lave Safemode
hadoop dfsadmin -safemode leave
hadoop fsck /
hadoop dfsadmin -safemode leave