#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/install-2.0.4627-1.sh)
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


echo "--------------------- Setting Version ----------------------"
export JICOFO_VERSION=1.0-589-1
export JITSI_MEET_VERSION=2.0.4627-1
export JITSI_MEET_WEB_VERSION=1.0.4127-1
export JITSI_MEET_WEB_CONFIG_VERSION=1.0.4127-1
export JITSI_MEET_PROSODY_VERSION=1.0.4127-1
export JITSI_MEET_TURNSERVER_VERSION=1.0.4127-1
export JITSI_VIDEOBRIDGE_VERSION=2.1-202-g5f9377b9-1

# KTH에 맞는 버전 설정.
export JITSI_MEET_TOKENS_VERSION=1.0.4370-1

export LUA_CJSON_VERSION=2.1.0.6-1

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


echo "---------------------- Setting Alias -----------------------"
# alias 설정 추가
if [[ ! -n $(awk "/alias jicofo-log/" ${HOME}/.bash_aliases) ]]; then
    echo "alias jicofo-log='sudo tail -f /var/log/jitsi/jicofo.log'" >> ${HOME}/.bash_aliases
fi
if [[ ! -n $(awk "/alias prosody-err/" ${HOME}/.bash_aliases) ]]; then
    echo "alias prosody-err='sudo tail -f /var/log/prosody/prosody.err'" >> ${HOME}/.bash_aliases
fi
if [[ ! -n $(awk "/alias prosody-log/" ${HOME}/.bash_aliases) ]]; then
    echo "alias prosody-log='sudo tail -f /var/log/prosody/prosody.log'" >> ${HOME}/.bash_aliases
fi
if [[ ! -n $(awk "/alias allstart/" ${HOME}/.bash_aliases) ]]; then
    echo "alias start-all='sudo service prosody start && sudo service jicofo start && sudo service jitsi-videobridge2 start && sudo service nginx start'" >> ${HOME}/.bash_aliases
fi
if [[ ! -n $(awk "/alias allstop/" ${HOME}/.bash_aliases) ]]; then
    echo "alias stop-all='sudo service prosody stop && sudo service jicofo stop && sudo service jitsi-videobridge2 stop && sudo service nginx stop'" >> ${HOME}/.bash_aliases
fi
if [[ ! -n $(awk "/alias allrestart/" ${HOME}/.bash_aliases) ]]; then
    echo "alias restart-all='sudo service prosody restart && sudo service jicofo restart && sudo service jitsi-videobridge2 restart && sudo service nginx restart'" >> ${HOME}/.bash_aliases
fi
# cat ${HOME}/.bash_aliases


echo "-------------------------- Update --------------------------"
sudo apt update


echo "--------------------- Install Prosody ----------------------"
# Prosody 설치
echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -

sudo apt update
sudo apt install -y prosody

sudo chown root:prosody /etc/prosody/certs/localhost.key
sudo chmod 644 /etc/prosody/certs/localhost.key
# cp /etc/prosody/certs/localhost.key /etc/ssl


echo "------------------- Install Jitsi Meet ---------------------"
# Jitsi Meet 설치
sudo apt update
sudo apt install apt-transport-https
sudo apt-add-repository universe
sudo apt update

curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

sudo apt update

# 버전 지정 설치
# 패키지 디펜던시 확인 : sudo apt depends jitsi-meet=2.0.4627-1
sudo apt install -y jicofo=${JICOFO_VERSION}                                    \
                    jitsi-meet-web=${JITSI_MEET_WEB_VERSION}                    \
                    jitsi-meet-web-config=${JITSI_MEET_WEB_CONFIG_VERSION}      \
                    jitsi-meet-prosody=${JITSI_MEET_PROSODY_VERSION}            \
                    jitsi-meet-turnserver=${JITSI_MEET_TURNSERVER_VERSION}      \
                    jitsi-videobridge2=${JITSI_VIDEOBRIDGE_VERSION}

sudo apt install -y jitsi-meet=${JITSI_MEET_VERSION}

## TODO KTH에 설치된 버전을 설정한다.
# sudo apt install -y jicofo=1.0-626-1
# sudo apt install -y jitsi-meet-web=1.0.4370-1
# sudo apt install -y jitsi-meet-web-config=1.0.4370-1
# sudo apt install -y jitsi-meet-prosody=1.0.4370-1
# sudo apt install -y jitsi-meet-turnserver=1.0.4370-1
# sudo apt install -y jitsi-videobridge2=2.1-304-g8488f77d-1

echo "------------------- Setting Virtual Host -------------------"
# Host 등록
if [[ ! -n $(sudo awk "/${IPADDR} ${VHOST}/" /etc/hosts) ]]; then
    echo "${IPADDR} ${VHOST}" | sudo tee -a /etc/hosts > /dev/null
fi


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
sudo luarocks unpack lua-cjson-${LUA_CJSON_VERSION}.src.rock

