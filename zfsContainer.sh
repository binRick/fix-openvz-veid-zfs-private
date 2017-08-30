#!/bin/sh
VEID=$1
if [ -z "$VEID" ]; then exit -1; fi
NEWPRIVATE="/tank/$VEID/private/$VEID"
PRIVATE=$(vzlist $VEID -1o private)

vzlist $1 >/dev/null || exit -1
vzlist $1 -1o private | grep "$/tank/$VEID/private/$VEID^" >/dev/null && exit 0

zfs list tank/$VEID >/dev/null 2>&1 || zfs create tank/$VEID
zfs get mounted tank/$VEID -pHovalue | grep '^yes$' >/dev/null || zfs mount tank/$VEID && \
	zfs get mounted tank/$VEID -pHovalue | grep '^yes$' >/dev/null || exit -1

if [ "${#PRIVATE} " -lt 3 ]; then exit -1; fi
ls $PRIVATE/etc/passwd >/dev/null 2>&1 || exit -1
CMD="rsync --numeric-ids --delete -ar $PRIVATE /tank/$VEID/private/"
echo "Running Rsync:"
echo "    $CMD"
`$CMD`
echo "Rsync completed"


echo "Stopping Container" && vzctl stop $VEID && echo "Disabling Container" && \
	vzctl set $VEID --disabled yes --save && echo "Rsyncing private again" && `$CMD` \
	echo "Reconfiguring private and root" && \
	vzctl set $VEID --private $NEWPRIVATE --root /tank/$VEID/root --save && \
	echo "Enabling Container" && vzctl set $VEID --disabled no --save && \
	echo "Starting Container" && vzctl start $VEID

