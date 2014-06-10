#!/bin/bash
# Only /etc and Hive, Oozie, HUE, Ambari database backups entries are going to be saved on this directories respectively

hdoop fs -mkdir /etc_backup
hadoop fs -mkdir /sql_dbs_backup