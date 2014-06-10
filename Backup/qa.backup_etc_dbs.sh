#!/bin/bash
# Backup all configurations from /etc directory and any sql databases being used by Hive, Oozie, 
# HUE, Ambari. All the /etc files are backed up since it leaves a very small footprint on the filesystem.
# This can be run by root user under its home directory or any user that has root privileges.
# This script will create the backup files in the current directory and later move it to HDFS for snapshotting and backup/DR.

now=$(date +'%Y-%m-%d')

# Step 1. Create TAR file of the /etc directory and its subdirectories

echo "......creating TAR file for /etc and children" + $(date)

tar --create --gzip --preserve-permissions --recursion --absolute-names -f $now.etc.hadoop.conf.tar.gz /etc/hadoop/conf/

echo "......finished creating the TAR file with filename etc.hadoop.conf.tar.gz " + $(date)

# Step 2. Push the TAR file to HDFS

echo "......saving etc.hadoop.conf.tar.gz TAR file to HDFS" + $(date)

hadoop fs -put $now.etc.hadoop.conf.tar.gz /etc_backup

echo "......TAR file saved to HDFS " + $(date)

# Step 3. TAR the HUE desktop.db database image and save it to HDFS. Run this step where HUE database is located.

echo "......creating TAR file for HUE's desktop.db database" + $(date)

tar --create --gzip --preserve-permissions --recursion --absolute-names -f $now.hue.desktop.db.tar.gz /var/lib/hue/desktop.db

echo "......saving hue.desktop.db.tar.gz to HDFS"

hadoop fs -put $now.hue.desktop.db.tar.gz /sql_dbs_backup

echo "......finished saving hue.desktop.db.tar.gz to HDFS " + $(date)

# Step 4. Create the Hive metastore database dumps and save it to HDFS. You need to replace localhost with the hostname on where mysql is installed.

echo "......creating TAR file for Hive's metastore database " + $(date)

mysqldump -h hostname -u hive -phive --add-drop-database --add-drop-table --complete-insert --create-options --debug-check --dump-date --events --extended-insert --flush-privileges --lock-all-tables --log-error=hive_dump.error --databases hive > $now.hive_metastore.sql

echo "......finished creating Hive metastore backup " + $(date)

echo "......saving hive metastore db file to HDFS" + $(date)

hadoop fs -put $now.hive_metastore.sql /sql_dbs_backup

echo "......finished saving hive metastore db file to HDFS" + $(date)

# Step 5. At this step, it is assumed that the root home directory has a file called .pgpass and its owned by root and has a permission of 600. Their should only be one line in that file which has -> hostname:5432:ambari:ambari:bigdata

echo "......performing back up of PostgreSQL database for Ambari " + $(date)

pg_dump --host=hostname  -U ambari  --file=$now.ambari.postgresql.backup
 
echo "......finished backing up Ambari PostgreSQL database " + $(date) 

echo "......saving ambari.postgresql.backup to HDFS " + $(date) 

hadoop fs -put $now.ambari.postgresql.backup /sql_dbs_backup

echo "......finished saving ambari.postgresql.backup to HDFS" + $(date) 

# Step 6. Backup Oozie Derby database and load it up to HDFS for snapshotting and backup/Dr purposes. Run this script where database is located.

echo "......creating TAR file for Oozie derby database" + $(date)

tar --create --gzip --preserve-permissions --recursion --absolute-names -f $now.oozie.derby.tar.gz /hadoop/oozie/data/

echo "......finished creating the TAR file with filename oozie.derby.tar.gz " + $(date)

echo "......saving oozie.derby.tar.gz TAR file to HDFS" + $(date)

hadoop fs -put $now.oozie.derby.tar.gz /sql_dbs_backup

echo "......finished saving oozie.derby.tar.gz to HDFS " + $(date)

# Step 7. Clean up locally created temporarily backup files since they're already in HDFS at this point.

echo "......cleaning up locally created temporary backup files" + $(date)

rm -f $now.*

echo "......finished cleaning up locally created temporary backup files" + $(date)




