#!/bin/zsh
echo -n "subject: $*\n$*" | /usr/sbin/sendmail han
