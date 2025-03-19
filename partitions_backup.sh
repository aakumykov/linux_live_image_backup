#!/bin/bash

set -e

if [ $# -lt 1 ]; then
	cat <<- EOF > /dev/stderr
	Usage: $0 <disk to backup> > /path/to/archive.zip
	Example: $0 /dev/sda > /mnt/backup.zip
	EOF
	exit 1
fi

DISK=$1
shift


show_as_error(){
	echo "$*" > /dev/stderr
}

show_as_error_and_exit(){
	show_as_error "$*"
	exit 1
}

check_disk_is_correct(){
	if [ ! -e $DISK ]; then
		show_as_error_and_exit "File '$DISK' does not exists!"
	fi
	if [ ! -b $DISK ]; then
		show_as_error_and_exit "Disk '$DISK' is not a block device!"
	fi
}

show_as_error DISK: $DISK


get_part_numbers_of(){
	blkid $1* | \grep -vi swap | \grep -E ' UUID="[^"]+"' | cut -d' ' -f1 | cut -d: -f1 | \grep -Eo [0-9]+
}

part_numbers(){
	get_part_numbers_of $DISK
}


TEMP_DIR=`mktemp -d`
show_as_error TEMP_DIR: $TEMP_DIR


PART_NAME=`echo $DISK | grep -Eo '[^/]+$'`
show_as_error PART_NAME: $PART_NAME


prepare_pipes(){
	for n in `part_numbers`; do
		local FIFO=$TEMP_DIR/${PART_NAME}$n
		mkfifo $FIFO
		ls -l $FIFO
	done
}

prepare_pipes

#
# Сделать этот скрипт реагирующим на аргумент
#
./datto_snapshot_helper.sh remove
./datto_snapshot_helper.sh create


