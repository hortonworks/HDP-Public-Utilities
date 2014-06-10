#!/bin/bash
# Enable target HDFS paths used for backup/DR to be snapshot. Add all paths that are going to be used for backup purposes.

hdfs dfsadmin -allowSnapshot  /backup
hdfs dfsadmin -allowSnapshot  /sql_dbs_backup
hdfs dfsadmin -allowSnapshot  /etc_backup