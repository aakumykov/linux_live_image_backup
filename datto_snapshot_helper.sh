#!/bin/bash
set -e

#
# FIXME: Если диск не содержит разделов, а отформатирован напрямую?
#

show_usage_and_exit(){
	cat <<- EOF > /dev/stderr
	Usage: $0 <exists|create|remove|list> <disk>
	Example: $0 create /dev/sda - will create Dattobd snapshots for partitions on /dev/sda (/dev/sda1, /dev/sda2 etc)
	EOF
	exit 1
}

show_as_error(){
	echo $* > /dev/stderr
}


if [ $# -lt 2 ]; then
	show_usage_and_exit
fi


CMD=$1
shift
#show_as_error CMD: $CMD

DISK=$1
shift
#show_as_error DISK: $DISK


field_of(){
	echo "$1" | cut -d$2 -f $3
}

some_snapshots_exists(){
	set +f
	ls -1 /dev/datto* | grep -E 'datto[0-9]+' > /dev/null
	local RES=$?
	set -f
	return $RES
}

show_error_and_exit(){
	show_as_error "$*"
	exit 1
}

list_existing_datto_devices(){
	set +f
	show_as_error "Existing datto-devices:"
	for i in `ls -1 /dev/datto*`; do
		show_as_error $i
	done
	set -f
}



#
# Работа
#
if [ "create" == "$CMD" ]; then
	show_as_error "CMD is 'create', checking if some snapshots exists..."

	if some_snapshots_exists; then
		cat <<- EOF > /dev/stderr
		Some snapshots already exists. Cannot create its again.
		`list_existing_datto_devices`
		EOF
		exit 1
	fi
fi



OLD_IFS=$IFS
IFS=$'\n'
set -f # Disable globbing (!)


for i in `mount | grep $DISK | sort`; do

	PART_FILE=`field_of "$i" ' ' 1`
	PART_NUM=`echo $PART_FILE | grep -Eo '[0-9]+$'`
	MOUNT_POINT=`field_of "$i" ' ' 3`
	FILE_SYSTEM=`field_of "$i" ' ' 5`

	DEVICE="/dev/datto${PART_NUM}"

	case $CMD in
		create)
			show_as_error "Creating '$DEVICE'"
			dbdctl setup-snapshot $PART_FILE $MOUNT_POINT/.datto$PART_NUM $PART_NUM
			;;
		remove)
			[ -b $DEVICE ] && { 
				show_as_error "Removing '$DEVICE'"
				dbdctl destroy $PART_NUM 
			}
			;;
		exists)
			some_snapshots_exists
			;;
		list)
			ls -l /dev/datto$PART_NUM
			;;
		*)
			show_usage_and_exit
			;;

	esac
done

IFS=$OLD_IFS

