#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/jitsi-meet-token.sh)
#
# 사전작업
# FQDN 설정 /etc/hosts 파일 127.0.0.1 에 도메인 입력
# (ex : 127.0.0.1       grouput.kthcorp.com v-kgmeetctl01)
# /etc/ssl 에 인증서 복사

# Could not get lock / Unable to acquire the dpkg 에러 발생
sudo killall apt apt-get
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a

# Exit on error
set -e

sudo apt upgrade -y
sudo apt update


echo "------------------------- Install --------------------------"
sudo apt install -y gcc unzip lua5.2 liblua5.2-dev luarocks


echo "--------------------- Install BASEXX -----------------------"
sudo luarocks install basexx


echo "------------------ Install LIBSSL1.0-DEV -------------------"
sudo apt install -y libssl1.0-dev


echo "-------------------- Install LUACRYPTO ---------------------"
sudo luarocks install luacrypto


echo "---------------------- Install CJSON -----------------------"
mkdir src && cd src
sudo luarocks download lua-cjson
sudo luarocks unpack lua-cjson-2.1.0.6-1.src.rock

sudo sed -i 's/lua_objlen/lua_rawlen/g' ${HOME}/src/lua-cjson-2.1.0.6-1/lua-cjson/lua_cjson.c
sudo sed -i 's/5.1/5.2/g' ${HOME}/src/lua-cjson-2.1.0.6-1/lua-cjson/Makefile
sudo sed -i 's|$(PREFIX)/include|/usr/include/lua5.2|g' ${HOME}/src/lua-cjson-2.1.0.6-1/lua-cjson/Makefile

cd ${HOME}/src/lua-cjson-2.1.0.6-1/lua-cjson
sudo luarocks make


echo "---------------- Install Jitsi Meet Tokens -----------------"
sudo apt install -y jitsi-meet-tokens

echo "--------------------- Check Prosody ------------------------"
dpkg -l jitsi-meet-tokens
