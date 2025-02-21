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

restore_swap(){
	IFS=: read INDEX UUID && mkswap -U $UUID ${TARGET_DRIVE}${INDEX} > output/swap_info | buffer 
}

TARGET_DRIVE=$1
show_as_error TARGET_DRIVE: $TARGET_DRIVE

cat disks/sfdisk_dump | buffer | bsdtar -xf- -O sfdisk_dump | (sfdisk $TARGET_DRIVE) &
SFDISK_PID=$!

# TODO: использовать отдельную команду с проверкой на наличие раздела
cat disks/swap_info | bsdtar -xf- -O swap_info | (sleep 2 && restore_swap) &
SWAP_PID=$!

cat disks/boot_rec | bsdtar -xf- -O boot_rec | (dd of=$TARGET_DRIVE bs=440 count=1) &
BOOT_PID=$!

cat archive | tee disks/sfdisk_dump | tee disks/swap_info | tee disks/boot_rec > /dev/null &
#cat archive | tee disks/sfdisk_dump | tee disks/boot_rec > /dev/null &
#cat archive | tee disks/sfdisk_dump > /dev/null &
TEE_PID=$!

cat /dev/stdin > archive 

# sleep 3
#kill_if_runs $TEE_PID
#kill_if_runs $SFDISK_PID
#kil_if_runs $SWAP_PID
#kill_if_runs $BOOT_PID

sleep 3
cat output/swap_info

