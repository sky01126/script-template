#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/apache24_install.sh)
#
# - 상용 리눅스
#   yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#   yum install -y libnghttp2
#
# - 개발 리눅스
#   yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#   yum install -y libnghttp2 libnghttp2-devel
#
# - 참조 사이트
#   mod_ratelimit : http://elkha.kr/xe/misc/166663
#                   https://httpd.apache.org/docs/trunk/mod/mod_ratelimit.html
#   mod_cache : https://httpd.apache.org/docs/2.4/ko/mod/mod_cache.html
#   아파치 성능향상 : https://httpd.apache.org/docs/2.4/misc/perf-tuning.html
#
# - SSL 1.1.1 사용 시 아래 2개 파일 복사
#   cp /home/server/openssl/lib/libssl.so.1.1 /usr/lib64/
#   cp /home/server/openssl/lib/libcrypto.so.1.1 /usr/lib64/
#
# - [2022.01.04] 보안 업데이트 - Apache HTTP Server 2.4.51 및 이전 버전
#   Apache HTTP Server에서 널 포인터 역참조로 인해 발생하는 서비스거부 취약점(CVE-2021-44224)
#   Apache HTTP Server에서 입력값 검증이 미흡하여 발생하는 버퍼오버플로우 취약점(CVE-2021-44790)

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
while [[ -L "$PRG" ]]; do
    ls=$(ls -ld "$PRG")
    link=$(expr "$ls" : '.*-> \(.*\)$')
    if expr "$link" : '/.*' >/dev/null; then
        PRG="$link"
    else
        PRG=$(dirname "$PRG")/"$link"
    fi
done

# Get standard environment variables
PRGDIR=$(dirname "$PRG")

# ----------------------------------------------------------------------------------------------------------------------
# 멀티의 setting.sh 읽기
if [[ ! -f "${PRGDIR}/library/setting.sh" ]]; then
    rm -rf /tmp/setting.sh

    curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/library/setting.sh -o /tmp/setting.sh
    source /tmp/setting.sh
else
    source ${PRGDIR}/library/setting.sh
fi

# ----------------------------------------------------------------------------------------------------------------------
# Apache 2.4
HTTPD_ALIAS='httpd'

