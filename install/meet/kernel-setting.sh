#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/kernel-setting.sh)
#

# Exit on error
set -e

printf "\e[00;32m---------------- Setting Kernel Parameter ------------------\e[00m\n"
# Kernel Parameter 변경
if [[ ! -n $(awk "/net.core.rmem_max/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.core.rmem_max = 33554432' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.core.wmem_max/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.core.wmem_max = 33554432' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.core.rmem_default/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.core.rmem_default = 1048576' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.core.netdev_max_backlog/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.core.netdev_max_backlog = 100000' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.core.somaxconn/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.core.somaxconn = 1024' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.core.wmem_default/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.core.wmem_default = 1048576' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.ipv4.tcp_max_syn_backlog/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.ipv4.tcp_max_syn_backlog = 8192' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.ipv4.udp_rmem_min/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.ipv4.udp_rmem_min = 1048576' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.ipv4.udp_wmem_min/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.ipv4.udp_wmem_min = 1048576' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.ipv6.conf.all.disable_ipv6/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf"
fi
if [[ ! -n $(awk "/net.ipv6.conf.default.disable_ipv6/" /etc/sysctl.conf) ]]; then
    sudo sh -c "echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf"
fi

net_list=($(ls /sys/class/net))
for i in `seq 0 $((${#net_list[*]}-1))`; do
    name=${net_list[${i}]}
    if [[ ! -n $(awk "/net.ipv6.conf.${name}.disable_ipv6/" /etc/sysctl.conf) ]]; then
        sudo sh -c "echo 'net.ipv6.conf.${name}.disable_ipv6 = 1' >> /etc/sysctl.conf"
    fi
done

sudo sysctl -p
