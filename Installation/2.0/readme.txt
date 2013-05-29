README for
https://hortonworks.box.com/files/0/f/908341882/Install_HDP_2.0.0.2_alpha

* Installs HDP 2.0.0.2 Alpha [HDFS, YARN, TEZ, HIVE, PIG]
* Supports multiple nodes
* Creates a local repository
* Deploys password-less SSH

To use the script:
1. edit the names of the hosts in your cluster
2. run the script, and press ENTER when prompted

If something fails, you can mostly ctrl-c, fix the pb and re-run the script.
If the local repository fails in the middle, use -f to force the script to validate it. 

TODO
* HUE
* HBASE
* HIVE 0.11 from tarball