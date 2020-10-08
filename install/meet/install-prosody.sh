#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/install-prosody.sh)
#

# Exit on error
set -e

printf "\e[00;32m--------------------- Install Prosody ----------------------\e[00m\n"
# Prosody 설치
echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -

sudo apt update
sudo apt install -y prosody

sudo chown root:prosody /etc/prosody/certs/localhost.key
sudo chmod 644 /etc/prosody/certs/localhost.key
# cp /etc/prosody/certs/localhost.key /etc/ssl

printf "\e[00;32m--------------------- Check Prosody ------------------------\e[00m\n"
dpkg -l prosody

