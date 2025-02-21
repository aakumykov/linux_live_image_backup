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

kill_if_runs(){ 
	ps -p $1 > /dev/null && kill $1 
}


TARGET_DRIVE=$1
show_as_error TARGET_DRIVE: $TARGET_DRIVE

cat disks/sfdisk_dump | bsdtar -xf- -O sfdisk_dump | (sfdisk $TARGET_DRIVE) &
SFDISK_PID=$!

#cat disks/swap_info | bsdtar -xf- -O swap_info | (sleep 40 && IFS=: read INDEX UUID; sleep 3 && mkswap -U $UUID ${TARGET_DRIVE}${INDEX}) &
#SWAP_PID=$!

#cat disks/boot_rec | bsdtar -xf- -O boot_rec | (sleep 40 && dd of=$TARGET_DRIVE bs=440 count=1) &
#BOOT_PID=$!

#cat archive | tee disks/sfdisk_dump | buffer | tee disks/swap_info | tee disks/boot_rec > /dev/null &
#cat archive | tee disks/sfdisk_dump | buffer | tee disks/swap_info | tee disks/boot_rec > /dev/null &
cat archive | tee disks/sfdisk_dump | buffer > /dev/null &
TEE_PID=$!

cat /dev/stdin > archive 

# sleep 3
#kill_if_runs $TEE_PID
#kill_if_runs $SFDISK_PID
#kil_if_runs $SWAP_PID
#kill_if_runs $BOOT_PID

