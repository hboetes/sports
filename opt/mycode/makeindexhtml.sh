#!/bin/sh
# $Id: makeindexhtml,v 1.22 2007/03/17 19:19:27 han Exp $
# makeindexhtml-0.1
#
# This shell script makes an index.html file in the current and
# underlying directories
#
# Copyright (c) by Han Boetes <hboetes@gmail.com>
#
# Permission to use, copy, modify, and distribute this software
# for any purpose with or without fee is hereby granted, provided
# that the above copyright notice and this permission notice
# appear in all copies.

# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# This script was written with portability in mind. I cross-test
# it on linux and OpenBSD all the time. So if you have any
# improvements that you would like to send to me please keep that
# in mind.

##############################
# Settings.

# Make a file in the the basedir called .data that contains the
# url to the datadir with: dir.css, directory.gif, file.gif,
# link.gif
DATADIR="//homepage.boetes.org/.data" # Get mine from here if you want.
[ -r .data ] && DATADIR=$(cat .data)

ignorefile=".makeindexhtml.ignore"

# You can also add a .header and a .footer file in every directory.

# End of the configuration settings.  Change only below this line
# if you know what you are doing or don't care if it doesn't work.
#####################################

# compat with gnu-ls
if ls --version > /dev/null 2>&1; then
    alias ls='ls --time-style=locale'
fi

f_makeindexhtml()
{
    echo "Making an index.html in $hier/$directory"
    # The main html header
    cat << EOF > index.html
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="$DATADIR/dir.css">
<title></title>
</head>
<body>
EOF

    # Add headerfile
    [ -r .header ] && cat .header >> index.html

    # Make a directory header for easy browsing.
    # first lets get all the dirnames in sepparate pieces.
    dirlist=$(echo .. $directory|tr '/' ' ')
    printf  '\n%s' '<p>&nbsp;&nbsp;' >> index.html
    set -- $dirlist
    dirlength=$#
    for directory in $dirlist; do
        # Count backsteps "../" in the dir-structure.
        unset revdirs
        thisdir=$dirlength
        while [ $thisdir -gt 1 ]; do
            revdirs=$revdirs'../'
            thisdir=$(($thisdir - 1))
        done
        dirlength=$(($dirlength - 1))

        echo -n '<a href="'$revdirs'">'$directory'</a>/' >> index.html
    done

    printf "%s\n\n" "</p>" >> index.html
    # The head of the table.
    cat << EOF >> index.html
<table>
<tr>
<td class="nameh"><strong>Name</strong></td>
<td class="sizeh" align="right"><strong>Size</strong></td>
<td class="timeh"><strong>Time</strong></td>
</tr>

<tr>
<td class="name"><a href="../"><img src="$DATADIR/directory.gif" alt="prevdir">..</a></td>
<td class="size" align="right">&nbsp;</td>
<td class="time">&nbsp;</td>
</tr>

EOF
    find . -maxdepth 1 ! \( \
	-name . -o \
	-name CVS -o \
	-name index.html -o \
	-name .base -o \
	-name .cvsignore -o \
	-name .header -o \
	-name .footer \)|sed 's|^\./||'|sort| \
	$filter | \
	while read i; do
	    set -- $(ls -ldL "$i" 2>/dev/null)
            sizeentry=$5
            timeentry="$6 $7 $8"
            entryname=$i

            entrytype=file
            if [ -d "$i" ]; then
                entrytype=directory
            else
                if [ -L "$i" ]; then
                    entrytype=link
                fi
            fi
            cat << EOF >> index.html
<tr>
<td class="name"><a href="$entryname"><img src="$DATADIR/$entrytype.gif" alt="$entryname">$entryname</a></td>
<td class="size" align="right">$sizeentry</td>
<td class="time">$timeentry</td>
</tr>

EOF
	done
    # Well in case I wanna add something later.
    cat << EOF >> index.html
</table>
EOF

    # Add the footerfile
    [ -r .footer ] && cat .footer >> index.html

    # html footer
    cat << EOF >> index.html
</body>
</html>
EOF
}

if [ -r $PWD/$ignorefile ]; then
    filter="egrep -v -f $PWD/$ignorefile"
else
    filter=cat
fi

# Believe it or not but this is the main program.
hier=$PWD
find . -type d ! -name CVS|sed 's|^\./||'|$filter|while read directory; do
cd $hier/$directory
# only update index.html if it's not the newest file in the subdir.
if [ -n "$(find . ! -name . -maxdepth 1 -newer index.html 2> /dev/null)" ] || [ ! -r index.html ]; then
    f_makeindexhtml
else
    echo "index.html up to date in $hier/$directory"
fi
done
