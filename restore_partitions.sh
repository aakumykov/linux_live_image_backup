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

SOURCE_DISK_NAME=`source_disk_name`
echo SOURCE_DISK_NAME: $SOURCE_DISK_NAME

part_nums(){
	source_partitions | grep -Eo [0-9]+
}

echo Source partitions:
source_partitions

echo Part nums:
part_nums



COMMON_PIPE=$WORK_DIR/archive


prepare_pipes(){
	for n in `part_nums`; do
		local PIPE_NAME=$WORK_DIR/${SOURCE_DISK_NAME}${n}
		[ ! -e $PIPE_NAME ] && mkfifo $PIPE_NAME
		ls -l $PIPE_NAME
	done
}

prepare_pipes


#
# Проверка целевого диска
#
check_target_parts(){
	for n in `part_nums`; do
		local TARGET_PART=/dev/${TARGET_DISK_NAME}$n
		[ ! -b $TARGET_PART ] && show_as_error_and_exit "There is no target partition '$TARGET_PART' or it is not block device!"
	done
}

check_target_parts


#
# Собственно восстановление:
#
prepare_passing_data_from_common_to_specific_pipes(){
	local TEE_CMD="cat $COMMON_PIPE "
	for n in `part_nums`; do
		local PIPE_NAME=$WORK_DIR/${SOURCE_DISK_NAME}$n
		TEE_CMD+=" | tee $PIPE_NAME"
	done
	TEE_CMD+=" > /dev/null"
	
	echo $TEE_CMD
	eval $TEE_CMD &
}

prepare_passing_data_from_common_to_specific_pipes


prepare_passing_data_from_specific_pipes_to_target_parts(){
	for n in `part_nums`; do
		local SOURCE_PART_NAME="${SOURCE_DISK_NAME}${n}"
		local TARGET_PART_NAME=${TARGET_DISK_NAME}${n}
		local TARGET_PARTITION=/dev/$TARGET_PART_NAME
		local PIPE_NAME=$WORK_DIR/${SOURCE_PART_NAME}

		local CMD="dd if=$PIPE_NAME bs=1M | bsdtar -xf- -O $SOURCE_PART_NAME > $TARGET_PARTITION"

		echo $CMD
		eval $CMD &
	done
}

prepare_passing_data_from_specific_pipes_to_target_parts

echo "Passing archive data to ${COMMON_PIPE} ..."
START_CMD="cat /dev/stdin > $COMMON_PIPE"
echo $START_CMD
eval $START_CMD

