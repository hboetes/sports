#!/bin/sh
rm -f pkg_list
for i in $(find /usr{,/local}/{bin,lib} -type f); do
    echo -ne '\r'
    echo -n "$i "
    # if file $i | grep -q 'ELF.*bit LSB shared object' 2>&1 > /dev/null; then
    if file $i | fgrep -q 'bit LSB shared object' 2>&1 > /dev/null; then
	if ! ldd $i > /dev/null 2>&1; then
	    echo "appears to be unlinked" >&2
            pkg_locate $i| cut -d: -f1 >> pkg_list
	fi
    fi
done
echo These packages need updating:
cat pkg_list|sort|uniq|sed -e 's|-[0-9].*||' > pkg_list.new
mv pkg_list.new pkg_list
cat pkg_list
