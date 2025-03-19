#!/bin/bash

show_usage_and_exit(){
	echo "Usage: $0 <create|remove|list>" > /dev/stderr
	exit 1
}

field_of(){
	echo "$1" | cut -d$2 -f $3
}

some_snapshots_exists(){
	ls -1 /dev/datto* | grep -E 'datto[0-9]+' > /dev/null
}

show_error_and_exit(){
	echo "$*" > /dev/stderr
	exit 1
}


CMD=$1


#
# Работа
#
if [ "create" == "$CMD" ] && some_snapshots_exists; then
cat << EOF > /dev/stderr
Some snapshots already exists. Cannot create its again.
Existing snapshot devices:
`ls -1 /dev/datto*`

EOF
exit 1
fi


OLD_IFS=$IFS
IFS=$'\n'
set -f # Disable globbing.

for i in `mount | grep /dev/sda | sort`; do
	PART_FILE=`field_of "$i" ' ' 1`
	PART_NUM=`echo $PART_FILE | grep -Eo '[0-9]+$'`
	MOUNT_POINT=`field_of "$i" ' ' 3`
	FILE_SYSTEM=`field_of "$i" ' ' 5`


	case $CMD in
		create)
			dbdctl setup-snapshot $PART_FILE $MOUNT_POINT/.datto$PART_NUM $PART_NUM
			;;
		remove)
			dbdctl destroy $PART_NUM
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

