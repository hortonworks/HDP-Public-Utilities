#!/bin/bash
FILENAME="ambari_logs_`hostname`"
ARTIFACT_BASEPATH="/tmp"

function gather_server_logs {
    zip -r $ARTIFACT_BASEPATH/$FILENAME.zip /var/log/ambari-server /var/run/ambari-server/bootstrap > /dev/null
}
function gather_agent_logs {
	zip -r $ARTIFACT_BASEPATH/$FILENAME.zip /var/log/ambari-agent /var/lib/ambari-agent/data > /dev/null
}

function capture_metadata {
    rpm -qa | grep ambari > $ARTIFACT_BASEPATH/$FILENAME.txt
}

function print_instructions {
    echo -e "[-] SFTP the following files from `hostname`:\n\t$ARTIFACT_BASEPATH/$FILENAME.zip\n\t$ARTIFACT_BASEPATH/$FILENAME.txt"
}

echo "[*] Gathering Ambari Logs"
if [ -d /var/log/ambari-server ]; then
        gather_server_logs
fi
if [ -d /var/log/ambari-agent ]; then
        gather_agent_logs
fi
capture_metadata
print_instructions