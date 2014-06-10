#!/bin/bash
# Allow paths provided for snapshots.

hdfs dfsadmin -allowSnapshot  /datalake/raw/clickstream
hdfs dfsadmin -allowSnapshot  /datalake/calculated/sales
hdfs dfsadmin -allowSnapshot  /sql_dbs_backup
hdfs dfsadmin -allowSnapshot  /etc_backup
