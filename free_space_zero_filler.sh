#!/bin/bash

if [ $# -lt 1 ]; then
	cat <<- EOF > /dev/stderr
	Fills free sectors on disk with zero bytes by creating and removing file consisting with zeroes.'
	Usage: $0 <mount point>
	Example: '$0 /' will fill free sectors disk with zero on root partition'
	EOF
	exit 1
fi

show_as_error(){
	echo $* > /dev/stderr
}

show_as_error_and_exit(){
	show_as_error $*
	exit 1
}

DIR=$1
shift

# 500MB is unused free space. Do not process dir if it contains lower then this free space.
DEFAULT_SAFE_FREE_SPACE=$(( 500*1024 ))
SAFE_FREE_SPACE=$DEFAULT_SAFE_FREE_SPACE

free_space_in_dir(){
	df --output=avail $1 | tail -1
}

FREE_SPACE=$(( `free_space_in_dir $DIR` + 0 ))


if [ $FREE_SPACE -lt $SAFE_FREE_SPACE ]; then
	show_as_error_and_exit "Free space in '$DIR' (${FREE_SPACE} bytes) is lower than ${SAFE_FREE_SPACE} bytes. Will not fill with zero."
fi

temp_name(){
	tempfile | grep -Eo '[^/]+$'
}


ZERO_FILE="$DIR/ZERO_`temp_name`"
ZERO_FILE=`echo $ZERO_FILE | sed -E 's/[/]+/\//g'`
#show_as_error ZERO_FILE: $ZERO_FILE

ZERO_SIZE=$(( $FREE_SPACE - $SAFE_FREE_SPACE ))
#show_as_error ZERO_SIZE: $ZERO_SIZE

ZERO_BLOCK_SIZE=2048

ITERATIONS=$(( ZERO_SIZE / $ZERO_BLOCK_SIZE ))
#show_as_error ITERATIONS: $ITERATIONS



show_as_error "Partition mounted to '$DIR' has ${FREE_SPACE} bytes free space. File '$ZERO_FILE' with size ${ZERO_SIZE} bytes will be created on it and then removed."



show_as_error "Filling $DIR with zeroes by creating '$ZERO_FILE' ..."
dd if=/dev/zero bs=${ZERO_BLOCK_SIZE}k count=$ITERATIONS of=$ZERO_FILE 2>/dev/null 1>&2


show_as_error "Flushing changes to disk ..."
sync


show_as_error "Deleting zero file '$ZERO_FILE' ..."
rm -f $ZERO_FILE


show_as_error "=Done filling space with zero="