sudo sed -i 's/lua_objlen/lua_rawlen/g' ${HOME}/src/lua-cjson-${LUA_CJSON_VERSION}/lua-cjson/lua_cjson.c
sudo sed -i 's/5.1/5.2/g' ${HOME}/src/lua-cjson-${LUA_CJSON_VERSION}/lua-cjson/Makefile
sudo sed -i 's|$(PREFIX)/include|/usr/include/lua5.2|g' ${HOME}/src/lua-cjson-${LUA_CJSON_VERSION}/lua-cjson/Makefile

cd ${HOME}/src/lua-cjson-${LUA_CJSON_VERSION}/lua-cjson
sudo luarocks make


# echo "------------------- Install LUAJWTJITSI --------------------"
# cd
# sudo luarocks list
# sudo luarocks install luajwtjitsi


echo "---------------- Install Jitsi Meet Tokens -----------------"
sudo apt install -y jitsi-meet-tokens=${JITSI_MEET_TOKENS_VERSION}


echo "---------------- Setting Turn Server Config ----------------"
# turn server configuration 변경 (/usr/share/jitsi-meet-turnserver , /etc/nginx/modules-enabled)
# /usr/share/jitsi-meet-turnserver/jitsi-meet.conf
# default         turn; --> default web; 으로 변경
sudo sed -i 's/turn;/web;/g' /usr/share/jitsi-meet-turnserver/jitsi-meet.conf
sudo ln -sf /usr/share/jitsi-meet-turnserver/jitsi-meet.conf /etc/nginx/modules-enabled/60-jitsi-meet.conf


echo "------------------ Setting Prosody Config ------------------"
# prosody configuration (/etc/prosody)
sudo sed -i 's/VirtualHost \"localhost\"/-- VirtualHost \"localhost\"/g' /etc/prosody/prosody.cfg.lua
sudo sed -i 's/c2s_require_encryption = true/c2s_require_encryption = false/g' /etc/prosody/prosody.cfg.lua

if [[ ! -n $(sudo awk "/component_interface/" /etc/prosody/prosody.cfg.lua) ]]; then
    echo "component_interface = { \"*\" }" | sudo tee -a /etc/prosody/prosody.cfg.lua > /dev/null
    echo "" | sudo tee -a /etc/prosody/prosody.cfg.lua > /dev/null
fi

sudo sed -i '/Include/d' /etc/prosody/prosody.cfg.lua
echo "Include \"conf.d/*.cfg.lua\"" | sudo tee -a /etc/prosody/prosody.cfg.lua > /dev/null


echo "-------------- Setting Prosody Domain Config ---------------"
# domain prosody configuration (/etc/prosody/conf.avail)
sudo sed -i 's/--plugin_paths = { "\/usr\/share\/jitsi-meet\/prosody-plugins\/" }/plugin_paths = { "\/usr\/share\/jitsi-meet\/prosody-plugins\/" }/g' /etc/prosody/conf.avail/${VHOST}.cfg.lua
sudo sed -i 's/cross_domain_bosh = false;/cross_domain_bosh = true;/g' /etc/prosody/conf.avail/${VHOST}.cfg.lua
sudo sed -i 's/consider_bosh_secure = true;/consider_bosh_secure = false;\n-- asap_accepted_audiences = { "jitsi" }/g' /etc/prosody/conf.avail/${VHOST}.cfg.lua
sudo sed -i 's/authentication = "anonymous"/authentication = "token"/g' /etc/prosody/conf.avail/${VHOST}.cfg.lua
sudo sed -i "s/--app_id=\"example_app_id\"/app_id = \"${TOKEN_APP_ID}\"/g" /etc/prosody/conf.avail/${VHOST}.cfg.lua
sudo sed -i "s/--app_secret=\"example_app_secret\"/app_secret = \"${TOKEN_APP_SECRET}\"/g" /etc/prosody/conf.avail/${VHOST}.cfg.lua
sudo sed -i 's/"bosh";/"bosh";\n            "presence_identity";/g' /etc/prosody/conf.avail/${VHOST}.cfg.lua
# sudo sed -i 's/-- "token_verification";/"token_verification\";\n        \"token_moderation\";\n        \"kthmeet_logging\";/g' /etc/prosody/conf.avail/${VHOST}.cfg.lua
sudo sed -i 's/-- "token_verification";/"token_verification\";/g' /etc/prosody/conf.avail/${VHOST}.cfg.lua
sudo sed -i 's/          "token_verification";/        "token_verification";/g' /etc/prosody/conf.avail/${VHOST}.cfg.lua

if [[ ! -n $(sudo awk "/VirtualHost \"guest.${VHOST}\"/" /etc/prosody/conf.avail/${VHOST}.cfg.lua) ]]; then
    echo "" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
    echo "VirtualHost \"guest.${VHOST}\"" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
    echo "    authentication = \"token\"" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
    echo "    app_id = \"${TOKEN_APP_ID}\"" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
    echo "    app_secret = \"${TOKEN_APP_SECRET}\"" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
    echo "    c2s_require_encryption = false" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
    echo "    allow_empty_token = false" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
