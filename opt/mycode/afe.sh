#!/bin/zsh

# Copyright 2016 Han Boetes <han@boetes.org>
# Released under the MIT license.

GREP="/bin/grep -Ei"

case $1 in
    *magnet*)
        aria2c --bt-metadata-only --bt-save-metadata=true "$1"
        ;;
    http*)
        aria2c --follow-torrent=false "$1"
        ;;
    *.torrent)
        searchstring="$2"
        filelist=$(aria2c -S  "$1" | grep '[0-9]\|\./') # > ${1%torrent}filelist
        while :; do
            if [[ $searchstring == "" ]]; then
                searchstring='.'
            fi
            selection=(${(@f)"$(print -Rl $filelist | ${=GREP} $searchstring)"})
            clear
            print -Rl $selection
            oldsearchstring="$searchstring"
            # vared is a very nifty function provided by zsh.
            vared -p 'What do you want to download? Press enter again if you are done. ' searchstring
            if [[ $oldsearchstring == $searchstring ]]; then
                allfiles=($selection)
                break
            fi
        done
        getnum=${allfiles//|*/,}
        clearwhite=${getnum// /}
        downlitems=${clearwhite%,}
        command="aria2c --select-file=$downlitems $1"
        echo "Proceed with: $command [y/N] "
        read -rsk 1 reply
        if [[ $reply != n ]]; then
            echo ${=command}
            ${=command}
        fi
        ;;
    *)
        echo "What what what what?" >&2
        ;;
esac
