#!/bin/bash

DATE=$(date +%Y%m%dT%H%M%S)

# Attempting to call the regular backup script as our first attempt
/usr/local/bin/etcd-snapshot-backup.sh /assets/backup/etcd-snapshot.db

if [ $? -eq 0 ]; then
    echo "Successfully downloaded etcdctl and backed up etcd database !!!"
else
    echo "Failed to backup etcd. Most likely a disconnected environment !!!"
    echo "Calling the disconnected etcd backup script"
    /usr/local/bin/etcd-snapshot-backup-disconnected.sh /assets/backup/etcd-snapshot.db
fi
if [ $? -eq 0 ]; then
    mkdir /etcd-backup/${DATE}
    cp -r /assets/backup/*  /etcd-backup/${DATE}/
    echo 'Copied backup files to PVC mount point.'
    exit 0
fi
echo "Backup attempts failed. Please FIX !!!"
exit 1
