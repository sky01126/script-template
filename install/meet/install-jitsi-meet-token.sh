#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/install-jitsi-meet-token.sh)
#

# Exit on error
set -e

printf "\e[00;32m--------------------- Install Library ----------------------\e[00m\n"
sudo apt install -y gcc unzip lua5.2 liblua5.2-dev luarocks

# printf "\e[00;32m--------------------- Install Luarocks ---------------------\e[00m\n"
# mkdir $HOME/src
# cd $HOME/src

# wget https://keplerproject.github.io/luarocks/releases/luarocks-2.4.1.tar.gz
# tar xvzf luarocks-2.4.1.tar.gz

# cd $HOME/src/luarocks-2.4.1
# ./configure --lua-version=5.2 --versioned-rocks-dir
# make build
# sudo make install

printf "\e[00;32m---------------------- Install BASEXX ----------------------\e[00m\n"
sudo luarocks install basexx

printf "\e[00;32m------------------ Install LIBSSL1.0-DEV -------------------\e[00m\n"
sudo apt install -y libssl1.0-dev

printf "\e[00;32m-------------------- Install LUACRYPTO ---------------------\e[00m\n"
sudo luarocks install luacrypto

printf "\e[00;32m---------------------- Install CJSON -----------------------\e[00m\n"
cd $HOME/src

sudo luarocks download lua-cjson
sudo luarocks unpack lua-cjson-2.1.0.6-1.src.rock

sudo sed -i 's/lua_objlen/lua_rawlen/g' ${HOME}/src/lua-cjson-2.1.0.6-1/lua-cjson/lua_cjson.c
sudo sed -i 's/5.1/5.2/g' ${HOME}/src/lua-cjson-2.1.0.6-1/lua-cjson/Makefile
sudo sed -i 's|$(PREFIX)/include|/usr/include/lua5.2|g' ${HOME}/src/lua-cjson-2.1.0.6-1/lua-cjson/Makefile

cd ${HOME}/src/lua-cjson-2.1.0.6-1/lua-cjson
sudo luarocks make

printf "\e[00;32m---------------- Install Jitsi Meet Tokens -----------------\e[00m\n"
sudo apt install -y jitsi-meet-tokens

printf "\e[00;32m---------------------- Check Prosody -----------------------\e[00m\n"
dpkg -l jitsi-meet-tokens
