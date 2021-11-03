#!/usr/bin/env bash
MAINTAINER=`cat maintainers.txt | sed "s/ *#.*$//g" | grep .`
IRRDB=`cat registries.txt | sed "s/ *#.*$//g" | grep .`
WHOIS=`which whois`
TIMESTAMP=`printf '%(%Y-%m-%d.%H%M%S)T\n' -1`

while read IRR; do
	while read MNT; do
		echo "$WHOIS -h $IRR -i mnt-by $MNT > $MNT-$IRR"
	done <<< $MAINTAINER
done <<< $IRRDB
