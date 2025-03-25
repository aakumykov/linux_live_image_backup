#!/bin/bash
set -e

if [ 1 -ne $# ]; then
	cat <<- EOF >> /dev/stderr
	Usage: cat <config.zip> | $0 <disk drive restoring to>
	EOF
	exit 1
fi

show_as_error(){ 
	echo $* > /dev/stderr 
}

show_as_error_and_exit(){
	show_as_error ""
	show_as_error "=================================="
	show_as_error "$*"
	show_as_error "=================================="
	exit 1
}

command_exists(){
	which $1 > /dev/null 2>&1
}

check_required_commands(){
	for i in buffer sfdisk bsdtar tee; do
		command_exists $i || show_as_error_and_exit "Command '$i' not found, cannot work!"
	done
}

check_required_commands


kill_if_runs(){ 
	ps -p $1 > /dev/null && kill $1 
}


SWAP_LOG=swap.log

restore_swap(){
	IFS=: read INDEX UUID && mkswap -U $UUID ${TARGET_DRIVE}${INDEX} > $SWAP_LOG | buffer 
}

TEMP_DIR='/tmp/linux_image_restore'
if [ -d $TEMP_DIR ]; then
	show_as_error Dir $TEMP_DIR already exists, removing its content...
	rm $TEMP_DIR/* -rf
else
	mkdir $TEMP_DIR
fi
show_as_error "TEMP_DIR: $TEMP_DIR"

cd $TEMP_DIR
show_as_error "WORKING DIR: `pwd`"

LIST_NAME='part_list'
SFDISK_NAME='sfdisk_dump'
SWAP_NAME='swap_info'
BOOT_NAME='boot_rec'
COMMON_NAME='archive'

LIST_FILE=$TEMP_DIR/${LIST_NAME}.txt

LIST_PIPE="$TEMP_DIR/$LIST_NAME"
SFDISK_PIPE="$TEMP_DIR/$SFDISK_NAME"
SWAP_PIPE="$TEMP_DIR/$SWAP_NAME"
BOOT_PIPE="$TEMP_DIR/$BOOT_NAME"
COMMON_PIPE="$TEMP_DIR/$COMMON_NAME"

prepare_pipes(){
	mkfifo $COMMON_PIPE
	mkfifo $BOOT_PIPE
	mkfifo $SWAP_PIPE
	mkfifo $SFDISK_PIPE
	mkfifo $LIST_PIPE
}

prepare_pipes

TARGET_DRIVE=$1
show_as_error TARGET_DRIVE: $TARGET_DRIVE


cat $SFDISK_PIPE | buffer | bsdtar -xf- -O $SFDISK_NAME | (sfdisk $TARGET_DRIVE) &
SFDISK_PID=$!

# TODO: использовать отдельную команду с проверкой на наличие раздела
cat $SWAP_PIPE | bsdtar -xf- -O $SWAP_NAME | (sleep 2 && restore_swap) &
SWAP_PID=$!

cat $BOOT_PIPE | bsdtar -xf- -O $BOOT_NAME | (dd of=$TARGET_DRIVE bs=440 count=1) &
BOOT_PID=$!

cat $LIST_PIPE | bsdtar -xf- -O $LIST_NAME > $LIST_FILE &

cat $COMMON_PIPE | tee $SFDISK_PIPE | tee $SWAP_PIPE | tee $BOOT_PIPE | tee $LIST_PIPE > /dev/null &
#cat archive | tee disks/sfdisk_dump | tee disks/boot_rec > /dev/null &
#cat archive | tee disks/sfdisk_dump > /dev/null &
TEE_PID=$!

cat /dev/stdin > $COMMON_PIPE

# sleep 3
#kill_if_runs $TEE_PID
#kill_if_runs $SFDISK_PID
#kil_if_runs $SWAP_PID
#kill_if_runs $BOOT_PID

sleep 3

show_as_error ================ SWAP_LOG =================
cat $SWAP_LOG

show_as_error ================ PART_LIST =================
cat $LIST_FILE

