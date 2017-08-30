#!/bin/sh
VEID=$1
if [ -z "$VEID" ]; then exit -1; fi
vzlist $1 >/dev/null || exit -1
vzlist $1 -1o private | grep "$/tank/$VEID/private/$VEID^" >/dev/null && exit 0
zfs list tank/$VEID >/dev/null 2>&1 || zfs create tank/$VEID
zfs get mounted tank/$VEID -pHovalue | grep '^yes$' >/dev/null || zfs mount tank/$VEID && \
	zfs get mounted tank/$VEID -pHovalue | grep '^yes$' >/dev/null || exit -1
PRIVATE=$(vzlist $VEID -1o private)
if [ "${#PRIVATE} " -lt 3 ]; then exit -1; fi
ls $PRIVATE/etc/passwd >/dev/null 2>&1 || exit -1
echo "Running Rsync:\n\t$CMD"
CMD="rsync --numeric-ids --delete -ar $PRIVATE/ /tank/$VEID/private/$VEID/"
`$CMD`
echo "Rsync completed"

