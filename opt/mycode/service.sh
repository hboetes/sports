#!/bin/sh
if [ ! -x /etc/rc.d/$1 ]; then
    echo Unknown service. >&2
    exit 1
fi

if [ $(id -u) != 0 ]; then
    sudo $0 $@
else
    /etc/rc.d/$@
fi
