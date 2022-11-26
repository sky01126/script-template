#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#           Q            /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/haproxy_install.sh)


# ----------------------------------------------------------------------------------------------------------------------
# Exit on error
set -e

# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

## OS를 확인한다.
export OS='unknown'
if [[ "$(uname)" == "Darwin" ]]; then
    OS="darwin"
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    OS="linux"
fi

unset TMOUT


# ----------------------------------------------------------------------------------------------------------------------
PRG="$0"
while [[ -h "$PRG" ]]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)\$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`/"$link"
    fi
done

# Get standard environment variables
PRGDIR=`dirname "\$PRG"`


# ----------------------------------------------------------------------------------------------------------------------
# 멀티의 setting.sh 읽기
if [[ ! -f "${PRGDIR}/library/setting.sh" ]]; then
    curl -f -L -sS  http://shell.pe.kr/document/install/library/setting.sh -o /tmp/setting.sh
    source /tmp/setting.sh
    bash   /tmp/setting.sh
else
    source ${PRGDIR}/library/setting.sh
    bash   ${PRGDIR}/library/setting.sh
fi


# ----------------------------------------------------------------------------------------------------------------------
# HAProxy
HAPROXY_ALIAS='haproxy'

HAPROXY_VERSION="1.8.14"
HAPROXY_DOWNLOAD_URL="http://www.haproxy.org/download/1.8/src/haproxy-${HAPROXY_VERSION}.tar.gz"
HAPROXY_NAME=${HAPROXY_DOWNLOAD_URL##+(*/)}
HAPROXY_HOME=${HAPROXY_NAME%$EXTENSION}


# ----------------------------------------------------------------------------------------------------------------------
# Apache Tomcat Connector
MOD_JK_VERSION="1.2.42"
MOD_JK_DOWNLOAD_URL="http://archive.apache.org/dist/tomcat/tomcat-connectors/jk/tomcat-connectors-${MOD_JK_VERSION}-src.tar.gz"


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+----------------+--------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME       |\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME    |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| HAPROXY_HOME   |\e[00m ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}\n"
printf "\e[00;32m| HAPROXY_ALIAS  |\e[00m ${SERVER_HOME}/${HAPROXY_ALIAS}\n"
printf "\e[00;32m+----------------+--------------------------------------------------------\e[00m\n"


# ----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}" ]]; then
    printf "\e[00;32m|\e[00m \e[00;31m기존에 설치된 Apache가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${HAPROXY_HOME}\" service\e[00m"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${HAPROXY_HOME}\" service?\e[00m"
    read -e -p ' [Y / n] > ' INSTALL_CHECK
    if [[ -z "${INSTALL_CHECK}" ]]; then
        INSTALL_CHECK="n"
    fi

    if [[ "$(uppercase ${INSTALL_CHECK})" != "Y" ]]; then
        printf "\e[00;32m|\e[00m \e[00;31m\"${HAPROXY_HOME}\" 설치 취소...\e[00m\n"
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        exit 1
    fi
fi


# ----------------------------------------------------------------------------------------------------------------------
# OpenSSL 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}" ]]; then
    if [[ ! -f "${PRGDIR}/library/openssl.sh" ]]; then
        curl -f -L -sS  http://shell.pe.kr/document/install/library/openssl.sh -o /tmp/openssl.sh
        bash   /tmp/openssl.sh
    else
        bash  ${PRGDIR}/library/openssl.sh
    fi
elif [[ ! -d "${SERVER_HOME}/${OPENSSL_ALIAS}" || ! -L "${SERVER_HOME}/${OPENSSL_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${OPENSSL_HOME} ${OPENSSL_ALIAS}
fi


# ----------------------------------------------------------------------------------------------------------------------
cd ${SRC_HOME}

# delete the compile source
if [[ -d "${SRC_HOME}/${HAPROXY_HOME}" ]]; then
    printf "\e[00;32m| \"${SRC_HOME}/${HAPROXY_HOME}\" delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${HAPROXY_HOME}
fi

printf "\e[00;32m| \"${HAPROXY_HOME}\" install start...\e[00m\n"

# delete the previous home
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}" ]]; then
    printf "\e[00;32m| \"${HAPROXY_HOME}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}
fi
if [[ -d "${SERVER_HOME}/${HAPROXY_ALIAS}" || -L "${SERVER_HOME}/${HAPROXY_ALIAS}" ]]; then
    printf "\e[00;32m| \"${HAPROXY_ALIAS}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${HAPROXY_ALIAS}
fi

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${HAPROXY_NAME}" ]; then
    printf "\e[00;32m| \"${HAPROXY_NAME}\" download (URL : ${HAPROXY_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${HAPROXY_DOWNLOAD_URL}
fi

tar xvzf ${HAPROXY_NAME}
cd ${SRC_HOME}/${HAPROXY_HOME}

INSTALL_CONFIG="${INSTALL_CONFIG} TARGET=linux2628"
INSTALL_CONFIG="${INSTALL_CONFIG} ARCH=native"
INSTALL_CONFIG="${INSTALL_CONFIG} USE_OPENSSL=1"
INSTALL_CONFIG="${INSTALL_CONFIG} SSL_INC=${SERVER_HOME}/${OPENSSL_ALIAS}/include"
INSTALL_CONFIG="${INSTALL_CONFIG} SSL_LIB=${SERVER_HOME}/${OPENSSL_ALIAS}/lib"

make ${INSTALL_CONFIG}
make DESTDIR="${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}" PREFIX="" install

cd ${SERVER_HOME}
ln -s ./${PROGRAME_HOME}/${HAPROXY_HOME} ${HAPROXY_ALIAS}

# Install source delete
if [[ -d "${SRC_HOME}/${HAPROXY_HOME}" ]]; then
    printf "\e[00;32m| \"${SRC_HOME}/${HAPROXY_HOME}\" delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${HAPROXY_HOME}
fi

printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${HAPROXY_HOME}\" install success...\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
sleep 0.5


# ----------------------------------------------------------------------------------------------------------------------
## HTTPD 서버에서 필요없는 디렉토리 삭제.
#rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/build
#rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/cgi-bin
#rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/error
#rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/htdocs
#rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/icons
#rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/man
#rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/manual
#
## 필요 디렉토리 생성.
#mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/conf/extra/uriworkermaps
#mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/conf/extra/vhosts
#mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/logs/archive
#mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HAPROXY_HOME}/work



# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${HAPROXY_ALIAS}\" install success...\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"


