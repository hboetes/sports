#!/bin/sh

(
    ftp -o - https://www.spamhaus.org/drop/drop.txt | awk -F ';' '{print $1}'
    ftp -o - http://okean.com/sinokoreacidr.txt | awk '{print $1}'
    cat /etc/pf.local_blacklist.txt
) | egrep -v '(#|^$)' | sort -n | uniq > /etc/pf.blockedranges.txt
pfctl -f /etc/pf.conf
