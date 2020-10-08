#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/config-setting.sh)
#

printf "\e[00;32m---------------- Setting Turn Server Config ----------------\e[00m\n"
# turn server configuration 변경 (/usr/share/jitsi-meet-turnserver , /etc/nginx/modules-enabled)
# /usr/share/jitsi-meet-turnserver/jitsi-meet.conf
# default         turn; --> default web; 으로 변경
sudo sed -i 's/turn;/web;/g' /usr/share/jitsi-meet-turnserver/jitsi-meet.conf
sudo ln -sf /usr/share/jitsi-meet-turnserver/jitsi-meet.conf /etc/nginx/modules-enabled/60-jitsi-meet.conf

printf "\e[00;32m------------------ Setting Prosody Config ------------------\e[00m\n"
# prosody configuration (/etc/prosody)
sudo sed -i 's/VirtualHost \"localhost\"/-- VirtualHost \"localhost\"/g' /etc/prosody/prosody.cfg.lua
sudo sed -i 's/c2s_require_encryption = true/c2s_require_encryption = false/g' /etc/prosody/prosody.cfg.lua

if [[ ! -n $(sudo awk "/component_interface/" /etc/prosody/prosody.cfg.lua) ]]; then
    echo "component_interface = { \"*\" }" | sudo tee -a /etc/prosody/prosody.cfg.lua > /dev/null
    echo "" | sudo tee -a /etc/prosody/prosody.cfg.lua > /dev/null
fi

sudo sed -i '/Include/d' /etc/prosody/prosody.cfg.lua
echo "Include \"conf.d/*.cfg.lua\"" | sudo tee -a /etc/prosody/prosody.cfg.lua > /dev/null

# printf "\e[00;32m----------- Setting Prosody Guest Domain Config ------------\e[00m\n"
# if [[ ! -n $(sudo awk "/VirtualHost \"guest.${VHOST}\"/" /etc/prosody/conf.avail/${VHOST}.cfg.lua) ]]; then
#     echo "" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
#     echo "VirtualHost \"guest.${VHOST}\"" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
#     echo "    authentication = \"token\"" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
#     echo "    app_id = \"${TOKEN_APP_ID}\"" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
#     echo "    app_secret = \"${TOKEN_APP_SECRET}\"" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
#     echo "    c2s_require_encryption = false" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null
#     echo "    allow_empty_token = false" | sudo tee -a /etc/prosody/conf.avail/${VHOST}.cfg.lua > /dev/null

#     # Guest 인증서 추가
#     sudo prosodyctl cert generate ${VHOST}
#     sudo ln -sf /var/lib/prosody/${VHOST}.crt /etc/prosody/certs/${VHOST}.crt
#     sudo ln -sf /var/lib/prosody/${VHOST}.key /etc/prosody/certs/${VHOST}.key

# fi

printf "\e[00;32m----------------- Setting Domain Config JS -----------------\e[00m\n"
# domain config.js configuration (/etc/jitsi/meet)
sudo sed -i 's/p2pTestMode: false/p2pTestMode: false,\n        octo: {\n          probability: 1\n        },\n/g' /etc/jitsi/meet/${VHOST}-config.js
sudo sed -i 's/\/\/ resolution: 720,/resolution: 720,\n    constraints: {\n        video: {\n            aspectRatio: 16 \/ 9,\n            height: {\n                ideal: 720,\n                max: 720,\n                min: 240\n            }\n        }\n    },/g' /etc/jitsi/meet/${VHOST}-config.js
sudo sed -i 's/enableUserRolesBasedOnToken: false/enableUserRolesBasedOnToken: true/g' /etc/jitsi/meet/${VHOST}-config.js
sudo sed -i 's/deploymentInfo: {/deploymentInfo: {\n        shard: \"shard\",\n        region: \"region1\",\n        userRegion: \"region1\"/g' /etc/jitsi/meet/${VHOST}-config.js
sudo sed -i 's/\/\/ disableDeepLinking: false,/disableDeepLinking: true,/g' /etc/jitsi/meet/${VHOST}-config.js

printf "\e[00;32m------------------ Setting Jicofo Config -------------------\e[00m\n"
#jicofo configuration (/etc/jisti/jicofo)
sudo sed -i "s/JICOFO_HOST=localhost/JICOFO_HOST=${VHOST}/g" /etc/jitsi/jicofo/config

if [[ ! -n $(sudo awk "/org.jitsi.jicofo.ALWAYS_TRUST_MODE_ENABLED/" /etc/jitsi/jicofo/sip-communicator.properties) ]]; then
    echo "org.jitsi.jicofo.ALWAYS_TRUST_MODE_ENABLED=true" | sudo tee -a /etc/jitsi/jicofo/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.jicofo.BridgeSelector.BRIDGE_SELECTION_STRATEGY/" /etc/jitsi/jicofo/sip-communicator.properties) ]]; then
    echo "org.jitsi.jicofo.BridgeSelector.BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy" | sudo tee -a /etc/jitsi/jicofo/sip-communicator.properties > /dev/null
fi

printf "\e[00;32m--------------- Setting Video Bridge Config ----------------\e[00m\n"
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
