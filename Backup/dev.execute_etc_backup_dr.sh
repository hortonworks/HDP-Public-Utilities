#!/bin/bash
# Utility to run a copy of the snapshots of the /etc directory from a source cluster and drop it to target cluster

now=$(date +'%Y-%m-%d')

echo "......Executing remote copy of backup data from source cluster to target cluster at " + $(date)

hadoop distcp -update -prbugp -m 32 \
        hdfs://qa_namenode_host/datalake/archive/master_data/.snapshot/$now \
        hdfs://dev_namenode_host/backup/

echo "......Completed copying source cluster data for back to target cluster"
