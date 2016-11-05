#!/bin/bash

debugmsg () {
	[ -n "$DEBUG" ] && echo "$@"
}

trymtu () {
	[ -z "$DEBUG" ] && echo -n . || echo Trying $1
	! ip link set dev "$iface" mtu $1 2>&1 > /dev/null | grep -q "Invalid argument"
}

trap 'echo; exit 1' INT

iface=${1:?"Interface is required"}
max=${2:-12001}
min=1200
curr=$max

echo -n Testing
[ -n "$DEBUG" ] && echo

if ! trymtu $curr; then
	while (( max > min + 1 )); do
		debugmsg iter $min $max
		# search down until mtu succeeds
		debugmsg down...
		curr=$((max - ((max - min) / 2)))
		trymtu $curr
		rv=$?
		until [ $rv = 0 ]; do
			max=$curr
			curr=$((max - ((max - min) / 2)))
			# prevent infinite loops
			(( $curr == $max )) && break
			trymtu $curr
			rv=$?
		done
		[ $rv = 0 ] && min=$curr || max=$curr
		(( max > min + 1 )) || break
		# search up until mtu fails
		debugmsg up...
		curr=$((min + ((max - min) / 2)))
		trymtu $curr
		rv=$?
		while [ $rv = 0 ]; do
			min=$curr
			curr=$((min + ((max - min) / 2)))
			# prevent infinite loops
			(( $curr == $min )) && break
			trymtu $curr
			rv=$?
		done
		[ $rv = 0 ] && min=$curr || max=$curr
	done
	curr=$min
fi

ip link set dev "$iface" mtu $curr
[ -z "$DEBUG" ] && echo
echo MTU: $curr