fi

# Guest 인증서 추가
sudo prosodyctl cert generate ${VHOST}
sudo ln -sf /var/lib/prosody/${VHOST}.crt /etc/prosody/certs/${VHOST}.crt
sudo ln -sf /var/lib/prosody/${VHOST}.key /etc/prosody/certs/${VHOST}.key


echo "---------------- Setting Domain Config JS ------------------"
# domain config.js configuration (/etc/jitsi/meet)
sudo sed -i 's/p2pTestMode: false/p2pTestMode: false,\n        octo: {\n          probability: 1\n        },\n/g' /etc/jitsi/meet/${VHOST}-config.js
sudo sed -i 's/\/\/ resolution: 720,/resolution: 720,\n    constraints: {\n        video: {\n            aspectRatio: 16 \/ 9,\n            height: {\n                ideal: 720,\n                max: 720,\n                min: 240\n            }\n        }\n    },/g' /etc/jitsi/meet/${VHOST}-config.js
sudo sed -i 's/enableUserRolesBasedOnToken: false/enableUserRolesBasedOnToken: true/g' /etc/jitsi/meet/${VHOST}-config.js
sudo sed -i 's/deploymentInfo: {/deploymentInfo: {\n        shard: \"shard\",\n        region: \"region1\",\n        userRegion: \"region1\"/g' /etc/jitsi/meet/${VHOST}-config.js
sudo sed -i 's/\/\/ disableDeepLinking: false,/disableDeepLinking: true,/g' /etc/jitsi/meet/${VHOST}-config.js


echo "------------------ Setting Jicofo Config -------------------"
#jicofo configuration (/etc/jisti/jicofo)
sudo sed -i "s/JICOFO_HOST=localhost/JICOFO_HOST=${VHOST}/g" /etc/jitsi/jicofo/config

if [[ ! -n $(sudo awk "/org.jitsi.jicofo.ALWAYS_TRUST_MODE_ENABLED/" /etc/jitsi/jicofo/sip-communicator.properties) ]]; then
    echo "org.jitsi.jicofo.ALWAYS_TRUST_MODE_ENABLED=true" | sudo tee -a /etc/jitsi/jicofo/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.jicofo.BridgeSelector.BRIDGE_SELECTION_STRATEGY/" /etc/jitsi/jicofo/sip-communicator.properties) ]]; then
    echo "org.jitsi.jicofo.BridgeSelector.BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy" | sudo tee -a /etc/jitsi/jicofo/sip-communicator.properties > /dev/null
fi


echo "--------------- Setting Video Bridge Config ----------------"
# jvb configuration (/etc/jitsi/videobridge)
sudo sed -i "s/localhost/${VHOST}/g" /etc/jitsi/videobridge/sip-communicator.properties
sudo sed -i "s/org.jitsi.videobridge.xmpp.user.shard.MUC_NICKNAME=.*/org.jitsi.videobridge.xmpp.user.shard.MUC_NICKNAME=${JVBNAME}/g" /etc/jitsi/videobridge/sip-communicator.properties

if [[ ! -n $(sudo awk "/org.jitsi.videobridge.xmpp.user.shard.DISABLE_CERTIFICATE_VERIFICATION/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.jitsi.videobridge.xmpp.user.shard.DISABLE_CERTIFICATE_VERIFICATION=true" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.videobridge.SINGLE_PORT_HARVESTER_PORT/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.jitsi.videobridge.SINGLE_PORT_HARVESTER_PORT=10000" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.videobridge.DISABLE_TCP_HARVESTER/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.jitsi.videobridge.DISABLE_TCP_HARVESTER=true" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.videobridge.octo.BIND_ADDRESS/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.jitsi.videobridge.octo.BIND_ADDRESS=${IPADDR}" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.videobridge.octo.PUBLIC_ADDRESS/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.jitsi.videobridge.octo.PUBLIC_ADDRESS=${IPADDR}" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.videobridge.octo.BIND_PORT/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.jitsi.videobridge.octo.BIND_PORT=4096" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.videobridge.REGION/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.jitsi.videobridge.REGION=region1" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.ice4j.ipv6.DISABLED/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.ice4j.ipv6.DISABLED=true" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi


echo "------------------------- Restart --------------------------"
sudo service prosody            restart
sudo service jicofo             restart
sudo service jitsi-videobridge2 restart
sudo service nginx              restart


echo "--------------------- Check Prosody ------------------------"
dpkg -l prosody


echo "---------------------- Check Jitsi -------------------------"
dpkg -l | grep jicofo


echo "---------------------- Check Jitsi -------------------------"
dpkg -l | grep jitsi


echo "------------------------------------------------------------"
echo "source \${HOME}/.bashrc"
