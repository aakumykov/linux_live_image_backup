#!/bin/bash

if [ $# -lt 1 ]; then
	cat <<- EOF > /dev/stderr
	Usage: cat <archive> | $0 <target device>
	Example: cat /path/to/archive_with_partitions_data.zip | $0 /dev/sdb
	Will extract partitions from archive to corresponding partitions on /dev/sdb (partitions must already exists).
	EOF
	exit 1
fi

show_as_error(){
	echo "$*" > /dev/stderr
}

show_as_error_and_exit(){
	show_as_error $*
	exit 1
}

TARGET_DISK=$1
shift
echo TARGET DISK: $TARGET_DISK

WORK_DIR=`mktemp -d`
echo WORK_DIR: $WORK_DIR


