#!/usr/bin/env zsh

local packages=($@)
local all=false
local reinstall=()
# Don't build these packages automatically, they _always_ have changes
# and are massive hogs to build.
local weekly=(emacs sccache rspamd)
unset depends
if [[ -z $packages ]]; then
    packages=($(prt-get listinst))
    all=true
fi

for i in $packages; do
    # skip packages in the weekly array not older than 7 days.
    if [[ $all == true ]] && (($weekly[(Ie)$i])); then
        if find /usr/pkgmk/package/${i}_*pkg.tar.gz -mtime -7 | \grep -q . ; then
            echo "Skipping $i, it's less than 7 days old."
            continue
        fi
    fi
    if [ -d /usr/pkgmk/source/$i/.git/ ]; then
        echo "checking if $i is up to date"
        git -C /usr/pkgmk/source/$i remote update
        if git -C /usr/pkgmk/source/$i status -uno|grep -q 'git pull'; then
            (
                cd /usr/sports/*/$i
                # First check if the dependencies need an update
                # XXX this will result in multiple reinstall requests.
                source Pkgfile
                for dep in $depends; do
                    update-git-ports $dep
                done
                pkgmk -f
            ) && reinstall+=$i
        fi
    else
        [[ $all == false ]] && echo "$i is not a git package"
    fi
done

if [[ -n $reinstall ]]; then
    echo 'you there? [Y/n]'
    read -sk1 niets
    prt-get update $reinstall
fi
