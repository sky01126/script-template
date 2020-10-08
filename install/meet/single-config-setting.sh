#!/bin/bash
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/single-config-setting.sh)
#

# Could not get lock / Unable to acquire the dpkg 에러 발생
sudo killall apt apt-get
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a

# 대문자 변환
uppercase() {
    echo $* | tr "[a-z]" "[A-Z]"
}

# Exit on error
set -e

printf "\e[00;32m------------------------ TEST START ------------------------\e[00m\n"
export VHOST="meetlocal.kthcorp.com"
export JVBNAME="kthmeet-jvb"
export TOKEN_APP_ID="433D3BF7B0A185DA47330C810934FBFF"
export TOKEN_APP_SECRET="qwer1234"
printf "\e[00;32m------------------------- TEST END -------------------------\e[00m\n"

printf "\e[00;32m------------------- Setting Meet Config --------------------\e[00m\n"
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

# ---------------- Setting Kernel Parameter ------------------
curl -f -L -sS  https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/kernel-setting.sh -o /tmp/kernel-setting.sh
chmod +x /tmp/kernel-setting.sh
/tmp/kernel-setting.sh

printf "\e[00;32m---------------------- Setting Alias -----------------------\e[00m\n"
# alias 설정 추가
if [[ ! -n $(awk "/alias jvb-log/" ${HOME}/.bash_aliases) ]]; then
    echo "alias jvb-log='sudo tail -f /var/log/jitsi/jvb.log'" >> ${HOME}/.bash_aliases
fi
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

printf "\e[00;32m------------------- Setting Virtual Host -------------------\e[00m\n"
# Host 등록
if [[ ! -n $(sudo awk "/${IPADDR} ${VHOST}/" /etc/hosts) ]]; then
    echo "${IPADDR} ${VHOST}" | sudo tee -a /etc/hosts > /dev/null
fi

printf "\e[00;32m----------------- Install Jitsi Meet Token -----------------\e[00m\n"
printf "\e[00;32mEnter whether to install jitsi meet tokens?\e[00m"
read -e -p ' [Y / n](enter)] (default. n) > ' INSTALL_JITSI_MEET_TOKEN
if [[ ! -z ${INSTALL_JITSI_MEET_TOKEN}  ]] && [[ "$(uppercase ${INSTALL_JITSI_MEET_TOKEN})" == "Y" ]]; then
    # ---------------- Install Jitsi Meet Tokens -----------------
    curl -f -L -sS  https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/install-jitsi-meet-token.sh -o /tmp/install-jitsi-meet-token.sh
    chmod +x /tmp/install-jitsi-meet-token.sh
    /tmp/install-jitsi-meet-token.sh

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
fi

# ---------------------- Setting Config ----------------------"
curl -f -L -sS  https://raw.githubusercontent.com/sky01126/script-template/master/install/meet/config-setting.sh -o /tmp/config-setting.sh
chmod +x /tmp/config-setting.sh
/tmp/config-setting.sh

printf "\e[00;32m----------------------- All Restart ------------------------\e[00m\n"
sudo service prosody            restart
sudo service jicofo             restart
sudo service jitsi-videobridge2 restart
sudo service nginx              restart

printf "\e[00;32m---------------------- Check Prosody -----------------------\e[00m\n"
dpkg -l prosody

printf "\e[00;32m----------------------- Check Jitsi ------------------------\e[00m\n"
dpkg -l | grep jicofo

printf "\e[00;32m----------------------- Check Jitsi ------------------------\e[00m\n"
dpkg -l | grep jitsi

printf "\e[00;32m------------------- Delete Install File --------------------\e[00m\n"
rm -rf /tmp/kernel-setting.sh
rm -rf /tmp/install-jitsi-meet-token.sh
rm -rf /tmp/config-setting.sh

