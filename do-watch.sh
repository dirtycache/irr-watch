#!/usr/bin/env bash

cd /home/eng/irr-watch

MAINTAINER=`cat maintainers.txt | sed "s/ *#.*$//g" | grep .`
IRRDB=`cat registries.txt | sed "s/ *#.*$//g" | grep .`
AUTNUMS=`cat autnums-filters.txt | sed "s/ *#.*$//g" | grep .`
WHOIS=`which whois`
GIT=`which git`
CURL=`which curl`
TIMESTAMP=`printf '%(%Y-%m-%d.%H%M%S)T\n' -1`

/usr/bin/rm -f autnum_*.txt

while read IRR; do
	while read MNT; do
		if ["$IRR" == "rr.ntt.net"]; then
			IRRSRC="NTTCOM"
		elif ["$IRR" == "rr.level3.net"]; then
			IRRSRC="LEVEL3"
		elif ["$IRR" == "whois.radb.net"]; then
			IRRSRC="RADB"
		elif ["$IRR" == "rr.arin.net"]; then
			IRRSRC="ARIN"
		fi
		echo "$WHOIS -h $IRR -s $IRRSRC -i mnt-by $MNT"	
		#$WHOIS -h $IRR -i mnt-by $MNT > $MNT-$IRR
	done <<< $MAINTAINER
done <<< $IRRDB

#while read IRR; do
#        while read MNT; do
#                $WHOIS -h $IRR -i mnt-by $MNT | grep aut-num | awk '{print $2}' >> autnum_$IRR.txt
#		while read AUTNUM; do
#			$WHOIS -h $IRR -i origin $AUTNUM > routes-origin-$AUTNUM-$IRR.txt 
#		done <<< `cat autnum_$IRR.txt`
#        done <<< $MAINTAINER
#done <<< $IRRDB

while read ASN; do
	$CURL curl -s "https://routing.he.net/index.php?cmd=display_filter&as=$ASN&af=4&which=irr" | grep "^ip prefix-list" > he-filter-as$ASN.txt
done <<< $AUTNUMS

$GIT add .
$GIT commit -m "IRR changes"
$GIT push
