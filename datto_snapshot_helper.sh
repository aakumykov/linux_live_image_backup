#!/bin/bash

if [ $# -lt 2 ]; then
	cat <<- EOF
	Usage: $0 <disk> <create|remove|list>
	Example: $0 /dev/sda create
	EOF
	exit 1
fi

DISK=$1
shift

CMD=$1
shift


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

for i in `mount | grep $DISK | sort`; do
	P=`field_of "$i" ' ' 1`
	N=`echo $P | grep -Eo '[0-9]+$'`
	M=`field_of "$i" ' ' 3`
	F=`field_of "$i" ' ' 5`


	case $CMD in
		create)
			dbdctl setup-snapshot $P $M/.datto$N $N
			;;
		remove)
			dbdctl destroy $N
			;;
		list)
			ls -l /dev/datto$N
			;;
		*)
			show_usage_and_exit
			;;

	esac
done

IFS=$OLD_IFS

