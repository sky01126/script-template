#!/bin/bash

# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/kpms_agent_install.sh)
# Ubuntu에서 실행 : curl -f -L -sS  http://shell.pe.kr/document/install/kpms_agent_install.sh -o /tmp/kpms_agent_install.sh && chmod +x /tmp/kpms_agent_install.sh && sudo /tmp/kpms_agent_install.sh


# ----------------------------------------------------------------------------------------------------------------------
# Exit on error
set -e

# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

unset TMOUT

## OS를 확인한다.
export OS='unknown'
if [[ "$(uname)" == "Darwin" ]]; then
    OS="darwin"
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    OS="linux"
fi


# ----------------------------------------------------------------------------------------------------------------------
# .bashrc 경로 설정.
export BASH_FILE=${HOME}/.bashrc
source ${BASH_FILE}


# ----------------------------------------------------------------------------------------------------------------------
if [[ "$(uname)" == "Linux" ]] && [[ "$USER" != "root" ]]; then
    printf "\e[00;31mKPMS Agent 설치 스크립트는 ROOT 권한으로 실행하십시오.\e[00m\n"
    exit 1
fi


# ----------------------------------------------------------------------------------------------------------------------
# 대문자 변환
uppercase() {
    echo $* | tr "[a-z]" "[A-Z]"
}

# 소문자변환
lowercase() {
    echo $* | tr "[A-Z]" "[a-z]"
}


# ----------------------------------------------------------------------------------------------------------------------
# File Extension
EXTENSION='.tar.gz'


# ----------------------------------------------------------------------------------------------------------------------
SRC_HOME="${HOME}/src"
SERVER_HOME=${SERVER_HOME}
PROGRAME_HOME="opt/local"

DEFAULT_SERVER_HOME="/home/server"
if [[ "${OS}" == "darwin" ]]; then
    DEFAULT_SERVER_HOME=${HOME}/server
fi

if [[ ! -z "${SERVER_HOME}" ]]; then
    DEFAULT_SERVER_HOME=${SERVER_HOME}
fi

KPMS_ALIAS="kpms-agent"
KPMS_PROCESS_NAME="kpms.Agent"

KPMS_VERSION='1.0.0'
KPMS_DOWNLOAD_URL="http://211.113.13.116/api/kpms/program/download/${KPMS_ALIAS}-${KPMS_VERSION}.tar.gz"

