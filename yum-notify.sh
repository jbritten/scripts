#!/bin/bash

# Author: Andrew Howard

LOCK_FILE=/tmp/`basename $0`.lock
function cleanup {
 echo "Caught exit signal - deleting trap file"
 rm -f $LOCK_FILE
 exit 2
}
trap 'cleanup' 1 2 9 15 17 19 23 EXIT
(set -C; : > $LOCK_FILE) 2> /dev/null
if [ $? != "0" ]; then
 echo "Lock File exists - exiting"
 exit 1
fi


# "yum check-update" returns an exit code of 100 if there are updates available. Handy for shell scripting.
yum check-update &>/dev/null; RETVAL=$?

# If no updates available, just log and exit
if [ $RETVAL -eq 0 ]; then
  logger "`pwd`/`basename $0`: Checked for updates - none available."
  # Remove lock file
  trap 'rm $LOCK_FILE' EXIT
  exit 0
else
  logger "`pwd`/`basename $0`: Checked for updates - found some.  Notifying."
fi

# If updates available, notify.
TO="devnull@rootmypc.net"
CC="devnull@rootmypc.net"
FROM="root@`hostname`"
SUBJECT="RPM updates available"
OUTPUT=`yum check-update`

sendmail -t -f$FROM <<EOF
To: $TO
Reply-to: $FROM
Cc: $CC
From: $FROM
Subject: $SUBJECT
This email generated by `pwd`/`basename $0` on `hostname`.

Results of "yum check-update" on server `hostname`:
"$OUTPUT"
.
EOF


