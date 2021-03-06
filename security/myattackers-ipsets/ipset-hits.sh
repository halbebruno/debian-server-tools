#!/bin/bash
#
# Display hits of ipsets and reset their counters.
#
# VERSION       :0.1.1
# DATE          :2016-04-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install ipset
# LOCATION      :/usr/local/sbin/ipset-hits.sh

Reset_rule() {
    local IPSET="$1"
    local RULE
    local -i RULE_NUMBER

    RULE="$(iptables -n --line-numbers -L myattackers-ipset | grep -F "match-set ${IPSET} src reject-with icmp-port-unreachable")"
    RULE_NUMBER="${RULE%% *}"
    if [ -z "$RULE_NUMBER" ] || [ "$RULE_NUMBER" -lt 1 ]; then
        return 1
    fi

    if ! iptables -v -n -Z myattackers-ipset "$RULE_NUMBER" -L;
        echo "Error resetting rule for ${IPSET}" 1>&2
        return 2
    fi

    return 0
}

for IPSET in $(ipset list -name); do
    Reset_rule "$IPSET"
done
