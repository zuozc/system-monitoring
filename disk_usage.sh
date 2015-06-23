#!/bin/bash
HOSTNAME="${COLLECTD_HOSTNAME:-`hostname -f`}"
INTERVAL="${COLLECTD_INTERVAL:-15}"

if [[ $# -eq 1 ]]; then
	INTERVAL=$1
fi

# write logs with collectd
# parameters: 1.disk name 2.writable 3.readable 4.usage
record_log() {

	echo "PUTVAL $HOSTNAME/my-disk/disk_usage-$1 interval=$INTERVAL N:$2:$3:$4"

}

# check if disk is writable, readable or not and its usage.
check_disk() {
 
	(df -h | grep '^/dev') | while read line
	do 
		
		disk=$(echo $line | awk '{print $1}')
		usage=$(echo $line | awk '{print $5}')
		forder=$(echo $line | awk '{print $6}')
			
		# initiate
		disk=${disk##*\/}
		writable=1
		readable=1
		usage=${usage%%\%}

		# writable or not
		if [[ -w ${forder} ]]; then writable=0; fi
		
		# readable or not
		if [[ -r ${forder} ]]; then readable=0;	fi
		
		record_log $disk $writable $readable $usage
		
	done
}

while sleep "$INTERVAL"; do
   check_disk
done
