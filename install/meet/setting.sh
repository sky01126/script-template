#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/setting.sh)
#

# 테스트
VHOST="meetlocal.kthcorp.com"
JVBNAME="meetdev01"
TOKEN_APP_ID="kthmeet"
TOKEN_APP_SECRET="kthmeet"


echo "----- Setting Meet Config"
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
    printf "Enter the token app id (eg. kthmeet)"
    read -e -p " > " TOKEN_APP_ID
    while [[ -z ${TOKEN_APP_ID} ]]; do
        printf "Enter the token app id (eg. kthmeet)"
        read -e -p " > " TOKEN_APP_ID
    done
fi

if [[ -z ${TOKEN_APP_SECRET} ]]; then
    printf "Enter the token app secret (eg. kthmeet)"
    read -e -p " > " TOKEN_APP_SECRET
    while [[ -z ${TOKEN_APP_SECRET} ]]; do
        printf "Enter the token app secret (eg. kthmeet)"
        read -e -p " > " TOKEN_APP_SECRET
    done
fi

DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo VHOME=${VHOST}, IP=${IPADDR}, JVB=${JVBNAME}, APP_ID=${TOKEN_APP_ID}, APP_SECRET=${TOKEN_APP_SECRET}, ${DATE}


echo "-----Setting Virtual Host"
# Host 등록
if [[ ! -n $(sudo awk "/${IPADDR} ${VHOST}/" /etc/hosts) ]]; then
    echo "${IPADDR} ${VHOST}" | sudo tee -a /etc/hosts > /dev/null
fi


echo "----- Setting Turn Server Config"
# turn server configuration 변경 (/usr/share/jitsi-meet-turnserver , /etc/nginx/modules-enabled)
# /usr/share/jitsi-meet-turnserver/jitsi-meet.conf
# default         turn; --> default web; 으로 변경
sudo sed -i 's/turn;/web;/g' /usr/share/jitsi-meet-turnserver/jitsi-meet.conf
sudo ln -sf /usr/share/jitsi-meet-turnserver/jitsi-meet.conf /etc/nginx/modules-enabled/60-jitsi-meet.conf


echo "----- Setting Prosody Config"
# prosody configuration (/etc/prosody)
sudo sed -i 's/VirtualHost \"localhost\"/-- VirtualHost \"localhost\"/g' /etc/prosody/prosody.cfg.lua
sudo sed -i 's/c2s_require_encryption = true/c2s_require_encryption = false/g' /etc/prosody/prosody.cfg.lua
# echo "Include \"conf.d/*.cfg.lua\"" >> /etc/prosody/prosody.cfg.lua


echo "----- Setting Prosody Domain Config"
# domain prosody configuration (/etc/prosody/conf.avail)
sudo sed -i 's/cross_domain_bosh = false;/cross_domain_bosh = true;/g' /etc/prosody/conf.avail/$VHOST.cfg.lua
sudo sed -i 's/consider_bosh_secure = true;/consider_bosh_secure = false;\n-- asap_accepted_audiences = { "jitsi" }/g' /etc/prosody/conf.avail/$VHOST.cfg.lua
sudo sed -i 's/authentication = "anonymous"/authentication = "token"/g' /etc/prosody/conf.avail/$VHOST.cfg.lua
sudo sed -i "s/--app_id=\"example_app_id\"/app_id = \"$TOKEN_APP_ID\"/g" /etc/prosody/conf.avail/$VHOST.cfg.lua
sudo sed -i "s/--app_secret=\"example_app_secret\"/app_secret = \"$TOKEN_APP_SECRET\"/g" /etc/prosody/conf.avail/$VHOST.cfg.lua
sudo sed -i 's/"bosh";/"bosh";\n            "presence_identity";/g' /etc/prosody/conf.avail/$VHOST.cfg.lua
sudo sed -i 's/-- "token_verification";/"token_verification\";\n        \"token_moderation\";\n        \"kthmeet_logging\";/g' /etc/prosody/conf.avail/$VHOST.cfg.lua