HTTPD_VERSION="2.4.54"
HTTPD_DOWNLOAD_URL="http://archive.apache.org/dist/httpd/httpd-${HTTPD_VERSION}.tar.gz"
HTTPD_NAME=${HTTPD_DOWNLOAD_URL##+(*/)}
HTTPD_HOME=${HTTPD_NAME%$EXTENSION}

# ----------------------------------------------------------------------------------------------------------------------
# Apache Tomcat Connector
MOD_JK_VERSION="1.2.48"
MOD_JK_DOWNLOAD_URL="http://archive.apache.org/dist/tomcat/tomcat-connectors/jk/tomcat-connectors-${MOD_JK_VERSION}-src.tar.gz"

# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+--------------+----------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME     |\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME  |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| HTTPD_HOME   |\e[00m ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}\n"
printf "\e[00;32m| HTTPD_ALIAS  |\e[00m ${SERVER_HOME}/${HTTPD_ALIAS}\n"
printf "\e[00;32m+--------------+------------------------------------------------------------------\e[00m\n"

# ----------------------------------------------------------------------------------------------------------------------
# PCRE2 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${PCRE2_HOME}" ]]; then
    if [[ ! -f "${PRGDIR}/library/pcre2.sh" ]]; then
        rm -rf /tmp/pcre2.sh

        curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/library/pcre2.sh -o /tmp/pcre2.sh
        bash /tmp/pcre2.sh
    else
        bash ${PRGDIR}/library/pcre2.sh
    fi
elif [[ -n "${PCRE2_ALIAS}" ]] && [[ ! -d "${SERVER_HOME}/${PCRE2_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${PCRE2_HOME} ${PCRE2_ALIAS}
fi

# ----------------------------------------------------------------------------------------------------------------------
# OpenSSL 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}" ]]; then
    if [[ ! -f "${PRGDIR}/library/openssl.sh" ]]; then
        rm -rf /tmp/openssl.sh

        curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/library/openssl.sh -o /tmp/openssl.sh
        bash /tmp/openssl.sh
    else
        bash ${PRGDIR}/library/openssl.sh
    fi
elif [[ -n "${OPENSSL_ALIAS}" ]] && [[ ! -d "${SERVER_HOME}/${OPENSSL_ALIAS}" || ! -L "${SERVER_HOME}/${OPENSSL_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${OPENSSL_HOME} ${OPENSSL_ALIAS}
fi

# ----------------------------------------------------------------------------------------------------------------------
# APR / APR Util 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${APR_HOME}" ]]; then
    if [[ ! -f "${PRGDIR}/library/apr.sh" ]]; then
        rm -rf /tmp/apr.sh

        curl -f -L -sS https://raw.githubusercontent.com/sky01126/script-template/master/install/library/apr.sh -o /tmp/apr.sh
        bash /tmp/apr.sh
    else
        bash ${PRGDIR}/library/apr.sh
    fi
elif [[ -n "${APR_ALIAS}" ]] && [[ ! -d "${SERVER_HOME}/${APR_ALIAS}" || ! -L "${SERVER_HOME}/${APR_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${APR_HOME} ${APR_ALIAS}
fi

# ----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}" ]]; then
    printf "\e[00;32m|\e[00m \e[00;31m기존에 설치된 Apache가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${HTTPD_HOME}\" service\e[00m\n"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${HTTPD_HOME}\" service?\e[00m"
    read -e -p ' [Y / n] > ' INSTALL_CHECK
    if [[ -z "${INSTALL_CHECK}" ]]; then
        INSTALL_CHECK="n"
    fi

    if [[ "$(uppercase ${INSTALL_CHECK})" != "Y" ]]; then
        printf "\e[00;32m|\e[00m \e[00;31m\"${HTTPD_HOME}\" 설치 취소...\e[00m\n"
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        exit 1
    fi
fi

# ----------------------------------------------------------------------------------------------------------------------
# Domain Name 설정.
if [[ -z "${DOMAIN_NAME}" ]]; then
    printf "\e[00;32m| Enter the domain name\e[00m"
    read -e -p " > " DOMAIN_NAME
    while [[ -z ${DOMAIN_NAME} ]]; do
        printf "\e[00;32m| Enter the domain name\e[00m"
        read -e -p " > " DOMAIN_NAME
    done
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
fi

cd ${SRC_HOME}

# delete the compile source
if [[ -d "${SRC_HOME}/${HTTPD_HOME}" ]]; then
    printf "\e[00;32m| \"${SRC_HOME}/${HTTPD_HOME}\" delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${HTTPD_HOME}
fi

printf "\e[00;32m| \"${HTTPD_HOME}\" install start...\e[00m\n"

# delete the previous home
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}" ]]; then
    printf "\e[00;32m| \"${HTTPD_HOME}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}
fi
if [[ -d "${SERVER_HOME}/${HTTPD_ALIAS}" || -L "${SERVER_HOME}/${HTTPD_ALIAS}" ]]; then
    printf "\e[00;32m| \"${HTTPD_ALIAS}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${HTTPD_ALIAS}
fi

# verify that the source exists download
if [[ ! -f "${SRC_HOME}/${HTTPD_NAME}" ]]; then
    printf "\e[00;32m| \"${HTTPD_NAME}\" download (URL : ${HTTPD_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${HTTPD_DOWNLOAD_URL}
fi

tar xvzf ${HTTPD_NAME}
cd ${SRC_HOME}/${HTTPD_HOME}

## 특정라인 변경.
if [[ "$OS" == "linux" ]]; then
    sed -i "75s/.*/#define DEFAULT_SERVER_LIMIT 1024/g" ${SRC_HOME}/${HTTPD_HOME}/server/mpm/prefork/prefork.c

    # ServerLimit과 ThreadsPerChild 값을 변경한다. 서버의 스팩에 따라서 적절하게 수정한다.
    sed -i "87s/.*/#define DEFAULT_SERVER_LIMIT 128/g" ${SRC_HOME}/${HTTPD_HOME}/server/mpm/worker/worker.c

    # ServerLimit과 ThreadsPerChild 값을 변경한다. 서버의 스팩에 따라서 적절하게 수정한다.
    sed -i "115s/.*/#define DEFAULT_SERVER_LIMIT 128/g" ${SRC_HOME}/${HTTPD_HOME}/server/mpm/event/event.c
fi

INSTALL_CONFIG="--prefix=${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-cache"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-cache-disk"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-deflate"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-expires"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-file-cache"
#INSTALL_CONFIG="${INSTALL_CONFIG} --enable-headers"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-http2"
#INSTALL_CONFIG="${INSTALL_CONFIG} --enable-mem-cache"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-mime-magic"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-module=ssl"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-mods-shared=most"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-mpms-shared=all"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-proxy"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-proxy-ajp"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-proxy-http2"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-proxy-balancer"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-proxy-wstunnel"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-rewrite"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-so"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-ssl"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-mpm=event"

if [[ -z ${APR_HOME} ]]; then
    INSTALL_CONFIG="${INSTALL_CONFIG} --with-apr=${SERVER_HOME}/${PROGRAME_HOME}/${APR_HOME}"
    INSTALL_CONFIG="${INSTALL_CONFIG} --with-apr-util=${SERVER_HOME}/${PROGRAME_HOME}/${APR_HOME}"
else
    INSTALL_CONFIG="${INSTALL_CONFIG} --with-apr=${SERVER_HOME}/${APR_ALIAS}"
    INSTALL_CONFIG="${INSTALL_CONFIG} --with-apr-util=${SERVER_HOME}/${APR_ALIAS}"
fi

if [[ -z ${PCRE2_HOME} ]]; then
    INSTALL_CONFIG="${INSTALL_CONFIG} --with-pcre=${SERVER_HOME}/${PROGRAME_HOME}/${PCRE2_HOME}/bin/pcre2-config"
else
    INSTALL_CONFIG="${INSTALL_CONFIG} --with-pcre=${SERVER_HOME}/${PCRE2_ALIAS}/bin/pcre2-config"
fi

if [[ -z ${OPENSSL_HOME} ]]; then
    INSTALL_CONFIG="${INSTALL_CONFIG} --with-ssl=${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}"
else
    INSTALL_CONFIG="${INSTALL_CONFIG} --with-ssl=${SERVER_HOME}/${OPENSSL_ALIAS}"
fi

./configure ${INSTALL_CONFIG}
make
make install

cd ${SERVER_HOME}
ln -s ./${PROGRAME_HOME}/${HTTPD_HOME} ${HTTPD_ALIAS}

printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${HTTPD_HOME}\" install success...\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
sleep 0.5

# Apache Tomcat Connector 설치
printf "\e[00;32m| Apache Tomcat Connector install start...\e[00m\n"

MOD_JK_NAME="${MOD_JK_DOWNLOAD_URL##+(*/)}"
MOD_JK_HOME="${MOD_JK_NAME%$EXTENSION}"

cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${MOD_JK_NAME}" ]; then
    printf "\e[00;32m| \"${MOD_JK_NAME}\" download (URL : ${MOD_JK_DOWNLOAD_URL})\e[00m\n"
    curl -L -O "${MOD_JK_DOWNLOAD_URL}"
fi

tar xvzf ${MOD_JK_NAME}
cd ${SRC_HOME}/${MOD_JK_HOME}/native

./configure --with-apxs=${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/bin/apxs
make
make install

cp -rf apache-2.0/mod_jk.so ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/modules/

# Install source delete
if [[ -d "${SRC_HOME}/${MOD_JK_HOME}" ]]; then
    printf "\e[00;32m| \"${SRC_HOME}/${MOD_JK_HOME}\" delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${MOD_JK_HOME}
fi

# Install source delete
if [[ -d "${SRC_HOME}/${HTTPD_HOME}" ]]; then
    printf "\e[00;32m| \"${SRC_HOME}/${HTTPD_HOME}\" delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${HTTPD_HOME}
fi

# HTTPD 서버에서 필요없는 디렉토리 삭제.
# rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/build
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/cgi-bin
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/error
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/htdocs
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/icons
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/man
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/manual

# 필요 디렉토리 생성.
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/conf/extra/uriworkermaps
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/conf/extra/sites-enabled
##mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/logs/archive
#mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/logs/archive
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/work

# ----------------------------------------------------------------------------------------------------------------------
## Tomcat Worker Name 설정.
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m|   ______                           __  \e[00m\n"
printf "\e[00;32m|  /_  __/___  ____ ___  _________ _/ /_ \e[00m\n"
printf "\e[00;32m|   / / / __ \/ __  __ \/ ___/ __  / __/ \e[00m\n"
printf "\e[00;32m|  / / / /_/ / / / / / / /__/ /_/ / /_   \e[00m\n"
printf "\e[00;32m| /_/  \____/_/ /_/ /_/\___/\__,_/\__/   \e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
if [[ -z ${INSTALL_WORKER_NAME} ]]; then
    printf "\e[00;32m| Enter the JK Connecter name\e[00m"
    read -e -p ' (default. default) > ' INSTALL_WORKER_NAME
    if [[ -z ${CHECK_TOMCAT} ]]; then
        INSTALL_WORKER_NAME="default"
    fi
fi

# ----------------------------------------------------------------------------------------------------------------------
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     ___                     __
#    /   |  ____  ____ ______/ /_  ___
#   / /| | / __ \\/ __ \`/ ___/ __ \\/ _ \\
#  / ___ |/ /_/ / /_/ / /__/ / / /  __/
# /_/  |_/ .___/\\__,_/\\___/_/ /_/\\___/
#       /_/
#  :: Apache ::              (v${HTTPD_VERSION})

printf \"\e[00;32m     ___                     __         \e[00m\\\\n\"
printf \"\e[00;32m    /   |  ____  ____ ______/ /_  ___   \e[00m\\\\n\"
printf \"\e[00;32m   / /| | / __ \\\\/ __ \\\`/ ___/ __ \\\\/ _ \\\\  \e[00m\\\\n\"
printf \"\e[00;32m  / ___ |/ /_/ / /_/ / /__/ / / /  __/  \e[00m\\\\n\"
printf \"\e[00;32m /_/  |_/ .___/\\\\__,_/\\\\___/_/ /_/\\\\___/   \e[00m\\\\n\"
printf \"\e[00;32m       /_/                              \e[00m\\\\n\"
printf \"\e[00;32m  :: Apache ::              (v${HTTPD_VERSION})   \e[00m\\\\n\"
echo

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# HTTPD_HOME is the location of the configuration files of this instance of nginx
export HTTPD_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

\$HTTPD_HOME/bin/apachectl start

if [[ ! -f \"${SERVER_HOME}/${HTTPD_ALIAS}/work/httpd.pid\" ]]; then
    printf \"httpd 시작 중:\"

    sleep 0.5
    retval=\$?
    if [[ \$retval = 0 ]]; then
        printf \"                                           [  \e[00;32mOK\e[00m  ]\\\\n\"
    else
        printf \"                                           [\e[00;32mFAILED\e[00m]\\\\n\"
    fi
fi

" >${SERVER_HOME}/${HTTPD_ALIAS}/bin/start.sh

# ----------------------------------------------------------------------------------------------------------------------
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     ___                     __
#    /   |  ____  ____ ______/ /_  ___
#   / /| | / __ \\/ __ \`/ ___/ __ \\/ _ \\
#  / ___ |/ /_/ / /_/ / /__/ / / /  __/
# /_/  |_/ .___/\\__,_/\\___/_/ /_/\\___/
#       /_/
#  :: Apache ::              (v${HTTPD_VERSION})

printf \"\e[00;32m     ___                     __         \e[00m\\\\n\"
printf \"\e[00;32m    /   |  ____  ____ ______/ /_  ___   \e[00m\\\\n\"
printf \"\e[00;32m   / /| | / __ \\\\/ __ \\\`/ ___/ __ \\\\/ _ \\\\  \e[00m\\\\n\"
printf \"\e[00;32m  / ___ |/ /_/ / /_/ / /__/ / / /  __/  \e[00m\\\\n\"
printf \"\e[00;32m /_/  |_/ .___/\\\\__,_/\\\\___/_/ /_/\\\\___/   \e[00m\\\\n\"
printf \"\e[00;32m       /_/                              \e[00m\\\\n\"
printf \"\e[00;32m  :: Apache ::              (v${HTTPD_VERSION})   \e[00m\\\\n\"
echo

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# HTTPD_HOME is the location of the configuration files of this instance of nginx
export HTTPD_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

STOPD=
if [[ -f \"${SERVER_HOME}/${HTTPD_ALIAS}/work/httpd.pid\" ]]; then
    STOPD='true'
fi

\$HTTPD_HOME/bin/apachectl stop

if [[ -n \"\$STOPD\" ]]; then
    printf \"httpd 중지 중:\"

    sleep 0.5
    retval=\$?
    if [[ \$retval = 0 ]]; then
        printf \"                                           [  \e[00;32mOK\e[00m  ]\\\\n\"
    else
        printf \"                                           [\e[00;32mFAILED\e[00m]\\\\n\"
    fi
fi
" >${SERVER_HOME}/${HTTPD_ALIAS}/bin/stop.sh

# ----------------------------------------------------------------------------------------------------------------------
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     ___                     __
#    /   |  ____  ____ ______/ /_  ___
#   / /| | / __ \\/ __ \`/ ___/ __ \\/ _ \\
#  / ___ |/ /_/ / /_/ / /__/ / / /  __/
# /_/  |_/ .___/\\__,_/\\___/_/ /_/\\___/
#       /_/
#  :: Apache ::              (v${HTTPD_VERSION})

printf \"\e[00;32m     ___                     __         \e[00m\\\\n\"
printf \"\e[00;32m    /   |  ____  ____ ______/ /_  ___   \e[00m\\\\n\"
printf \"\e[00;32m   / /| | / __ \\\\/ __ \\\`/ ___/ __ \\\\/ _ \\\\  \e[00m\\\\n\"
printf \"\e[00;32m  / ___ |/ /_/ / /_/ / /__/ / / /  __/  \e[00m\\\\n\"
printf \"\e[00;32m /_/  |_/ .___/\\\\__,_/\\\\___/_/ /_/\\\\___/   \e[00m\\\\n\"
printf \"\e[00;32m       /_/                              \e[00m\\\\n\"
printf \"\e[00;32m  :: Apache ::              (v${HTTPD_VERSION})   \e[00m\\\\n\"
echo

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# HTTPD_HOME is the location of the configuration files of this instance of nginx
export HTTPD_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

STOPD=
if [[ -f \"${SERVER_HOME}/${HTTPD_ALIAS}/work/httpd.pid\" ]]; then
    STOPD='true'
fi

\$HTTPD_HOME/bin/apachectl restart

if [[ -n \"\$STOPD\" ]]; then
    printf \"httpd 재시작 중:\"

    sleep 0.5
    retval=\$?
    if [[ \$retval = 0 ]]; then
        printf \"                                           [  \e[00;32mOK\e[00m  ]\\\\n\"
    else
        printf \"                                           [\e[00;32mFAILED\e[00m]\\\\n\"
    fi
else
    printf \"httpd 시작 중:\"

    sleep 0.5
    retval=\$?
    if [[ \$retval = 0 ]]; then
        printf \"                                           [  \e[00;32mOK\e[00m  ]\\\\n\"
    else
        printf \"                                           [\e[00;32mFAILED\e[00m]\\\\n\"
    fi
fi
" >${SERVER_HOME}/${HTTPD_ALIAS}/bin/restart.sh

# ----------------------------------------------------------------------------------------------------------------------
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     ___                     __
#    /   |  ____  ____ ______/ /_  ___
#   / /| | / __ \\/ __ \`/ ___/ __ \\/ _ \\
#  / ___ |/ /_/ / /_/ / /__/ / / /  __/
# /_/  |_/ .___/\\__,_/\\___/_/ /_/\\___/
#       /_/
#  :: Apache ::              (v${HTTPD_VERSION})

printf \" \e[00;32m     ___                     __         \e[00m\\\\n\"
printf \" \e[00;32m    /   |  ____  ____ ______/ /_  ___   \e[00m\\\\n\"
printf \" \e[00;32m   / /| | / __ \\\\/ __ \\\`/ ___/ __ \\\\/ _ \\\\  \e[00m\\\\n\"
printf \" \e[00;32m  / ___ |/ /_/ / /_/ / /__/ / / /  __/  \e[00m\\\\n\"
printf \" \e[00;32m /_/  |_/ .___/\\\\__,_/\\\\___/_/ /_/\\\\___/   \e[00m\\\\n\"
printf \" \e[00;32m       /_/                              \e[00m\\\\n\"
printf \" \e[00;32m  :: Apache ::              (v${HTTPD_VERSION})   \e[00m\\\\n\"
echo

server_pid() {
    echo \`ps aux | grep httpd | grep -v grep | grep -v status | grep -v rotatelogs | awk '{print \$2}'\`
}

if [[ -n \"\$(server_pid)\" ]]; then
    pid=\`cat ${SERVER_HOME}/${HTTPD_ALIAS}/work/httpd.pid\`
    echo \"httpd (pid \$pid) is running.\"
    exit 0
else
    echo \"httpd (no pid file) not running.\"
    exit 1
fi
" >${SERVER_HOME}/${HTTPD_ALIAS}/bin/status.sh

# ----------------------------------------------------------------------------------------------------------------------
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     ___                     __
#    /   |  ____  ____ ______/ /_  ___
#   / /| | / __ \\/ __ \`/ ___/ __ \\/ _ \\
#  / ___ |/ /_/ / /_/ / /__/ / / /  __/
# /_/  |_/ .___/\\__,_/\\___/_/ /_/\\___/
#       /_/
#  :: Apache ::              (v${HTTPD_VERSION})

printf \" \e[00;32m     ___                     __         \e[00m\\\\n\"
printf \" \e[00;32m    /   |  ____  ____ ______/ /_  ___   \e[00m\\\\n\"
printf \" \e[00;32m   / /| | / __ \\\\/ __ \\\`/ ___/ __ \\\\/ _ \\\\  \e[00m\\\\n\"
printf \" \e[00;32m  / ___ |/ /_/ / /_/ / /__/ / / /  __/  \e[00m\\\\n\"
printf \" \e[00;32m /_/  |_/ .___/\\\\__,_/\\\\___/_/ /_/\\\\___/   \e[00m\\\\n\"
printf \" \e[00;32m       /_/                              \e[00m\\\\n\"
printf \" \e[00;32m  :: Apache ::              (v${HTTPD_VERSION})   \e[00m\\\\n\"
echo

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# HTTPD_HOME is the location of the configuration files of this instance of nginx
export HTTPD_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

\$HTTPD_HOME/bin/apachectl configtest
" >${SERVER_HOME}/${HTTPD_ALIAS}/bin/configtest.sh

# ----------------------------------------------------------------------------------------------------------------------
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     ___                     __
#    /   |  ____  ____ ______/ /_  ___
#   / /| | / __ \\/ __ \`/ ___/ __ \\/ _ \\
#  / ___ |/ /_/ / /_/ / /__/ / / /  __/
# /_/  |_/ .___/\\__,_/\\___/_/ /_/\\___/
#       /_/
#  :: Apache ::              (v${HTTPD_VERSION})

printf \" \e[00;32m     ___                     __         \e[00m\\\\n\"
printf \" \e[00;32m    /   |  ____  ____ ______/ /_  ___   \e[00m\\\\n\"
printf \" \e[00;32m   / /| | / __ \\\\/ __ \\\`/ ___/ __ \\\\/ _ \\\\  \e[00m\\\\n\"
printf \" \e[00;32m  / ___ |/ /_/ / /_/ / /__/ / / /  __/  \e[00m\\\\n\"
printf \" \e[00;32m /_/  |_/ .___/\\\\__,_/\\\\___/_/ /_/\\\\___/   \e[00m\\\\n\"
printf \" \e[00;32m       /_/                              \e[00m\\\\n\"
printf \" \e[00;32m  :: Apache ::              (v${HTTPD_VERSION})   \e[00m\\\\n\"
echo

server_pid() {
    echo \`ps aux | grep httpd | grep -v grep | grep -v status | grep -v rotatelogs | awk '{print \$2}'\`
}

if [[ -n \"\$(server_pid)\" ]]; then
    # Apache에서 실행되는 전체 Thread 숫자를 조회한다.
    PROCESS_IDS=''
    for pid in \`ps aux | grep httpd | grep ${USERNAME} | grep -v grep | grep -v status | grep -v rotatelogs | awk '{print \$2}'\`; do
        PROCESS_IDS+=\"\${pid} \"
    done
    #printf \" \e[00;32m|\e[00m ps hH p \${PROCESS_IDS} | wc -l\"
    #echo

    printf \"Total thread count running on httpd: \e[00;32m\`ps hH p \${PROCESS_IDS} | wc -l\`\e[00m\\\\n\"
    exit 0
else
    echo \"httpd (no pid file) not running.\"
    exit 1
fi
" >${SERVER_HOME}/${HTTPD_ALIAS}/bin/check-run-thread.sh

# ----------------------------------------------------------------------------------------------------------------------
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     ___                     __
#    /   |  ____  ____ ______/ /_  ___
#   / /| | / __ \/ __ \`/ ___/ __ \/ _ \
#  / ___ |/ /_/ / /_/ / /__/ / / /  __/
# /_/  |_/ .___/\__,_/\___/_/ /_/\___/
#       /_/
#  :: Apache ::              (v${HTTPD_VERSION})
#
# ------------------------------------------------------------------------------
# Exit on error
set -e

# ------------------------------------------------------------------------------
# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# ------------------------------------------------------------------------------
# 현재 사용자의 아이디명과 그룹정보
USERNAME=\`id -u -n\`
GROUPNAME=\`id -g -n\`

# ------------------------------------------------------------------------------
# check-run-thread.sh
sed -i \"s/for pid in.*/for pid in \`ps aux | grep httpd | grep \${USERNAME} | grep -v grep | grep -v status | grep -v rotatelogs | awk '{print \$2}'\`; do/g\" \${PRGDIR}/bin/check-run-thread.sh

# ------------------------------------------------------------------------------
# delete-log.sh
sed -i \"s/USER=.*/USER=\${USERNAME}/g\"       \${PRGDIR}/bin/*.sh
sed -i \"s/GROUP=.*/GROUP=\${GROUPNAME}/g\"    \${PRGDIR}/bin/*.sh

# ------------------------------------------------------------------------------
# Apache Config 수정.
sed -i \"s/User.*/User \${USERNAME}/g\"        \${PRGDIR}/conf/httpd.conf
sed -i \"s/Group.*/Group \${GROUPNAME}/g\"     \${PRGDIR}/conf/httpd.conf
" >${SERVER_HOME}/${HTTPD_ALIAS}/bin/change-user.sh

# ----------------------------------------------------------------------------------------------------------------------
echo "#!/bin/bash
# ------------------------------------------------------------------------------
#     ___                     __
#    /   |  ____  ____ ______/ /_  ___
#   / /| | / __ \\/ __ \`/ ___/ __ \\/ _ \\
#  / ___ |/ /_/ / /_/ / /__/ / / /  __/
# /_/  |_/ .___/\\__,_/\\___/_/ /_/\\___/
#       /_/
#  :: Apache ::              (v${HTTPD_VERSION})

#-----------------------------------------------
# 시스템에 맞게 계정과 그룹을 변경한다.
#-----------------------------------------------
USER=${USERNAME}
GROUP=${GROUPNAME}

# crontab 에 등록
# 10 0 * * * ${SERVER_HOME}/${HTTPD_ALIAS}/bin/delete-log.sh

# 파일 경로와 파일명 분리.
MAX_HISTORYS='30'
# FILE_PATH='${SERVER_HOME}/${HTTPD_ALIAS}/logs/archive'
FILE_PATH='${SERVER_HOME}/${HTTPD_ALIAS}/logs'
FILE_NAME=\`basename \"\${FILE_PATH}\"\`
EXTENSION='${EXTENSION}'

DELETE_LOG_NAME=\"delete-\$(date -d \"1 day ago\" +\"%Y-%m\").log\"

# 백업 디렉토리 생성 및 사용자, 그룹을 변경.
if [[ ! -d \"\${FILE_PATH}\" ]]; then
    mkdir -p \${FILE_PATH}
    chown -R \${USER}:\${GROUP} \${FILE_PATH}
fi

echo \"-----------------------------------------------------------------------------------------------------------------\" | tee -a \${FILE_PATH}/\${DELETE_LOG_NAME}
echo \"- 파일 삭제 : \$(date +\"%Y:%m:%d %H-%M-%S\")\" | tee -a \${FILE_PATH}/\${DELETE_LOG_NAME}

# 파일의 디렉토리로 이동.
pushd \${FILE_PATH} > /dev/null

# 보관주기가 지난 백업 파일은 삭제한다.
OLD_BACKUP_FILES=\`find . -mtime +\$((MAX_HISTORYS - 1)) -name \"*\${EXTENSION}\" -type f\`
if [[ -n \${OLD_BACKUP_FILES} ]]; then
    rm -rf \${OLD_BACKUP_FILES}
    echo \"  . 로그 파일 삭제 : \${OLD_BACKUP_FILES}\" | tee -a \${FILE_PATH}/\${DELETE_LOG_NAME}
else
    echo \"  . 삭제 대상 로그 파일이 없습니다.\" | tee -a \${FILE_PATH}/\${DELETE_LOG_NAME}
fi

chown \${USER}:\${GROUP} \${FILE_PATH}/\${DELETE_LOG_NAME}
" >${SERVER_HOME}/${HTTPD_ALIAS}/bin/delete-log.sh

# ----------------------------------------------------------------------------------------------------------------------
chmod +x ${SERVER_HOME}/${HTTPD_ALIAS}/bin/*.sh

# ----------------------------------------------------------------------------------------------------------------------
# Apache Config 수정.
echo "#
# This is the main Apache HTTP server configuration file.  It contains the
# configuration directives that give the server its instructions.
# See <URL:http://httpd.apache.org/docs/2.4/> for detailed information.
# In particular, see
# <URL:http://httpd.apache.org/docs/2.4/mod/directives.html>
# for a discussion of each configuration directive.
#
# Do NOT simply read the instructions in here without understanding
# what they do.  They're here only as hints or reminders.  If you are unsure
# consult the online docs. You have been warned.
#
# Configuration and logfile names: If the filenames you specify for many
# of the server's control files begin with \"/\" (or \"drive:/\" for Win32), the
# server will use that explicit path.  If the filenames do *not* begin
# with \"/\", the value of ServerRoot is prepended -- so \"logs/access_log\"
# with ServerRoot set to \"/usr/local/apache2\" will be interpreted by the
# server as \"/usr/local/apache2/logs/access_log\", whereas \"/logs/access_log\"
# will be interpreted as '/logs/access_log'.

#
# ServerRoot: The top of the directory tree under which the server's
# configuration, error, and log files are kept.
#
# Do not add a slash at the end of the directory path.  If you point
# ServerRoot at a non-local disk, be sure to specify a local disk on the
# Mutex directive, if file-based mutexes are used.  If you wish to share the
# same ServerRoot for multiple httpd daemons, you will need to change at
# least PidFile.
#
ServerRoot \"${SERVER_HOME}/${HTTPD_ALIAS}\"

#
# Mutex: Allows you to set the mutex mechanism and mutex file directory
# for individual mutexes, or change the global defaults
#
# Uncomment and change the directory if mutexes are file-based and the default
# mutex file directory is not on a local disk or is not appropriate for some
# other reason.
#
# Mutex default:logs

#
# Listen: Allows you to bind Apache to specific IP addresses and/or
# ports, instead of the default. See also the <VirtualHost>
# directive.
#
# Change this to Listen on specific IP addresses as shown below to
# prevent Apache from glomming onto all bound IP addresses.
#
#Listen 12.34.56.78:80
Listen 80

#
# Dynamic Shared Object (DSO) Support
#
# To be able to use the functionality of a module which was built as a DSO you
# have to place corresponding \`LoadModule' lines at this location so the
# directives contained in it are actually available _before_ they are used.
# Statically compiled modules (those listed by \`httpd -l') do not need

# to be loaded here.
#
# Example:
# LoadModule foo_module modules/mod_foo.so
#
LoadModule mpm_event_module modules/mod_mpm_event.so
#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
#LoadModule mpm_worker_module modules/mod_mpm_worker.so
LoadModule authn_file_module modules/mod_authn_file.so
#LoadModule authn_dbm_module modules/mod_authn_dbm.so
#LoadModule authn_anon_module modules/mod_authn_anon.so
#LoadModule authn_dbd_module modules/mod_authn_dbd.so
#LoadModule authn_socache_module modules/mod_authn_socache.so
LoadModule authn_core_module modules/mod_authn_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_user_module modules/mod_authz_user.so
#LoadModule authz_dbm_module modules/mod_authz_dbm.so
#LoadModule authz_owner_module modules/mod_authz_owner.so
#LoadModule authz_dbd_module modules/mod_authz_dbd.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule access_compat_module modules/mod_access_compat.so
LoadModule auth_basic_module modules/mod_auth_basic.so
#LoadModule auth_form_module modules/mod_auth_form.so
#LoadModule auth_digest_module modules/mod_auth_digest.so
#LoadModule allowmethods_module modules/mod_allowmethods.so
#LoadModule file_cache_module modules/mod_file_cache.so
#LoadModule cache_module modules/mod_cache.so
#LoadModule cache_disk_module modules/mod_cache_disk.so
#LoadModule cache_socache_module modules/mod_cache_socache.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
#LoadModule socache_dbm_module modules/mod_socache_dbm.so
#LoadModule socache_memcache_module modules/mod_socache_memcache.so
#LoadModule watchdog_module modules/mod_watchdog.so
#LoadModule macro_module modules/mod_macro.so
#LoadModule dbd_module modules/mod_dbd.so
#LoadModule dumpio_module modules/mod_dumpio.so
#LoadModule buffer_module modules/mod_buffer.so
#LoadModule ratelimit_module modules/mod_ratelimit.so
LoadModule reqtimeout_module modules/mod_reqtimeout.so
#LoadModule ext_filter_module modules/mod_ext_filter.so
#LoadModule request_module modules/mod_request.so
#LoadModule include_module modules/mod_include.so
LoadModule filter_module modules/mod_filter.so
#LoadModule substitute_module modules/mod_substitute.so
#LoadModule sed_module modules/mod_sed.so
LoadModule deflate_module modules/mod_deflate.so
LoadModule mime_module modules/mod_mime.so
LoadModule log_config_module modules/mod_log_config.so
#LoadModule log_debug_module modules/mod_log_debug.so
#LoadModule logio_module modules/mod_logio.so
LoadModule env_module modules/mod_env.so
#LoadModule mime_magic_module modules/mod_mime_magic.so
#LoadModule expires_module modules/mod_expires.so
LoadModule headers_module modules/mod_headers.so
#LoadModule unique_id_module modules/mod_unique_id.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule version_module modules/mod_version.so
#LoadModule remoteip_module modules/mod_remoteip.so
#LoadModule proxy_module modules/mod_proxy.so
#LoadModule proxy_connect_module modules/mod_proxy_connect.so
#LoadModule proxy_ftp_module modules/mod_proxy_ftp.so
#LoadModule proxy_http_module modules/mod_proxy_http.so
#LoadModule proxy_http2_module modules/mod_proxy_http2.so
#LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
#LoadModule proxy_scgi_module modules/mod_proxy_scgi.so
#LoadModule proxy_fdpass_module modules/mod_proxy_fdpass.so
#LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
#LoadModule proxy_ajp_module modules/mod_proxy_ajp.so
#LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
#LoadModule proxy_express_module modules/mod_proxy_express.so
#LoadModule proxy_hcheck_module modules/mod_proxy_hcheck.so
#LoadModule session_module modules/mod_session.so
#LoadModule session_cookie_module modules/mod_session_cookie.so
#LoadModule session_dbd_module modules/mod_session_dbd.so
#LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
#LoadModule ssl_module modules/mod_ssl.so
#LoadModule http2_module modules/mod_http2.so
#LoadModule lbmethod_byrequests_module modules/mod_lbmethod_byrequests.so
#LoadModule lbmethod_bytraffic_module modules/mod_lbmethod_bytraffic.so
#LoadModule lbmethod_bybusyness_module modules/mod_lbmethod_bybusyness.so
#LoadModule lbmethod_heartbeat_module modules/mod_lbmethod_heartbeat.so
LoadModule unixd_module modules/mod_unixd.so
#LoadModule dav_module modules/mod_dav.so
LoadModule status_module modules/mod_status.so
LoadModule autoindex_module modules/mod_autoindex.so
#LoadModule info_module modules/mod_info.so
#LoadModule cgid_module modules/mod_cgid.so
#LoadModule dav_fs_module modules/mod_dav_fs.so
#LoadModule vhost_alias_module modules/mod_vhost_alias.so
#LoadModule negotiation_module modules/mod_negotiation.so
LoadModule dir_module modules/mod_dir.so
#LoadModule actions_module modules/mod_actions.so
#LoadModule speling_module modules/mod_speling.so
#LoadModule userdir_module modules/mod_userdir.so
LoadModule alias_module modules/mod_alias.so
LoadModule rewrite_module modules/mod_rewrite.so

<IfModule unixd_module>
#
# If you wish httpd to run as a different user or group, you must run
# httpd as root initially and it will switch.
#
# User/Group: The name (or #number) of the user/group to run httpd as.
# It is usually good practice to create a dedicated user and group for
# running httpd, as with most system services.
#
User ${USERNAME}
Group ${GROUPNAME}

</IfModule>

# 'Main' server configuration
#
# The directives in this section set up the values used by the 'main'
# server, which responds to any requests that aren't handled by a
# <VirtualHost> definition.  These values also provide defaults for
# any <VirtualHost> containers you may define later in the file.
#
# All of these directives may appear inside <VirtualHost> containers,
# in which case these default settings will be overridden for the
# virtual host being defined.
#

#
# ServerAdmin: Your address, where problems with the server should be
# e-mailed.  This address appears on some server-generated pages, such
# as error documents.  e.g. admin@your-domain.com
#
ServerAdmin admin@kt.com

#
# ServerName gives the name and port that the server uses to identify itself.
# This can often be determined automatically, but we recommend you specify
# it explicitly to prevent problems during startup.
#
# If your host doesn't have a registered DNS name, enter its IP address here.
#
ServerName ${DOMAIN_NAME}:80

#
# Deny access to the entirety of your server's filesystem. You must
# explicitly permit access to web content directories in other
# <Directory> blocks below.
#
<Directory />
    AllowOverride none
    Require all denied

    # This directive specifies the number of bytes from 0 (meaning unlimited) to 2147483647 (2GB) that are allowed in a request body.
    # See the note below for the limited applicability to proxy requests.
    LimitRequestBody 2147483647
</Directory>

#
# Note that from this point forward you must specifically allow
# particular features to be enabled - so if something's not working as
# you might expect, make sure that you have specifically enabled it
# below.
#

#
# DocumentRoot: The directory out of which you will serve your
# documents. By default, all requests are taken from this directory, but
# symbolic links and aliases may be used to point to other locations.
#
#DocumentRoot \"${SERVER_HOME}/${HTTPD_ALIAS}/htdocs\"
#<Directory \"${SERVER_HOME}/${HTTPD_ALIAS}/htdocs\">
#    #
#    # Possible values for the Options directive are \"None\", \"All\",
#    # or any combination of:
#    #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
#    #
#    # Note that \"MultiViews\" must be named *explicitly* --- \"Options All\"
#    # doesn't give it to you.
#    #
#    # The Options directive is both complicated and important.  Please see
#    # http://httpd.apache.org/docs/2.4/mod/core.html#options
#    # for more information.
#    #
#    Options Indexes FollowSymLinks
#
#    #
#    # AllowOverride controls what directives may be placed in .htaccess files.
#    # It can be \"All\", \"None\", or any combination of the keywords:
#    #   AllowOverride FileInfo AuthConfig Limit
#    #
#    AllowOverride None
#
#    #
#    # Controls who can get stuff from this server.
#    #
#    Require all granted
#</Directory>

#
# DirectoryIndex: sets the file that Apache will serve if a directory
# is requested.
#
<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

#
# The following lines prevent .htaccess and .htpasswd files from being
# viewed by Web clients.
#
<Files \".ht*\">
    Require all denied
</Files>

#
# ErrorLog: The location of the error log file.
# If you do not specify an ErrorLog directive within a <VirtualHost>
# container, error messages relating to that virtual host will be
# logged here.  If you *do* define an error logfile for a <VirtualHost>
# container, that host's errors will be logged there and not here.
#
# ErrorLog \"|${SERVER_HOME}/${HTTPD_ALIAS}/bin/rotatelogs -L logs/error.log logs/archive/error.%Y-%m-%d.log 86400 +540\"
ErrorLog \"|${SERVER_HOME}/${HTTPD_ALIAS}/bin/rotatelogs logs/error.%Y-%m-%d.log 86400 +540\"

#
# LogLevel: Control the number of messages logged to the error_log.
# Possible values include: debug, info, notice, warn, error, crit,
# alert, emerg.
#
LogLevel warn

<IfModule log_config_module>
    #
    # The following directives define some format nicknames for use with
    # a CustomLog directive (see below).
    #
    SetEnvIf REQUEST_URI \"favicon.ico\" do_not_log
    LogFormat \"%h %l %u %t \\\"%{Host}i\\\" \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" TIME:%T\" combined
    # LogFormat \"%h %{NS-CLIENT-IP}i %l %u %t \\\"%{Host}i\\\" \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" TIME:%T\" combined

    #<IfModule logio_module>
    #  # You need to enable mod_logio.c to use %I and %O
    #  LogFormat \"%h %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" %I %O\" combinedio
    #</IfModule>

    #
    # The location and format of the access logfile (Common Logfile Format).
    # If you do not define any access logfiles within a <VirtualHost>
    # container, they will be logged here.  Contrariwise, if you *do*
    # define per-<VirtualHost> access logfiles, transactions will be
    # logged therein and *not* in this file.
    #
    # CustomLog \"logs/access_log\" common
    CustomLog \"|${SERVER_HOME}/${HTTPD_ALIAS}/bin/rotatelogs logs/access.%Y-%m-%d.log 86400 +540\" combined env=!do_not_log
    # CustomLog \"|${SERVER_HOME}/${HTTPD_ALIAS}/bin/rotatelogs -L logs/access.log logs/archive/access.%Y-%m-%d.log 86400 +540\" combined env=!do_not_log

    #
    # If you prefer a logfile with access, agent, and referer information
    # (Combined Logfile Format) you can use the following directive.
    #
    #CustomLog \"logs/access_log\" combined
</IfModule>

<IfModule alias_module>
    #
    # Redirect: Allows you to tell clients about documents that used to
    # exist in your server's namespace, but do not anymore. The client
    # will make a new request for the document at its new location.
    # Example:
    # Redirect permanent /foo http://www.example.com/bar

    #
    # Alias: Maps web paths into filesystem paths and is used to
    # access content that does not live under the DocumentRoot.
    # Example:
    # Alias /webpath /full/filesystem/path
    #
    # If you include a trailing / on /webpath then the server will
    # require it to be present in the URL.  You will also likely
    # need to provide a <Directory> section to allow access to
    # the filesystem path.

    #
    # ScriptAlias: This controls which directories contain server scripts.
    # ScriptAliases are essentially the same as Aliases, except that
    # documents in the target directory are treated as applications and
    # run by the server when requested rather than as documents sent to the
    # client.  The same rules about trailing \"/\" apply to ScriptAlias
    # directives as to Alias.
    #
    #ScriptAlias /cgi-bin/ \"${SERVER_HOME}/${HTTPD_ALIAS}/cgi-bin/\"
</IfModule>

<IfModule cgid_module>
    #
    # ScriptSock: On threaded servers, designate the path to the UNIX
    # socket used to communicate with the CGI daemon of mod_cgid.
    #
    #Scriptsock cgisock
</IfModule>

#
# \"${SERVER_HOME}/${HTTPD_ALIAS}/cgi-bin\" should be changed to whatever your ScriptAliased
# CGI directory exists, if you have that configured.
#
#<Directory \"${SERVER_HOME}/${HTTPD_ALIAS}/cgi-bin\">
#    AllowOverride None
#    Options None
#    Require all granted
#</Directory>

<IfModule headers_module>
    #
    # Avoid passing HTTP_PROXY environment to CGI's on this or any proxied
    # backend servers which have lingering \"httpoxy\" defects.
    # 'Proxy' request header is undefined by the IETF, not listed by IANA
    #
    RequestHeader unset Proxy early
</IfModule>

<IfModule mime_module>
    #
    # TypesConfig points to the file containing the list of mappings from
    # filename extension to MIME-type.
    #
    TypesConfig conf/mime.types

    #
    # AddType allows you to add to or override the MIME configuration
    # file specified in TypesConfig for specific file types.
    #
    #AddType application/x-gzip .tgz
    #
    # AddEncoding allows you to have certain browsers uncompress
    # information on the fly. Note: Not all browsers support this.
    #
    #AddEncoding x-compress .Z
    #AddEncoding x-gzip .gz .tgz
    #
    # If the AddEncoding directives above are commented-out, then you
    # probably should define those extensions to indicate media types:
    #
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz

    #
    # AddHandler allows you to map certain file extensions to \"handlers\":
    # actions unrelated to filetype. These can be either built into the server
    # or added with the Action directive (see below)
    #
    # To use CGI scripts outside of ScriptAliased directories:
    # (You will also need to add \"ExecCGI\" to the \"Options\" directive.)
    #
    #AddHandler cgi-script .cgi

    # For type maps (negotiated resources):
    #AddHandler type-map var

    #
    # Filters allow you to process content before it is sent to the client.
    #
    # To parse .shtml files for server-side includes (SSI):
    # (You will also need to add \"Includes\" to the \"Options\" directive.)
    #
    #AddType text/html .shtml
    #AddOutputFilter INCLUDES .shtml
</IfModule>

#
# The mod_mime_magic module allows the server to use various hints from the
# contents of the file itself to determine its type.  The MIMEMagicFile
# directive tells the module where the hint definitions are located.
#
#MIMEMagicFile conf/magic

#
# Customizable error responses come in three flavors:
# 1) plain text 2) local redirects 3) external redirects
#
# Some examples:
#ErrorDocument 500 \"The server made a boo boo.\"
#ErrorDocument 404 /missing.html
#ErrorDocument 404 \"/cgi-bin/missing_handler.pl\"
#ErrorDocument 402 http://www.example.com/subscription_info.html
#
ErrorDocument 400 /error/400
ErrorDocument 402 /error/402
ErrorDocument 403 /error/403
ErrorDocument 404 /error/404
ErrorDocument 500 /error/500

#
# MaxRanges: Maximum number of Ranges in a request before
# returning the entire resource, or one of the special
# values 'default', 'none' or 'unlimited'.
# Default setting is to accept 200 Ranges.
#MaxRanges unlimited

#
# EnableMMAP and EnableSendfile: On systems that support it,
# memory-mapping or the sendfile syscall may be used to deliver
# files.  This usually improves server performance, but must
# be turned off when serving from networked-mounted
# filesystems or if support for these functions is otherwise
# broken on your system.
# Defaults: EnableMMAP On, EnableSendfile Off
#
#EnableMMAP off
#EnableSendfile on

# Supplemental configuration
#
# The configuration files in the conf/extra/ directory can be
# included to add extra features or to modify the default configuration of
# the server, or you may simply copy their contents here and change as
# necessary.

# Server-pool management (MPM specific)
Include conf/extra/httpd-mpm.conf

# Multi-language error messages
#Include conf/extra/httpd-multilang-errordoc.conf

# Fancy directory listings
#Include conf/extra/httpd-autoindex.conf

# Language settings
#Include conf/extra/httpd-languages.conf

# User home directories
#Include conf/extra/httpd-userdir.conf

# Real-time info on requests and configuration
#Include conf/extra/httpd-info.conf

# Virtual hosts
Include conf/extra/httpd-vhosts.conf

# Local access to the Apache HTTP Server Manual
#Include conf/extra/httpd-manual.conf

# Distributed authoring and versioning (WebDAV)
#Include conf/extra/httpd-dav.conf

# Various default settings
Include conf/extra/httpd-default.conf

# Configure mod_proxy_html to understand HTML4/XHTML1
<IfModule proxy_html_module>
    Include conf/extra/proxy-html.conf
</IfModule>

# Secure (SSL/TLS) connections
#Include conf/extra/httpd-ssl.conf
#
# Note: The following must must be present to support
#       starting without SSL on platforms with no /dev/random equivalent
#       but a statically compiled-in mod_ssl.
#
<IfModule ssl_module>
    SSLRandomSeed startup builtin
    SSLRandomSeed connect builtin
</IfModule>

# PID File Path setting
PidFile work/httpd.pid

# Apache Tomcat JK Connect setting
Include conf/extra/httpd-jk.conf

# mod_deflate 설정
<IfModule mod_deflate>
    # 특별한 MIME type만 압축
    AddOutputFilterByType DEFLATE text/plain text/html text/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml application/xml application/rss+xml
    AddOutputFilterByType DEFLATE text/css application/javascript application/x-javascript
    #AddOutputFilterByType DEFLATE audio/midi

    # 압축률을 지정 : 1(min) ~ 9(max)
    DeflateCompressionLevel 9

    # Netscape 4.x에 문제가 있다...
    BrowserMatch ^Mozilla/4 gzip-only-text/html

    # Netscape 4.06-4.08에 더 문제가 있다
    BrowserMatch ^Mozilla/4\\.0[678] no-gzip

    # MSIE은 Netscape라고 자신을 알리지만, 문제가 없다
    BrowserMatch \\bMSIE !no-gzip !gzip-only-text/html

    # no gzip response.
    SetEnvIfNoCase Request_URI \\.(?:gif|jpe?g|png|bmp|zip|tar|rar|alz|a00|ace|mp3|mp4|mpe?g|wav|asf|wma|wmv|swf|exe|pdf|doc|xsl|hwp|java|t?gz|bz2|7z)$ no-gzip dont-vary
</IfModule>

# Expire 설정
<IfModule expires_module>
    ExpiresActive On
    ExpiresByType text/css \"modification plus 1 years\"
    ExpiresByType text/javascript \"modification plus 1 years\"
    ExpiresByType application/javascript \"modification plus 1 years\"
    ExpiresByType application/x-javascript \"modification plus 1 years\"
    ExpiresByType text/xml \"modification plus 1 years\"
    ExpiresByType application/x-shockwave-flash \"modification plus 1 years\"
    ExpiresByType image/jpeg \"modification plus 1 years\"
    ExpiresByType image/gif \"modification plus 1 years\"
    ExpiresByType image/png \"modification plus 1 years\"
</IfModule>

# The HTTP/2 protocol - worker / event 모드에서는 정상 동작 확인.
#<IfModule http2_module>
#    ProtocolsHonorOrder On
#
#    # HTTP/2 in a VirtualHost context (TLS only)
#    Protocols h2 http/1.1
#
#    # HTTP/2 in a Server context (TLS and cleartext)
#    # Protocols h2 h2c http/1.1
#</IfModule>

## \"Content-Security-Policy\", \"X-Content-Type-Options\", \"X-XSS-Protection\", \"Strict-Transport-Security\" 헤더 추가
#<IfModule headers_module>
#    Header set Content-Security-Policy \"policy\"
#    Header set X-Content-Type-Options \"nosniff\"
#    Header set X-XSS-Protection \"1; mode=block\"
#    Header set Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\"
#</IfModule>

# 지정된 Method\"HEAD GET POST PUT DELETE OPTIONS\"만 접속 허용
# 만약 정상 동작하지 않는 경우 \"ErrorDocument 403\" 부분을 주석 처리 후 테스트 진행.
<Location />
    Order allow,deny
    Allow from all
    <LimitExcept HEAD GET POST PUT DELETE OPTIONS>
        Deny from all
    </LimitExcept>
</Location>
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/httpd.conf

# ----------------------------------------------------------------------------------------------------------------------
# httpd-default.conf에서 ServerTokens 설정 변경
sed -i "55s/.*/ServerTokens Prod/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-default.conf

# ----------------------------------------------------------------------------------------------------------------------
# Apache Tomcat Connecter Config 추가.
echo "# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the \"License\"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an \"AS IS\" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LoadModule jk_module modules/mod_jk.so
<IfModule jk_module>
    # We need a workers file exactly once and in the global server
    JkWorkersFile conf/extra/workers.properties

    # Our JK error log
    # You can (and should) use rotatelogs here
    JkLogFile \"|${SERVER_HOME}/${HTTPD_ALIAS}/bin/rotatelogs logs/mod_jk.%Y-%m-%d.log 86400 +540\"
    # JkLogFile \"|${SERVER_HOME}/${HTTPD_ALIAS}/bin/rotatelogs -L logs/mod_jk.log logs/archive/mod_jk.%Y-%m-%d.log 86400 +540\"

    # Our JK log level (trace,debug,info,warn,error)
    JkLogLevel info

    # Our JK shared memory file
    JkShmFile work/mod_jk.shm

    # Define a new log format you can use in any CustomLog in order
    # to add mod_jk specific information to your access log.
    #LogFormat \"%h %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" \\\"%{Cookie}i\\\" \\\"%{Set-Cookie}o\\\" %{pid}P %{tid}P %{JK_LB_FIRST_NAME}n %{JK_LB_LAST_NAME}n ACC %{JK_LB_LAST_ACCESSED}n ERR %{JK_LB_LAST_ERRORS}n BSY %{JK_LB_LAST_BUSY}n %{JK_LB_LAST_STATE}n TIME:%D\" extended_jk

    # Start a separate thread for internal tasks like
    # idle connection probing, connection pool resizing
    # and load value decay.
    # Run these tasks every JkWatchdogInterval seconds.
    # Since: 1.2.27
    JkWatchdogInterval 60

    # Request Log Format
    JKRequestLogFormat \"\\\"%w\\\" \\\"%R\\\" \\\"%m %U %H %s %B\\\" \\\"\\\" \\\"TIME:%T\\\"\"

    JkLogStampFormat \"[%a %b %d %H:%M:%S.%Q %Y] \"

    # Example for UnMounting requests using regexps
    #SetEnvIf REQUEST_URI \"\\.(htm|html|php|php3|phps|inc|phtml|css|gif|jpg|png|bmp|js)\$\" no-jk
</IfModule>
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-jk.conf

# ----------------------------------------------------------------------------------------------------------------------
# securety settings
echo "<Location /jkmanager>
    JkMount jkstatus
    Order deny,allow
    AllowOverride all

    SetEnvIf REMOTE_ADDR ^((192.168)|(27.35.74)|(203.245.5[0|3|4])) let_remote_addr
    Require env let_remote_addr
</Location>

<Location /manager>
    Order deny,allow
    AllowOverride all
    Require env ip 127.0.0.1
</Location>

<Location /host-manager>
    Order deny,allow
    AllowOverride all
    Require env ip 127.0.0.1
</Location>

<LocationMatch \"/WEB-INF\">
    Require all denied
</LocationMatch>

<LocationMatch \"/META-INF\">
    Require all denied
</LocationMatch>
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/security.conf

# ----------------------------------------------------------------------------------------------------------------------
# StartServers * ThreadsPerChild = MaxSpareThreads
# ServerLimit  * ThreadsPerChild = MaxRequestWorkers
# +---------------------+-----------------------------------------------------
# | StartServers        | 처음 시작시 생성할 쓰레드 개수
# |---------------------|-----------------------------------------------------
# | ServerLimit         | MaxRequestWorkers 가 생성할 수 있는 최대 쓰레드 개수
# |---------------------|-----------------------------------------------------
# | MinSpareThreads     | 여유분으로 최소 유지하는 쓰레드 개수
# |---------------------|-----------------------------------------------------
# | MaxSpareThreads     | 여유분으로 최대 유지하는 쓰레드 개수
# |---------------------|-----------------------------------------------------
# | ThreadsPerChild     |  프로세스당 쓰레드 개수
# |---------------------|-----------------------------------------------------
# | MaxRequestWorkers   | 요청을 동시에 처리할 수 있는 쓰레드 개수
# +---------------------+-----------------------------------------------------
#sed -i "61s/.*/<IfModule mpm_event_module>/g"       ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
#sed -i "62s/.*/    StartServers             16/g"   ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
#sed -i "63s/.*/    ServerLimit              32/g"   ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
#sed -i "64s/.*/    MinSpareThreads          75/g"   ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
#sed -i "65s/.*/    MaxSpareThreads         400/g"   ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
#sed -i "66s/.*/    ThreadsPerChild          25/g"   ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
#sed -i "67s/.*/    MaxRequestWorkers       800/g"   ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
#sed -i "68s/.*/    MaxConnectionsPerChild    0/g"   ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
#sed -i "69s/.*/<\/IfModule>\\n/g"                   ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "61s/.*/<IfModule mpm_event_module>/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "62s/.*/    StartServers              8/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "63s/.*/    ServerLimit              16/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "64s/.*/    MinSpareThreads          75/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "65s/.*/    MaxSpareThreads         200/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "66s/.*/    ThreadsPerChild          25/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "67s/.*/    MaxRequestWorkers       400/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "68s/.*/    MaxConnectionsPerChild    0/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf
sed -i "69s/.*/<\/IfModule>\\n/g" ${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-mpm.conf

# ----------------------------------------------------------------------------------------------------------------------
#  worker settings
echo "# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the \"License\"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an \"AS IS\" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# workers.properties.minimal -
#
# This file provides minimal jk configuration properties needed to
# connect to Tomcat.
#
# The workers that jk should create and work with
#
# ------------------------------------------------------------------------------
worker.list=${INSTALL_WORKER_NAME}Wlb,jkstatus

# ------------------------------------------------------------------------------
worker.template.type=ajp13
worker.template.lbfactor=1
#worker.template.ping_mode=C
worker.template.ping_mode=A
worker.template.ping_timeout=10000
worker.template.recovery_options=4
worker.template.socket_timeout=300
worker.template.socket_keepalive=true
worker.template.connection_pool_timeout=5

# ------------------------------------------------------------------------------
# ${INSTALL_WORKER_NAME}01
worker.${INSTALL_WORKER_NAME}01.reference=worker.template
worker.${INSTALL_WORKER_NAME}01.host=127.0.0.1
worker.${INSTALL_WORKER_NAME}01.port=8009
worker.${INSTALL_WORKER_NAME}01.lbfactor=1
# worker.${INSTALL_WORKER_NAME}01.redirect=tomcat02

# ${INSTALL_WORKER_NAME}02
# worker.${INSTALL_WORKER_NAME}02.reference=worker.template
# worker.${INSTALL_WORKER_NAME}02.host=127.0.0.1
# worker.${INSTALL_WORKER_NAME}02.port=8009
# worker.${INSTALL_WORKER_NAME}02.lbfactor=1
# worker.${INSTALL_WORKER_NAME}02.activation=disabled

# ${INSTALL_WORKER_NAME}Wlb
worker.${INSTALL_WORKER_NAME}Wlb.type=lb
worker.${INSTALL_WORKER_NAME}Wlb.retries=2
worker.${INSTALL_WORKER_NAME}Wlb.method=Session
worker.${INSTALL_WORKER_NAME}Wlb.sticky_session=True
worker.${INSTALL_WORKER_NAME}Wlb.balance_workers=${INSTALL_WORKER_NAME}01
# worker.${INSTALL_WORKER_NAME}Wlb.balance_workers=${INSTALL_WORKER_NAME}01,${INSTALL_WORKER_NAME}02

# ------------------------------------------------------------------------------
#
# Define status worker
#
worker.jkstatus.type=status
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/workers.properties

# ----------------------------------------------------------------------------------------------------------------------
# uriworkermap settings
echo "# This file provides sample mappings for example wlb
# worker defined in workermap.properties.minimal
# The general syntax for this file is:
# [URL]=[Worker name]
# Optionally filter out all .jpeg files inside that context
# For no mapping the url has to start with exclamation (!)

# ------------------------------------------------------------------------------
# Mapping all URL
/jkmanager=jkstatus

# ------------------------------------------------------------------------------
# Exception Settings
#!/document|/*=${INSTALL_WORKER_NAME}Wlb

# ------------------------------------------------------------------------------
# Context Settings
#/test=${INSTALL_WORKER_NAME}Wlb
#/test/*=${INSTALL_WORKER_NAME}Wlb

# ------------------------------------------------------------------------------
# ROOT Settings
/*=${INSTALL_WORKER_NAME}Wlb
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/uriworkermaps/${INSTALL_WORKER_NAME}.properties

# ----------------------------------------------------------------------------------------------------------------------
# httpd-vhosts settings
echo "# Virtual Hosts
#
# Required modules: mod_log_config

# If you want to maintain multiple domains/hostnames on your
# machine you can setup VirtualHost containers for them. Most configurations
# use only name-based virtual hosts so the server doesn't need to worry about
# IP addresses. This is indicated by the asterisks in the directives below.
#
# Please see the documentation at
# <URL:http://httpd.apache.org/docs/2.4/vhosts/>
# for further details before you try to setup virtual hosts.
#
# You may use the command line option '-S' to verify your virtual host
# configuration.

#
# VirtualHost example:
# Almost any Apache directive may go into a VirtualHost container.
# The first VirtualHost section is used for all requests that do not
# match a ServerName or ServerAlias in any <VirtualHost> block.
#
Include conf/extra/sites-enabled/${INSTALL_WORKER_NAME}.conf
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-vhosts.conf

# ----------------------------------------------------------------------------------------------------------------------
# ${INSTALL_WORKER_NAME}.conf settings
echo "<VirtualHost *:80>
    ServerName  ${DOMAIN_NAME}
    ServerAlias ${DOMAIN_NAME}
    #ServerAdmin admin@kt.com

    Include conf/extra/security.conf

    DirectoryIndex index.html index.htm index.jsp

    #Alias /document/ \"/data/document/\"
    #<Directory \"/data/document/\">
    #    #Options                     FollowSymLinks
    #    AllowOverride               None
    #    Require                     all granted
    #</Directory>

    ## Forword Proxy
    #ProxyRequests On
    #ProxyVia On
    #<Proxy \"*\">
    #    # 접근하려는 클라이언트 필터링.
    #    Require ip 172.16.121
    #</Proxy>

    Redirect 404 /favicon.ico
    <Location /favicon.ico>
        ErrorDocument 404 \"No favicon\"
    </Location>

    # AccessLog.
    #CustomLog \"|${SERVER_HOME}/${HTTPD_ALIAS}/bin/rotatelogs -L logs/${INSTALL_WORKER_NAME}.access.log logs/archive/${INSTALL_WORKER_NAME}.access.%Y-%m-%d.log 86400 +540\" combined env=!do_not_log

    RewriteEngine On
    RewriteRule ^/?dummy\.html\$ - [R=404]
    ReWriteRule ^(.*);jsessionid=[A-Za-z0-9]+(.*)\$ \$1 [L,R=301]

    # Mount JK File
    JkMountFile conf/extra/uriworkermaps/${INSTALL_WORKER_NAME}.properties
</VirtualHost>
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/sites-enabled/${INSTALL_WORKER_NAME}.conf

# ----------------------------------------------------------------------------------------------------------------------
# httpd-vhosts settings
echo "
#
# This is the Apache server configuration file providing SSL support.
# It contains the configuration directives to instruct the server how to
# serve pages over an https connection. For detailed information about these
# directives see <URL:http://httpd.apache.org/docs/2.4/mod/mod_ssl.html>
#
# Do NOT simply read the instructions in here without understanding
# what they do.  They're here only as hints or reminders.  If you are unsure
# consult the online docs. You have been warned.
#
# Required modules: mod_log_config, mod_setenvif, mod_ssl,
#          socache_shmcb_module (for default value of SSLSessionCache)

#
# Pseudo Random Number Generator (PRNG):
# Configure one or more sources to seed the PRNG of the SSL library.
# The seed data should be of good random quality.
# WARNING! On some platforms /dev/random blocks if not enough entropy
# is available. This means you then cannot use the /dev/random device
# because it would lead to very long connection times (as long as
# it requires to make more entropy available). But usually those
# platforms additionally provide a /dev/urandom device which doesn't
# block. So, if available, use this one instead. Read the mod_ssl User
# Manual for more details.
#
#SSLRandomSeed startup file:/dev/random  512
#SSLRandomSeed startup file:/dev/urandom 512
#SSLRandomSeed connect file:/dev/random  512
#SSLRandomSeed connect file:/dev/urandom 512


#
# When we also provide SSL we have to listen to the
# standard HTTP port (see above) and to the HTTPS port
#
Listen 443

##
##  SSL Global Context
##
##  All SSL configuration in this context applies both to
##  the main server and all SSL-enabled virtual hosts.
##

#   SSL Cipher Suite:
#   List the ciphers that the client is permitted to negotiate,
#   and that httpd will negotiate as the client of a proxied server.
#   See the OpenSSL documentation for a complete list of ciphers, and
#   ensure these follow appropriate best practices for this deployment.
#   httpd 2.2.30, 2.4.13 and later force-disable aNULL, eNULL and EXP ciphers,
#   while OpenSSL disabled these by default in 0.9.8zf/1.0.0r/1.0.1m/1.0.2a.
SSLCipherSuite HIGH:MEDIUM:!MD5:!RC4:!3DES
SSLProxyCipherSuite HIGH:MEDIUM:!MD5:!RC4:!3DES

#  By the end of 2016, only TLSv1.2 ciphers should remain in use.
#  Older ciphers should be disallowed as soon as possible, while the
#  kRSA ciphers do not offer forward secrecy.  These changes inhibit
#  older clients (such as IE6 SP2 or IE8 on Windows XP, or other legacy
#  non-browser tooling) from successfully connecting.
#
#  To restrict mod_ssl to use only TLSv1.2 ciphers, and disable
#  those protocols which do not support forward secrecy, replace
#  the SSLCipherSuite and SSLProxyCipherSuite directives above with
#  the following two directives, as soon as practical.
# SSLCipherSuite HIGH:MEDIUM:!SSLv3:!kRSA
# SSLProxyCipherSuite HIGH:MEDIUM:!SSLv3:!kRSA

#   User agents such as web browsers are not configured for the user's
#   own preference of either security or performance, therefore this
#   must be the prerogative of the web server administrator who manages
#   cpu load versus confidentiality, so enforce the server's cipher order.
SSLHonorCipherOrder on

#   SSL Protocol support:
#   List the protocol versions which clients are allowed to connect with.
#   Disable SSLv3 by default (cf. RFC 7525 3.1.1).  TLSv1 (1.0) should be
#   disabled as quickly as practical.  By the end of 2016, only the TLSv1.2
#   protocol or later should remain in use.
SSLProtocol all -SSLv3
SSLProxyProtocol all -SSLv3

#   Pass Phrase Dialog:
#   Configure the pass phrase gathering process.
#   The filtering dialog program (\`builtin' is an internal
#   terminal dialog) has to provide the pass phrase on stdout.
SSLPassPhraseDialog  builtin

#   Inter-Process Session Cache:
#   Configure the SSL Session Cache: First the mechanism
#   to use and second the expiring timeout (in seconds).
#SSLSessionCache         \"dbm:${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/logs/ssl_scache\"
SSLSessionCache        \"shmcb:${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/logs/ssl_scache(512000)\"
SSLSessionCacheTimeout  300

#   OCSP Stapling (requires OpenSSL 0.9.8h or later)
#
#   This feature is disabled by default and requires at least
#   the two directives SSLUseStapling and SSLStaplingCache.
#   Refer to the documentation on OCSP Stapling in the SSL/TLS
#   How-To for more information.
#
#   Enable stapling for all SSL-enabled servers:
#SSLUseStapling On

#   Define a relatively small cache for OCSP Stapling using
#   the same mechanism that is used for the SSL session cache
#   above.  If stapling is used with more than a few certificates,
#   the size may need to be increased.  (AH01929 will be logged.)
#SSLStaplingCache \"shmcb:${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/logs/ssl_stapling(32768)\"

#   Seconds before valid OCSP responses are expired from the cache
#SSLStaplingStandardCacheTimeout 3600

#   Seconds before invalid OCSP responses are expired from the cache
#SSLStaplingErrorCacheTimeout 600

##
## SSL Virtual Host Context
##
Include conf/extra/sites-enabled/${INSTALL_WORKER_NAME}-ssl.conf
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/httpd-ssl.conf

# ----------------------------------------------------------------------------------------------------------------------
# ${INSTALL_WORKER_NAME}-ssl.conf settings
echo "<VirtualHost _default_:443>
    ServerName  ${DOMAIN_NAME}
    ServerAlias ${DOMAIN_NAME}
    #ServerAdmin admin@kt.com

    Include conf/extra/security.conf

    SSLEngine on

    # +TLSv1.1 +TLSv1.2만 사용하고 모두 제외
    SSLProtocol -All +TLSv1.1 +TLSv1.2
    # +TLSv1 +TLSv1.1 +TLSv1.2만 사용하고 모두 제외
    #SSLProtocol -All +TLSv1 +TLSv1.1 +TLSv1.2
    # -SSLv2 -SSLv3 -TLSv1 제외하고 모두 사용
    #SSLProtocol all -SSLv2 -SSLv3 -TLSv1
    SSLCipherSuite HIGH:MEDIUM:!ADH:!AECDH:!PSK:!RC4:!SRP:!SSLv2
    #SSLCertificateFile conf/ssl/cert.pem
    #SSLCertificateKeyFile conf/ssl/newkey.pem
    #SSLCACertificateFile conf/ssl/TrueBusiness-Chain_sha2.pem
    #SSLCertificateChainFile conf/ssl/Comodo_Chain.pem
    SSLCertificateFile conf/ssl/${DOMAIN_NAME}.crt
    SSLCertificateKeyFile conf/ssl/${DOMAIN_NAME}.key

    DirectoryIndex index.html index.htm index.jsp

    #Alias /document/ \"/data/document/\"
    #<Directory \"/home/server/tomcat/webapps/ROOT\">
    #    Options                     FollowSymLinks
    #    AllowOverride               None
    #    Require                     all granted
    #</Directory>

    Redirect 404 /favicon.ico
    <Location /favicon.ico>
        ErrorDocument 404 \"No favicon\"
    </Location>

    # AccessLog.
    #CustomLog \"|${SERVER_HOME}/${HTTPD_ALIAS}/bin/rotatelogs -L logs/${INSTALL_WORKER_NAME}.access.log logs/archive/${INSTALL_WORKER_NAME}.access.%Y-%m-%d.log 86400 +540\" combined env=!do_not_log

    RewriteEngine On
    RewriteRule ^/?dummy\.html\$ - [R=404]
    ReWriteRule ^(.*);jsessionid=[A-Za-z0-9]+(.*)\$ \$1 [L,R=301]

    # Mount JK File
    JkMountFile conf/extra/uriworkermaps/${INSTALL_WORKER_NAME}.properties
</VirtualHost>
" >${SERVER_HOME}/${HTTPD_ALIAS}/conf/extra/sites-enabled/${INSTALL_WORKER_NAME}-ssl.conf

# # ----------------------------------------------------------------------------------------------------------------------
# printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
# printf "\e[00;32m| 사설 인증키를 생성하려면 도메인을 입력주세요.\e[00m\n"
# printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
# printf "\e[00;32m| Enter whether to ssl setting?\e[00m"
# read -e -p ' [Y / n](enter)] (default. n) > ' CHECK_SSL
# if [[ ! -z ${CHECK_SSL} ]] && [[ "$(uppercase ${CHECK_SSL})" == "Y" ]]; then
#     # 사설 인증키 생성
#     mkdir ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/conf/ssl

#     echo "[v3_extensions]
# # Extensions to add to a certificate request
# basicConstraints                = CA:FALSE
# authorityKeyIdentifier          = keyid,issuer
# subjectKeyIdentifier            = hash
# keyUsage                        = nonRepudiation, digitalSignature, keyEncipherment

# ## SSL 용 확장키 필드
# extendedKeyUsage                = serverAuth,clientAuth
# subjectAltName                  = @subject_alternative_name

# [subject_alternative_name]
# # Subject AltName의 DNSName field에 SSL Host 의 도메인 이름을 적어준다.
# # 멀티 도메인일 경우 *.lesstif.com 처럼 쓸 수 있다.
# DNS.1                           = *.${DOMAIN_NAME}

# [distinguished_name]
# countryName                     = Seoul
# countryName_default             = KR
# countryName_min                 = 2
# countryName_max                 = 2

# # 회사명 입력
# organizationName                = kt alpha
# organizationName_default        = kt alpha Co., Ltd.

# # 부서 입력
# #organizationalUnitName         = Organizational Unit Name (eg, section)
# #organizationalUnitName_default = lesstif SSL Project

# # SSL 서비스할 domain 명 입력
# commonName                      = ${DOMAIN_NAME}
# commonName_default              = admin@${DOMAIN_NAME}
# commonName_max                  = 64

# [req]
# # 화면으로 입력 받지 않도록 설정.
# prompt                          = no
# default_bits                    = 2048
# default_md                      = sha1
# default_keyfile                 = lesstif-rootca.key
# distinguished_name              = distinguished_name
# x509_extensions                 = v3_extensions
# # 인증서 요청시에도 extension 이 들어가면 authorityKeyIdentifier 를 찾지 못해 에러가 나므로 막아둔다.
# #req_extensions                  = v3_extensions
#     " >${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/conf/ssl/${DOMAIN_NAME}.conf

#     ${SERVER_HOME}/${OPENSSL_ALIAS}/bin/openssl genpkey \
#     -algorithm RSA \
#     -pkeyopt rsa_keygen_bits:4096 \
#     -out ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.key

#     chmod 400 ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.key

#     ${SERVER_HOME}/${OPENSSL_ALIAS}/bin/openssl req \
#     -new \
#     -sha256 \
#     -key ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.key \
#     -out ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.csr \
#     -config ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.conf

#     ${SERVER_HOME}/${OPENSSL_ALIAS}/bin/openssl x509 -req \
#     -days 3650 \
#     -extensions v3_user \
#     -in ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.csr \
#     -signkey ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.key \
#     -out ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.crt \
#     -extfile ${SERVER_HOME}/${HTTPD_ALIAS}/conf/ssl/${DOMAIN_NAME}.conf

#     rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${HTTPD_HOME}/conf/ssl/${DOMAIN_NAME}.conf
# fi

# # ----------------------------------------------------------------------------------------------------------------------
# if [[ -f ${BASH_FILE} ]]; then
#     SET_HTTPD_HOME=$(awk "/# Apache Start \/ Restart \/ Stop script/" ${BASH_FILE})
#     if [[ ! -n ${SET_HTTPD_HOME} ]]; then
#         echo "# Apache Start / Restart / Stop script
# # Apache Start / Stop Aliases
# alias httpd-start='sudo   ${SERVER_HOME}/${HTTPD_ALIAS}/bin/start.sh'
# alias httpd-stop='sudo    ${SERVER_HOME}/${HTTPD_ALIAS}/bin/stop.sh'
# alias httpd-restart='sudo ${SERVER_HOME}/${HTTPD_ALIAS}/bin/restart.sh'
# alias httpd-status='sudo  ${SERVER_HOME}/${HTTPD_ALIAS}/bin/status.sh'
# " >>${BASH_FILE}
#     fi
# fi

# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${HTTPD_ALIAS}\" install success...\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
