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
                # If it's not an ip range.
                if [[ ${i#ip4} != */* ]]; then
                    echo ${i#ip4:} permit
                elif [[ ${i#ip4} = */32 ]]; then
                    i=${i%/32}
                    echo ${i#ip4:} permit
                else
                    # Even professional sysadmins make mistakes. And
                    # postfix will complain about that.
                    ip4=$($ipc ${i#ip4:})
                    echo ${ip4} permit
                fi
                ;;
            ip6:*)
                echo ${i#ip6:} permit
                :
                ;;
            include:*)
                recurse ${i#include:}
                ;;
            redirect\=*)
                i=${i#redirect\=}
                recurse $i
                ;;
            # MXes are a bit more complicated. They produce a list of
            # hostnames that can have both A and AAAA records.
            mx)
                for MX in $(dig +short -t MX $1| cut -d' ' -f2); do
                    A="$(dig +short -t A $MX)"
                    if [[ $A != $IFS ]]; then
                        for i in ${=A}; do
                            echo $i permit
                        done
                    fi
                    AAAA="$(dig +short -t AAAA $MX)"
                    [[ $AAAA != $IFS ]] && [[ $AAAA != '' ]] && echo $AAAA permit
                done
                ;;
            a:*)
                for AA in $(dig +short -t A $1| cut -d' ' -f2); do
                    echo $AA permit
                done
                ;;
        esac
    done
}

ipc_pyr()
{
    ipcalc $1 | awk '/network/ {print $3$4}'
}

ipc_jodies()
{
    ipcalc -nb $1 | awk '/Network/ {print $2}'
}

if ipcalc -nb 10/8 > /dev/null 2>&1; then
    ipc=ipc_jodies
else
    ipc=ipc_pyr
fi

# Groups of hosts to be queried (edit to your liking)
#webmail_hosts="aol.com google.com microsoft.com outlook.com hotmail.com gmx.com icloud.com mail.com inbox.com zoho.com"
#social_hosts="facebook.com twitter.com pinterest.com instagram.com tumblr.com reddit.com linkedin.com"
#commerce_hosts="craigslist.org amazon.com ebay.com paypal.com"
#bulk_hosts="sendgrid.com sendgrid.net mailchimp.com exacttarget.com cust-spf.exacttarget.com constantcontact.com icontact.com mailgun.com fishbowl.com fbmta.com mailjet.com"
#misc_hosts="zendesk.com github.com"
# gmx?

for domain in google.com hotmail.com github.com paypal.com gmx.com linkedin.com amazon.com telenet.be boetes.org axis-simulation.com; do
    # for domain in amazon.com; do
    echo "# $domain"
    recurse $domain
done

# Blacklisting is also possible: format
# 172.93.224.0/24 reject optional message.
cat /etc/postfix/blacklist
