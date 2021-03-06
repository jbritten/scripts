#!/bin/bash
# Author: Andrew Howard
# A race-condition-safe bash script wrapper that will ensure this script
# runs non-concurrently with other instances of itself.

logger "Beginning run of script: $0"

LOCK_FILE=/tmp/`basename $0`.lock
function cleanup {
 logger "Exiting script: $0"
 echo "Caught exit signal - deleting trap file"
 rm -f $LOCK_FILE
 exit 2
}
trap 'cleanup' 1 2 9 15 17 19 23 EXIT
(set -C; : > $LOCK_FILE) 2> /dev/null
if [ $? != "0" ]; then
 echo "Lock File exists - exiting"
 logger "Lock File exists - exiting script: $0"
 exit 1
fi

BACKUPDIR=/home/rack/perms-backup
RETENTIONDAYS=7

if [ ! -d $BACKUPDIR ]; then
  mkdir -p $BACKUPDIR
fi

find / -wholename '/proc' -prune -o -fprintf $BACKUPDIR/perms-backup.`date +%Y%m%d`.txt "chmod %m '%p'\nchown %u:%g '%p'\n"
getfacl --no-effective --recursive --skip-base --absolute-names / > $BACKUPDIR/facl-backup.`date +%Y%m%d`.txt

tmpwatch -m ${RETENTIONDAYS}d $BACKUPDIR

