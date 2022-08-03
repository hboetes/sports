#!/bin/sh

# get the list of mirrors
if [[ ! -e ftp.html ]]; then
    wget -q https://www.openbsd.org/ftp.html
fi
# get the main mirror's timestamp
mainstamp=$(ftp -o - https://ftp.openbsd.org/pub/OpenBSD/patches/timestamp)
# get the urls for the http mirrors.
mirrors=$(sed -ne 's|<a href="\(http.*\)" rel="nofollow">|\1|p' ftp.html)
for i in $mirrors; do
    mirrorstamp=$(wget -T 5 -q -O - $i/patches/timestamp)
    if [[ $mainstamp == $mirrorstamp ]]; then
        echo "$mirrorstamp: $i is up to date"
    elif [[ -n $mirrorstamp ]]; then
        hours=$(((mainstamp  - mirrorstamp) / 3600))
        if [[ $hours -lt 23 ]]; then
            echo "$mirrorstamp: $i is $hours hour(s) late"
        else
            days=$(($hours/24))
            echo "$mirrorstamp: $i more than $days day(s) late."
        fi
    else
        echo "$mirrorstamp: Mirror $i is unreachable"
    fi
done