if [[ ! -n $(sudo awk "/VirtualHost \"guest.$VHOST\"/" /etc/prosody/conf.avail/$VHOST.cfg.lua) ]]; then
    echo "VirtualHost \"guest.$VHOST\"" | sudo tee -a /etc/prosody/conf.avail/$VHOST.cfg.lua > /dev/null
    echo "    authentication = \"token\"" | sudo tee -a /etc/prosody/conf.avail/$VHOST.cfg.lua > /dev/null
    echo "    app_id = \"$TOKEN_APP_ID\"" | sudo tee -a /etc/prosody/conf.avail/$VHOST.cfg.lua > /dev/null
    echo "    app_secret = \"$TOKEN_APP_SECRET\"" | sudo tee -a /etc/prosody/conf.avail/$VHOST.cfg.lua > /dev/null
    echo "    c2s_require_encryption = false" | sudo tee -a /etc/prosody/conf.avail/$VHOST.cfg.lua > /dev/null
    echo "    allow_empty_token = false" | sudo tee -a /etc/prosody/conf.avail/$VHOST.cfg.lua > /dev/null
fi

echo "----- Setting Domain Config JS"
# domain config.js configuration (/etc/jitsi/meet)
sudo sed -i 's/p2pTestMode: false/p2pTestMode: false,\n        octo: {\n          probability: 1\n        },\n/g' /etc/jitsi/meet/$VHOST-config.js
sudo sed -i 's/\/\/ resolution: 720,/resolution: 720,\n    constraints: {\n        video: {\n            aspectRatio: 16 \/ 9,\n            height: {\n                ideal: 720,\n                max: 720,\n                min: 240\n            }\n        }\n    },/g' /etc/jitsi/meet/$VHOST-config.js
sudo sed -i 's/enableUserRolesBasedOnToken: false/enableUserRolesBasedOnToken: true/g' /etc/jitsi/meet/$VHOST-config.js
sudo sed -i 's/deploymentInfo: {/deploymentInfo: {\n        shard: \"shard\",\n        region: \"region1\",\n        userRegion: \"region1\"/g' /etc/jitsi/meet/$VHOST-config.js
sudo sed -i 's/\/\/ disableDeepLinking: false,/disableDeepLinking: true,/g' /etc/jitsi/meet/$VHOST-config.js


echo "----- Setting Jicofo Config"
#jicofo configuration (/etc/jisti/jicofo)
sudo sed -i "s/JICOFO_HOST=localhost/JICOFO_HOST=$VHOST/g" /etc/jitsi/jicofo/config

if [[ ! -n $(sudo awk "/org.jitsi.jicofo.ALWAYS_TRUST_MODE_ENABLED/" /etc/jitsi/jicofo/sip-communicator.properties) ]]; then
    echo "org.jitsi.jicofo.ALWAYS_TRUST_MODE_ENABLED=true" | sudo tee -a /etc/jitsi/jicofo/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.jicofo.BridgeSelector.BRIDGE_SELECTION_STRATEGY/" /etc/jitsi/jicofo/sip-communicator.properties) ]]; then
    echo "org.jitsi.jicofo.BridgeSelector.BRIDGE_SELECTION_STRATEGY=SplitBridgeSelectionStrategy" | sudo tee -a /etc/jitsi/jicofo/sip-communicator.properties > /dev/null
fi

echo "----- Setting Video Bridge Config"
# jvb configuration (/etc/jitsi/videobridge)
sudo sed -i "s/localhost/$VHOST/g" /etc/jitsi/videobridge/sip-communicator.properties
sudo sed -i "s/org.jitsi.videobridge.xmpp.user.shard.MUC_NICKNAME=.*/org.jitsi.videobridge.xmpp.user.shard.MUC_NICKNAME=$JVBNAME/g" /etc/jitsi/videobridge/sip-communicator.properties

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
    echo "org.jitsi.videobridge.octo.BIND_ADDRESS=$IPADDR" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
fi
if [[ ! -n $(sudo awk "/org.jitsi.videobridge.octo.PUBLIC_ADDRESS/" /etc/jitsi/videobridge/sip-communicator.properties) ]]; then
    echo "org.jitsi.videobridge.octo.PUBLIC_ADDRESS=$IPADDR" | sudo tee -a /etc/jitsi/videobridge/sip-communicator.properties > /dev/null
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
