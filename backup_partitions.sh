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


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
show_as_error SCRIPT_DIR: $SCRIPT_DIR

DATTO_HELPER="$SCRIPT_DIR/datto_snapshot_helper.sh"

command_exists(){
	which $1 > /dev/null 2>&1
}

check_required_commands(){
	# Dattobd
	command_exists dbdctl || show_as_error_and_exit "Command 'dbdctl' not found! You must install it firsrt on backuped system (https://github.com/datto/dattobd)."
	# Datto snapshot helper
	[ -e $DATTO_HELPER ] || show_as_error_and_exit "Command '$DATTO_HELPER' not found or not executable!"
	# Zip
	command_exists zip || show_as_error_and_exit "Command 'zip' not found!"
}


check_required_commands



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

part_nums(){
	get_part_numbers_of $DISK
}

part_count(){
	part_numbers | wc -l
}


TEMP_DIR=`mktemp -d`
show_as_error TEMP_DIR: $TEMP_DIR


PART_NAME=`echo $DISK | grep -Eo '[^/]+$'`
show_as_error PART_NAME: $PART_NAME

pipe_name_for_num(){
	[ $# -lt 1 ] && show_as_error_and_exit "pipe_name_for_num(): argument (number) missing"
	echo $TEMP_DIR/${PART_NAME}$1
}

prepare_pipes(){
	show_as_error "PIPES:"
	for n in `part_nums`; do
		local FIFO=`pipe_name_for_num $n`
		mkfifo $FIFO
		show_as_error `ls $FIFO`
	done
}


prepare_pipes

#
# Сделать этот скрипт реагирующим на аргумент
#
show_as_error "Removing old Dattobd devices if exits..."
$DATTO_HELPER remove

show_as_error "Creating Dattobd snapshot devices..."
$DATTO_HELPER create


prepare_dumps(){
	for n in `part_nums`; do
		local PIPE_NAME=`pipe_name_for_num $n`
		dd if=/dev/datto$n bs=1M of=$PIPE_NAME &
	done
}

prepare_dumps

cd $TEMP_DIR
show_as_error "WORKING_DIR: `pwd`"

show_as_error "Zipping partitions data..."
zip -q -FI -r - . > /dev/stdout


show_as_error "Removing /dev/datto* devices..."
$DATTO_HELPER remove
show_as_error "Done"
