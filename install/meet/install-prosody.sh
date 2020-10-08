#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/install-prosody.sh)
#
# 사전작업
# FQDN 설정 /etc/hosts 파일 127.0.0.1 에 도메인 입력
# (ex : 127.0.0.1       grouput.kthcorp.com v-kgmeetctl01)
# /etc/ssl 에 인증서 복사

# Exit on error
set -e


echo "--------------------- Install Prosody ----------------------"
# Prosody 설치
echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -

sudo apt update
sudo apt install -y prosody

sudo chown root:prosody /etc/prosody/certs/localhost.key
sudo chmod 644 /etc/prosody/certs/localhost.key
# cp /etc/prosody/certs/localhost.key /etc/ssl


echo "--------------------- Check Prosody ------------------------"
dpkg -l prosody

