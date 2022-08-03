#!/bin/sh
echo -n "subject: $*\n$*" | sendmail han
