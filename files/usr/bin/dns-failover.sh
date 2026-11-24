#!/bin/sh
# DNS 降级守护：PVE 代理存活时走 fake-ip + 代理，失联时自动切回国内直连。
# 由 /etc/init.d/dns-failover 每 10 秒调用一次，自身幂等。

PROXY=192.168.2.7
STATE=/tmp/dns-failover.state
CNT=/tmp/dns-failover.cnt
LOG=/root/dns-failover.log

if timeout 3 nslookup www.baidu.com "$PROXY" >/dev/null 2>&1; then
    echo 0 > "$CNT"
    UP=1
else
    c=$(cat "$CNT" 2>/dev/null || echo 0)
    c=$((c + 1))
    echo "$c" > "$CNT"
    if [ "$c" -ge 2 ]; then UP=0; else UP=1; fi
fi

old=$(cat "$STATE" 2>/dev/null)

if [ "$UP" = "1" ]; then
    ip route replace 198.18.0.0/15 via "$PROXY" dev br-lan 2>/dev/null
    if [ "$old" != "up" ]; then
        uci set dhcp.@dnsmasq[0].noresolv='1'
        uci -q delete dhcp.@dnsmasq[0].server
        uci add_list dhcp.@dnsmasq[0].server="$PROXY"
        uci commit dhcp
        /etc/init.d/dnsmasq restart >/dev/null 2>&1
        echo up > "$STATE"
        echo "$(date '+%F %T') UP   DNS=$PROXY  route 198.18/15 via $PROXY" >> "$LOG"
    fi
else
    ip route del 198.18.0.0/15 2>/dev/null
    if [ "$old" != "down" ]; then
        uci set dhcp.@dnsmasq[0].noresolv='1'
        uci -q delete dhcp.@dnsmasq[0].server
        uci add_list dhcp.@dnsmasq[0].server='223.5.5.5'
        uci add_list dhcp.@dnsmasq[0].server='119.29.29.29'
        uci commit dhcp
        /etc/init.d/dnsmasq restart >/dev/null 2>&1
        echo down > "$STATE"
        echo "$(date '+%F %T') DOWN DNS=domestic  route removed" >> "$LOG"
    fi
fi
