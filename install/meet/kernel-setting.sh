#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/setting.sh)

# Could not get lock / Unable to acquire the dpkg 에러 발생
sudo killall apt apt-get
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a

# Exit on error
set -e

sudo apt update


echo "------------------------ TEST START ------------------------"
VHOST="meetlocal.kthcorp.com"
JVBNAME="kthmeet-jvb"
TOKEN_APP_ID="433D3BF7B0A185DA47330C810934FBFF"
TOKEN_APP_SECRET="qwer1234"
echo "------------------------- TEST END -------------------------"


echo "-------------------- Setting Meet Config -------------------"
IPADDR=$(hostname -I | awk '{print $1}')

if [[ -z ${VHOST} ]]; then
    printf "Enter the virtual host(eg. meetdev.kthcorp.com)"
    read -e -p " > " VHOST
    while [[ -z ${VHOST} ]]; do
        printf "Enter the virtual host (eg. meetdev.kthcorp.com)"
        read -e -p " > " VHOST
    done
fi

if [[ -z ${JVBNAME} ]]; then
    printf "Enter the java video bridge name (eg. meetdev01)"
    read -e -p " > " JVBNAME
    while [[ -z ${JVBNAME} ]]; do
        printf "Enter the java video bridge name (eg. meetdev01)"
        read -e -p " > " JVBNAME
    done
fi

if [[ -z ${TOKEN_APP_ID} ]]; then
    printf "Enter the token app id (eg. 433D3BF7)"
    read -e -p " > " TOKEN_APP_ID
    while [[ -z ${TOKEN_APP_ID} ]]; do
        printf "Enter the token app id (eg. 433D3BF7)"
        read -e -p " > " TOKEN_APP_ID
    done
fi

if [[ -z ${TOKEN_APP_SECRET} ]]; then
    printf "Enter the token app secret (eg. qwer1234)"
    read -e -p " > " TOKEN_APP_SECRET
    while [[ -z ${TOKEN_APP_SECRET} ]]; do
        printf "Enter the token app secret (eg. qwer1234)"
        read -e -p " > " TOKEN_APP_SECRET
    done
fi


echo "---------------- Setting Kernel Parameter ------------------"
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
