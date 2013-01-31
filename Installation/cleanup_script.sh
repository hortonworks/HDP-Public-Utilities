export REPO_FILTER='Cloudera'
export PATHS=( /etc /var/log /var/run /usr/lib /var/lib /var/tmp /tmp/ /var )
export PACKAGES=(`yum list | egrep -E "$REPO_FILTER" | awk '{ print $1; }' | grep -v '^[0-9]'`)
export PROJECT_NAMES=( hadoop* hbase hcatalog hive ganglia nagios oozie sqoop hue zookeeper mapred hdfs flume)
export PROJECT_REGEX=`echo ${PROJECT_NAMES[@]} | sed 's/ /|/g'`
echo $PROJECT_REGEX

# Erase packages
yum -y erase ${PACKAGES[@]};

# Erase alternatives
cd /etc/alternatives
for name in `ls | egrep "$PROJECT_REGEX"`; do
	for path in `alternatives --display $name | grep priority | awk '{print $1}'`; do
		alternatives --remove $name $path
	done
done

for project in ${PROJECT_NAMES[@]}; do
	# Erase fs entries
	for base_path in ${PATHS[@]} ; do
		if [ -d $base_path/$project ] ; then
			rm -rf $base_path/$project
		fi
	done
	
	# Remove users
	cat /etc/passwd | grep $project > /dev/null
	if [ $? -eq 0 ]; then
		userdel -r $project
	fi
done

# Removing repo's
cd /etc/yum.repos.d && egrep $REPO_FILTER *.repo | awk -F: '{ print $1; }' | sort -u | xargs -n 1 rm