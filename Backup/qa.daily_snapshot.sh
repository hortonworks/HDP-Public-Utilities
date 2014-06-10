#!/bin/bash
# Script for running the snapshot of /datalake/raw/clickstream and /datalake/calculated/sales  directories

now=$(date +'%Y-%m-%d')

echo "......Creating snapshot now starting at "  $(date)

hdfs dfs -createSnapshot /datalake/raw/clickstream $now
hdfs dfs -createSnapshot /datalake/calculated/sales $now
hdfs dfs -createSnapshot /sql_dbs_backup $now
hdfs dfs -createSnapshot /etc_backup $now

echo "......Snapshots completed at " + $(date)