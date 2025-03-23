#!/bin/bash
set -e

if [ 1 -ne $# ]; then
	cat <<- EOF > /dev/stderr
	Usage: $0 <hdd> > /path/to/archive.zip
	Example: $0 /dev/sda > /mnt/config.zip
	EOF
	exit 1
fi

show_as_error(){
	echo $* > /dev/stderr
}

all_blkids_of_working_disk(){
        eval "blkid $DISK*"
}

swap_exists(){
        all_blkids_of_working_disk | grep swap > /dev/null
}

swap_uuid(){
         all_blkids_of_working_disk | grep swap | grep -Eo ' UUID="[^"]+"' | cut -d= -f2 | grep -Eo '[^"]+'
}

swap_index(){
	all_blkids_of_working_disk | grep swap | grep -Eo /dev/sda[0-9]+ | grep -Eo '[0-9]+$'
}

swap_info(){
	echo `swap_index`:`swap_uuid`
}

part_names(){
	all_blkids_of_working_disk | \grep -E ' UUID=' | \grep -vi swap | cut -d: -f1 | \grep -Eo '[^/]+$'
}

fail_on_no_program(){
	show_as_error "============================="
	show_as_error "$*"
	show_as_error "============================="
	exit 1
}


sfdisk_with_write_command(){
cat << EOF
`sfdisk -d $1`
write
EOF
}


if ! which zip > /dev/null; then
	fail_on_no_program "Where is no 'zip' executable!"
	exit 1
fi


if ! which bsdtar > /dev/null; then
	fail_on_no_program "Where is no 'bsdtar' executable!"
	exit 1
fi


DISK=$1
shift
show_as_error DISK: $DISK



SWAP_EXISTS=false
if swap_exists; then SWAP_EXISTS=true; fi
show_as_error SWAP_EXISTS: $SWAP_EXISTS


TEMP_DIR=`mktemp -d`
show_as_error TEMP_DIR: $TEMP_DIR


BOOT_PIPE=$TEMP_DIR/boot_rec
mkfifo $BOOT_PIPE
show_as_error BOOT_PIPE: $BOOT_PIPE


LIST_PIPE=$TEMP_DIR/part_list
mkfifo $LIST_PIPE
show_as_error LIST_PIPE: $LIST_PIPE


if [ $SWAP_EXISTS = true ]
then
	SWAP_PIPE=$TEMP_DIR/swap_info
	mkfifo $SWAP_PIPE
	show_as_error SWAP_PIPE: $SWAP_PIPE
else
	show_as_error SWAP does not exists on $DISK
fi


SFDISK_PIPE=$TEMP_DIR/sfdisk_dump
mkfifo $SFDISK_PIPE
show_as_error SFDISK_PIPE: $SFDISK_PIPE


part_names > $LIST_PIPE &
LIST_PID=$!
show_as_error LIST_PID: $LIST_PID


sfdisk_with_write_command $DISK > $SFDISK_PIPE &
SFDISK_PID=$!
show_as_error SFDISK_PID: $SFDISK_PID


SWAP_PID=-1
if [ $SWAP_EXISTS = true ]
then
	swap_info > $SWAP_PIPE &
	SWAP_PID=$!
	show_as_error SWAP_PID: $SWAP_PID
fi


dd if=$DISK bs=440 count=1 of=$BOOT_PIPE 2>/dev/null &
BOOT_PID=$!
show_as_error BOOT_PID: $BOOT_PID


cd $TEMP_DIR
if [ "`pwd`" != "$TEMP_DIR" ]; then
	show_as_error "Cannot change dir to '$TEMP_DIR'"
else
	show_as_error Working dir: `pwd`
fi


zip -q -FI -r - . > /dev/stdout

kill_if_runs(){
	ps -p $1 > /dev/null && kill $1
}

kill_if_runs $BOOT_PID
if [ $SWAP_EXISTS = true ]; then kill_if_runs $SWAP_PID; fi
kill_if_runs $SFDISK_PID


cd -

show_as_error `rm -rfv $TEMP_DIR`



