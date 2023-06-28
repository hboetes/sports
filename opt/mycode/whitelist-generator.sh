#!/bin/zsh

# Copyright 2016, Han Boetes <hboetes@gmail.com>
# Released under the MIT license, see LICENSE file included in this repository.

# TODO the rest of the spec is also interesting.
recurse()
{
    t=$(dig +short +nosplit -t TXT $1 | grep v=spf1 | sed -e 's|" "||g')
    # (Q) strips a string of quotes.
    t=${(Q)t}
    for i in ${=t}; do
        case $i in
            ip4:*)
                # if it's a /32
                if [[ $i == */32 ]]; then
                    ip4=${i%/32}
                    echo "${ip4#ip4:} $whattodo"
                # If it's an ip range.
                elif [[ ${i#ip4} == */* ]]; then
                    # Even professional sysadmins make mistakes. And
                    # postfix will complain about that.
                    ip4="$(ipc ${i#ip4:})"
                    echo "${ip4} $whattodo"
               else
                    echo "${i#ip4:} $whattodo"
                fi
                ;;
            ip6:*)
                echo ${i#ip6:} $whattodo
                :
                ;;
            include:*)
                recurse ${i#include:}
                ;;
            redirect\=*)
                k=${i#redirect\=}
                recurse $k
                ;;
            # MXes are a bit more complicated. They produce a list of
            # hostnames that can have both A and AAAA records.
            mx)
                for MX in $(dig +short -t MX $1| cut -d' ' -f2); do
                    A="$(dig +short -t A $MX)"
                    if [[ $A != $IFS ]]; then
                        for j in ${=A}; do
                            echo $j $whattodo
                        done
                    fi
                    AAAA="$(dig +short -t AAAA $MX)"
                    [[ $AAAA != $IFS ]] && [[ $AAAA != '' ]] && echo $AAAA $whattodo
                done
                ;;
            a:*)
                for AA in $(dig +short -t A ${i#a:}| cut -d' ' -f2); do
                    echo $AA $whattodo
                done
                ;;
        esac
    done
}

ipc(){

    ipcalc $1| awk '/^Network:/ {print $2}'
}

# Groups of hosts to be queried (edit to your liking)
for domain in google.com hotmail.com github.com paypal.com gmx.com linkedin.com amazon.com telenet.be boetes.org axis-simulation.com easybank.at; do
    whattodo=permit
    echo "# $domain"
    recurse $domain
done

# Blacklisting is also possible: format
# 172.93.224.0/24 reject optional message.
echo '# The rejects from /etc/postfix/blacklist'
cat /etc/postfix/blacklist