KPMS_NAME=${KPMS_DOWNLOAD_URL##+(*/)}
KPMS_HOME=${KPMS_NAME%$EXTENSION}

KPMS_START_USER="root"


# ----------------------------------------------------------------------------------------------------------------------
# KPMS Agent 설치 확인.
if [[ -d "${DEFAULT_SERVER_HOME}/${PROGRAME_HOME}/${KPMS_HOME}" ]]; then
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m|\e[00m \e[00;31m기존에 설치된 KPMS Agent가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${KPMS_HOME}\" service\e[00m\n"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${KPMS_HOME}\" service?\e[00m"
    read -e -p ' [Y / n] > ' INSTALL_CHECK
    if [[ -z "${INSTALL_CHECK}" ]]; then
        INSTALL_CHECK="n"
    fi

    if [[ "$(uppercase ${INSTALL_CHECK})" != "Y" ]]; then
        printf "\e[00;32m|\e[00m \e[00;31m\"${KPMS_HOME}\" 설치 취소...\e[00m\n"
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        exit 1
    fi
fi


# ----------------------------------------------------------------------------------------------------------------------
# 프로세스 정보 확인.
server_pid() {
    echo `ps aux | grep -v grep | grep ${KPMS_PROCESS_NAME} | awk '{ print \$2 }'`
}


# ----------------------------------------------------------------------------------------------------------------------
# 기존에 실행되는 프로세스가 존재하면 KILL 한다.
PIDS=$(server_pid)
if [[ ! -z "${PIDS}" ]]; then
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m|\e[00m \e[00;31mKill process.\e[00m (PID: \e[00;32m${PIDS}\e[00m)\n"
    kill -9 ${PIDS}
    sleep 2
fi


# ----------------------------------------------------------------------------------------------------------------------
# Server home 설정.
if [[ -z "${SERVER_HOME}" ]]; then
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter the server home path (default. ${DEFAULT_SERVER_HOME})\e[00m"
    read -e -p " > " SERVER_HOME
    if [[ -z "${SERVER_HOME}" ]]; then
        SERVER_HOME=${DEFAULT_SERVER_HOME}
    fi
fi


# ----------------------------------------------------------------------------------------------------------------------
# 디렉토리 생성 / 삭제
mkdir -p ${SRC_HOME}
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}

# delete the previous home
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${KPMS_HOME}" ]]; then
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| \"${KPMS_HOME}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${KPMS_HOME}
fi
if [[ -d "${SERVER_HOME}/${KPMS_ALIAS}" || -L "${SERVER_HOME}/${KPMS_ALIAS}" ]]; then
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| \"${KPMS_ALIAS}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${KPMS_ALIAS}
fi

cd ${SRC_HOME}

# verify that the source exists download
if [[ -f "${SRC_HOME}/${KPMS_NAME}" ]]; then
    rm -rf ${SRC_HOME}/${KPMS_NAME}
fi

printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${KPMS_NAME}\" download (URL : ${KPMS_DOWNLOAD_URL})\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
curl -L -O ${KPMS_DOWNLOAD_URL}
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"

tar xvzf ${KPMS_NAME} -C ${SERVER_HOME}/${PROGRAME_HOME}/

cd ${SERVER_HOME}
ln -s ./${PROGRAME_HOME}/${KPMS_HOME} ${KPMS_ALIAS}


# ----------------------------------------------------------------------------------------------------------------------
# SERVER_HOME이 설정되어있는지 확인 후 설징이 없으면 생성한다.
if [[ -f ${BASH_FILE} ]]; then
    SET_SERVER_HOME=`awk "/export SERVER_HOME/" ${BASH_FILE}`
    if [[ ! -n ${SET_SERVER_HOME} ]]; then
        printf "\e[00;32m| Setting server home path...\e[00m\n"

        echo "# Server Home
export SERVER_HOME=\"${SERVER_HOME}\"
" >> ${BASH_FILE}

        source ${BASH_FILE}
    fi
fi


# ----------------------------------------------------------------------------------------------------------------------
if [[ -f "/etc/centos-release" ]]; then
    OSINFO=`cat /etc/centos-release`
elif [[ -f "/etc/oracle-release" ]]; then
    OSINFO=`cat /etc/oracle-release`
elif [[ -f "/etc/redhat-release" ]]; then
    OSINFO=`cat /etc/redhat-release`
elif [[ -f "/etc/issue.net" ]]; then
    OSINFO=`cat /etc/issue.net`
else
    OSINFO="UNKNOWN"
fi


# ----------------------------------------------------------------------------------------------------------------------
if [[ "${OS}" == "linux" ]]; then
    # 자동 실행 스크립트 생성 확인.
    if [[ -f "/usr/bin/systemctl" ]] || [[ -f "/bin/systemctl" ]]; then
        if [[ -z `systemctl list-unit-files | awk '{ print $1 }' | grep -x ${KPMS_ALIAS}.service` ]]; then
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
            printf "\e[00;32m| ${OSINFO} : Add system service...\e[00m\n"
            printf "\e[00;32m|\e[00m "

            echo "[Unit]
Description=KPMS Agent
After=network.target

[Service]
Type=forking
User=root
ExecStart=${SERVER_HOME}/${KPMS_ALIAS}/bin/start.sh
ExecStop=${SERVER_HOME}/${KPMS_ALIAS}/bin/stop.sh

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/${KPMS_ALIAS}.service

            # systemctl disable kpms-agent && rm -rf /etc/systemd/system/kpms-agent.service && systemctl reset-failed
            # systemctl list-unit-files | grep kpms-agent

            systemctl enable ${KPMS_ALIAS}
        fi
    else # CentOS 6
        if [[ -z `chkconfig --list | awk '{ print $1 }' | grep -x ${KPMS_ALIAS}` ]]; then
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
            printf "\e[00;32m| ${OSINFO} Add chkconfig...\e[00m\n"
            echo "#!/bin/sh
#
# ${KPMS_ALIAS}      Start up the KPMS server daemon
#
# chkconfig: 2345 98 98
# description: KPMS server.

su - ${KPMS_START_USER} -c \"${SERVER_HOME}/${KPMS_ALIAS}/bin/${KPMS_ALIAS}.sh \$1\"
" > /etc/init.d/${KPMS_ALIAS}

            chmod +x /etc/init.d/${KPMS_ALIAS}

            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
            ls -al /etc/init.d/${KPMS_ALIAS}
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
            cat /etc/init.d/${KPMS_ALIAS}

            # 서비스 등록
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
            chkconfig --add ${KPMS_ALIAS}
            chkconfig ${KPMS_ALIAS} on
            chkconfig --list | grep ${KPMS_ALIAS}
        fi
    fi
fi

printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m|\e[00m "
${SERVER_HOME}/${KPMS_ALIAS}/bin/start.sh
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"


# ----------------------------------------------------------------------------------------------------------------------
# Source 삭제.
rm -rf ${SRC_HOME}/${KPMS_NAME}
