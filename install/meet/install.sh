#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/develop-document/master/Template/install-script/meet/meet-pre-work.sh)
#
# 사전작업
# FQDN 설정 /etc/hosts 파일 127.0.0.1 에 도메인 입력
# (ex : 127.0.0.1       grouput.kthcorp.com v-kgmeetctl01)
# /etc/ssl 에 인증서 복사

# kernel parameter 변경
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


# alias 설정 추가
if [[ ! -n $(awk "/alias jicofo-log/" $HOME/.bash_aliases) ]]; then
    echo "alias jicofo-log='sudo tail -100f /var/log/jitsi/jicofo.log'" >> $HOME/.bash_aliases
fi
if [[ ! -n $(awk "/alias prosody-err/" $HOME/.bash_aliases) ]]; then
    echo "alias prosody-err='sudo   tail -100f /var/log/prosody/prosody.err'" >> $HOME/.bash_aliases
fi
if [[ ! -n $(awk "/alias prosody-log/" $HOME/.bash_aliases) ]]; then
    echo "alias prosody-log='sudo   tail -100f /var/log/prosody/prosody.log'" >> $HOME/.bash_aliases
fi
if [[ ! -n $(awk "/alias allstart/" $HOME/.bash_aliases) ]]; then
    echo "alias allstart='sudo service prosody start && sudo service jicofo start && sudo service jitsi-videobridge2 start && sudo service nginx start'" >> $HOME/.bash_aliases
fi
if [[ ! -n $(awk "/alias allstop/" $HOME/.bash_aliases) ]]; then
    echo "alias allstop='sudo service prosody stop && sudo service jicofo stop && sudo service jitsi-videobridge2 stop && sudo service nginx stop'" >> $HOME/.bash_aliases
fi
if [[ ! -n $(awk "/alias allrestart/" $HOME/.bash_aliases) ]]; then
    echo "alias allrestart='sudo service prosody restart && sudo service jicofo restart && sudo service jitsi-videobridge2 restart && sudo service nginx restart'" >> $HOME/.bash_aliases
fi
source $HOME/.bashrc

# ------------------------------------------------------------
cat $HOME/.bash_aliases

# 기존 설치 된 lua5.1 제거 (모든 cjson, luajwtjitsi 등 luarocks 로 설치 된 모든 패키지에 영향을 미침)
sudo apt remove -y lua5.1

sudo apt update -y

echo "--------------------------- GCC ----------------------------"
sudo apt install -y gcc

echo "-------------------------- UNZIP ---------------------------"
sudo apt install -y unzip

echo "-------------------------- LUA5.2 --------------------------"
sudo apt install -y lua5.2

echo "------------------------ LIBLUA5.2 -------------------------"
sudo apt install -y liblua5.2

echo "---------------------- LIBLUA5.2-DEV -----------------------"
sudo apt install -y liblua5.2-dev

echo "------------------------- LUAROCKS -------------------------"
sudo apt install -y luarocks

echo "---------------------- LIBSSL1.0-DEV -----------------------"
sudo apt install -y libssl1.0-dev

# luarocks 를 통한 패키지 설치
echo "-------------------------- CJSON ---------------------------"
mkdir src && cd src
sudo luarocks download lua-cjson
sudo luarocks unpack lua-cjson-2.1.0.6-1.src.rock
cd lua-cjson-2.1.0.6-1/lua-cjson
sed -i 's/lua_objlen/lua_rawlen/g' lua_cjson.c
sed -i 's/5.1/5.2/g' Makefile
sed -i 's|$(PREFIX)/include|/usr/include/lua5.2|g' Makefile
sudo luarocks make

echo "------------------------- BASEXX ---------------------------"
luarocks install basexx

echo "------------------------ LUACRYPTO -------------------------"
sudo luarocks install luacrypto
sudo luarocks install luajwtjitsi

# ------------------------------------------------------------
# Prosody 설치
echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -

sudo apt update
sudo apt install -y prosody

# Prosody 버전 확인
dpkg -l prosody

# ------------------------------------------------------------
# Prosody 설치
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list

sudo apt update -y
sudo apt install -y prosody

sudo chown root:prosody /etc/prosody/certs/localhost.key
sudo chmod 644 /etc/prosody/certs/localhost.key
cp /etc/prosody/certs/localhost.key /etc/ssl

# ------------------------------------------------------------
# Jitsi Meet 설치
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

sudo apt update -y
sudo apt install -y jitsi-meet
#sudo apt install -y jitsi-meet-turnserver
sudo apt install -y jitsi-meet-tokens
