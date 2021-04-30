#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

firstLine="$(cat "$1" | head -n 1 )" 

alg=""
keyid=""
key=""
format=""

convert () {
	if [ "$format" == "knot" ]; then
		echo "converting to BIND format" >> /dev/stderr
		echo "key \"$keyid\" {"
		echo "	algorithm $alg;"
		echo "	secret \"$key\";"
		echo "};"
	fi
	if [ "$format" == "bind" ]; then
		echo "converting to KNOT format" >> /dev/stderr
		echo "# $alg:$keyid:$key"
		echo "key: "
		echo "  - id: $keyid"
		echo "    algorithm: $alg"
		echo "    secret: $key"
	fi
}

#detect knot format via comment generated by keymgr
if [[ ${firstLine:0:2} == "# " ]] ; then 
	firstLine="${firstLine:2}"
	alg="$(echo "$firstLine" | awk -F  ":" '{print $1}')"
	keyid="$(echo "$firstLine" | awk -F  ":" '{print $2}')"
	key="$(echo "$firstLine" | awk -F  ":" '{print $3;}')"
	if [[ ! ( -z "$alg" || -z "$keyid" || -z "$key" ) ]];then
		format="knot"
		echo "detected KNOT format (via comment)" >> /dev/stderr
		convert
		exit 0
	fi
fi

#detect knot, without comment 
s=0
while read line; do
	if [ $s -eq 2 ];then
		if [[ "$line" =~ "algorithm:" ]]; then
			alg="$(echo "$line" | awk '{print $2}' )"
		fi
		if [[ "$line" =~ "secret:" ]]; then
			key="$(echo "$line" | awk '{print $2}' )"
		fi

	fi

	if [ $s -eq 1 ]; then
		if [[ "$line" =~ "id:" ]]; then
			keyid="$(echo "$line" | awk '{print $3}' )"
			s=2
		fi
	fi	

	if [[ "$line" =~ "key:" ]] ; then
		s=1
	fi
done <"$1"

if [[ ! ( -z "$alg" || -z "$keyid" || -z "$key" ) ]];then
	format="knot"
	echo "detected KNOT format" >> /dev/stderr
	convert
	exit 0
fi


#detect bind format, generated via tsig-keygen
s=0
while read line; do
	if [ $s -eq 2 ];then
		if [[ "$line" =~ "algorithm" ]]; then
			alg="$(echo "$line" | awk '{print $2}' | rev | cut -c2- | rev)"
		fi
		if [[ "$line" =~ "secret" ]]; then
			key="$(echo "$line" | awk '{print $2}' | cut -c2- | rev | cut -c3- | rev)"
		fi
	fi

	if [[ "$line" =~ 'key "' ]] ; then
		keyid="$( echo "$line" | awk -F '"' '{print $2}')"
		s=2
	fi
done <"$1"

if [[ ! ( -z "$alg" || -z "$keyid" || -z "$key" ) ]];then
	format="bind"
	echo "detected BIND format" >> /dev/stderr
	convert
	exit 0
fi

echo "cound not parse input" >> /dev/stderr
exit 1
