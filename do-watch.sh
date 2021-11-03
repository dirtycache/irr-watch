#!/usr/bin/env bash
cd /home/eng/irr-watch
MAINTAINER=`cat maintainers.txt | sed "s/ *#.*$//g" | grep .`
IRRDB=`cat registries.txt | sed "s/ *#.*$//g" | grep .`
WHOIS=`which whois`
GIT=`which git`
TIMESTAMP=`printf '%(%Y-%m-%d.%H%M%S)T\n' -1`

while read IRR; do
	while read MNT; do
		$WHOIS -h $IRR -i mnt-by $MNT > $MNT-$IRR
	done <<< $MAINTAINER
done <<< $IRRDB

$GIT add .
$GIT commit -m "IRR changes"
$GIT push
