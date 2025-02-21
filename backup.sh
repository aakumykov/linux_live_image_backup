#!/bin/bash
set -e

if [ 2 -ne $# ]; then
	cat <<- EOF > /dev/stderr
	Usage: $0 <hdd> <archive file>
	Example: $0 /dev/sda /mnt/config.zip
	EOF
	exit 1
fi

show_as_error(){
	echo $*
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

sfdisk_with_write_command(){
cat << EOF
`sfdisk -d $1`
write
EOF
}


if ! which zip > /dev/null; then
	show_as_error Where is no \'zip\' executable!
	exit 1
fi


if ! which bsdtar > /dev/null; then
	show_as_error Where is no \'bsdtar\' executable!
	exit 1
fi


DISK=$1
shift
show_as_error DISK: $DISK


ARCHIVE=$1
shift
show_as_error ARCHIVE: $ARCHIVE


SWAP_EXISTS=false
if swap_exists; then SWAP_EXISTS=true; fi
show_as_error SWAP_EXISTS: $SWAP_EXISTS


TEMP_DIR=`mktemp -d`
show_as_error TEMP_DIR: $TEMP_DIR


BOOT_PIPE=$TEMP_DIR/boot_rec
mkfifo $BOOT_PIPE
show_as_error BOOT_PIPE: $BOOT_PIPE


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

dd if=$DISK bs=440 count=1 of=$BOOT_PIPE &
BOOT_PID=$!
show_as_error BOOT_PID: $BOOT_PID


cd $TEMP_DIR
if [ "`pwd`" != "$TEMP_DIR" ]; then
	show_as_error "Cannot change dir to '$TEMP_DIR'"
else
	show_as_error Working dir: `pwd`
fi


zip -FI -r - . > $ARCHIVE

show_as_error `ls -lh $ARCHIVE`


kill $BOOT_PID
if [ $SWAP_EXISTS = true ]; then kill $SWAP_PID; fi
kill $SFDISK_PID


cd -

show_as_error `rm -rfv $TEMP_DIR`



