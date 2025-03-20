#!/bin/bash

if [ $# -lt 1 ]; then
	cat <<- EOF > /dev/stderr
	Usage: cat <archive> | $0 <target device>
	Example: cat /path/to/archive_with_partitions_data.zip | $0 /dev/sdb
	Will extract partitions from archive to corresponding partitions on /dev/sdb (partitions must already exists).
	EOF
	exit 1
fi

show_as_error_and_exit(){
	echo $*
	exit 1
}

TARGET_DISK=$1
shift
echo TARGET DISK: $TARGET_DISK

[ -b $TARGET_DISK ] || show_as_error_and_exit "File '$TARGET_DISK' is not a block device!"


TARGET_DISK_NAME=`echo $TARGET_DISK | grep -Eo '[^/]+$'`
echo TARGET_DISK_NAME: $TARGET_DISK_NAME


WORK_DIR='/tmp/linux_image_restore'
[ ! -d $WORK_DIR ] && show_as_error_and_exit "Directory '$WORK_DIR' not found. Are you run partitions structure restoring script first?"


source_partitions(){
	local PART_LIST_FILE=$WORK_DIR/part_list.txt
	if [ -f $PART_LIST_FILE ]; then
		cat $PART_LIST_FILE
	else
		show_as_error_and_exit "There is no '$PART_LIST_FILE', cannot get list of partitions!"
	fi
}

source_disk_name(){
	source_partitions | head -1 | grep -Eo '[^/]+$' | grep -Eo '[^0-9]+'
}

part_nums(){
	source_partitions | grep -Eo [0-9]+
}

echo Source partitions:
source_partitions

echo Part nums:
part_nums

echo Source disk name:
source_disk_name


COMMON_PIPE=$WORK_DIR/archive


prepare_pipes(){
	for n in `part_nums`; do
		local PIPE_NAME=$WORK_DIR/${TARGET_DISK_NAME}${n}
		[ ! -e $PIPE_NAME ] && mkfifo $PIPE_NAME
		ls -l $PIPE_NAME
	done
}

prepare_pipes


