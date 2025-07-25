#!/usr/bin/env bash

cd /home/adam/irr-watch

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
		$WHOIS -h $IRR -i mnt-by $MNT > $MNT-$IRR
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

# HE filters
while read ASN; do
	$CURL -s "https://routing.he.net/index.php?cmd=display_filter&as=$ASN&af=4&which=irr" | grep "^ip prefix-list" > he-filter-as$ASN.txt
done <<< $AUTNUMS

# Routes with this origin
#while read ASN; do
#	whois -h rr.ntt.net -i origin AS$ASN > origin-$ASN.txt
#done <<< $AUTNUMS

whois -h $IRR -i origin AS$ASN | awk -v RS= -v ORS="\n\n" '
{
  for (i = 1; i <= NF; i++) {
    if ($i ~ /^route6?:/) {
      split($i, a)
      print a[2], $0
      break
    }
  }
}' | sort | cut -d' ' -f2- > origin-$ASN.txt

$GIT add .
$GIT commit -m "IRR changes"
$GIT push
