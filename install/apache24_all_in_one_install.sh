#!/bin/bash
# APR을 Apache 소스에 넣어서 설치하는 버전.
# OpenSSL은 OS 설치 버전을 사용.
# ------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -fsSL -H "Cache-Control: no-cache" -H 'Pragma: no-cache' https://raw.githubusercontent.com/sky01126/script-template/master/install/apache24_all_in_one_install.sh)
#
# ----------------------- 상용 서버 ------------------------
# yum install -y epel-release
# yum install -y libnghttp2
#
# ----------------------- 개발 서버 ------------------------
# yum install -y epel-release
# yum install -y libnghttp2 libnghttp2-devel
#
# ----------------------- 참조 사이트 ------------------------
# mod_ratelimit : http://elkha.kr/xe/misc/166663
#                 https://httpd.apache.org/docs/trunk/mod/mod_ratelimit.html
# mod_cache : https://httpd.apache.org/docs/2.4/ko/mod/mod_cache.html
# 아파치 성능향상 : https://httpd.apache.org/docs/2.4/misc/perf-tuning.html
#
# ----------------------- Apache 계정 생성 ------------------------
# groupadd -g 48 -r apache && useradd -r -u 48 -g apache -s /sbin/nologin -d /apache -c "Apache" apache
#
# ----------------------- Alias 등록 ------------------------
# echo "# Apache start / stop script.
# alias apache-start=\"sudo /apache/apache24/bin/start.sh\"
# alias apache-stop=\"sudo /apache/apache24/bin/stop.sh\"
# alias apache-restart=\"sudo /apache/apache24/bin/restart.sh\"
# alias apache-configtest=\"/apache/apache24/bin/configtest.sh\"
# " >> $HOME/.bash_aliases && source $HOME/.bashrc
#
# - SSL 1.1.1 사용 시 아래 2개 파일 복사
#   cp /home/server/openssl/lib/libssl.so.1.1 /usr/lib64/
#   cp /home/server/openssl/lib/libcrypto.so.1.1 /usr/lib64/
#
# ----------------------- 보안 업데이트 ------------------------
# - [2022.01.04] 보안 업데이트 - Apache HTTP Server 2.4.51 및 이전 버전
#   Apache HTTP Server에서 널 포인터 역참조로 인해 발생하는 서비스거부 취약점(CVE-2021-44224)
#   Apache HTTP Server에서 입력값 검증이 미흡하여 발생하는 버퍼오버플로우 취약점(CVE-2021-44790)111
#

# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 현재 사용자의 아이디명과 그룹정보
# export USERNAME=`id -u -n`
# export GROUPNAME=`id -g -n`
export USERNAME="apache"
export GROUPNAME="apache"

# ------------------------------------------------------------------------------
# 대문자 변환
uppercase() {
    echo $* | tr "[a-z]" "[A-Z]"
}

# 소문자변환
lowercase() {
    echo $* | tr "[A-Z]" "[a-z]"
}

# ------------------------------------------------------------------------------
# File Extension
export EXTENSION='.tar.gz'

# ------------------------------------------------------------------------------
# 서버 디렉토리 설정.
# export SERVER_HOME="/apache"
# export LOG_HOME="/ap_log"

# export SERVER_HOME="/home/www"
if [[ -z "${SERVER_HOME}" ]]; then
    printf "Enter the server home path"
    read -e -p " > " SERVER_HOME
    while [[ -z "${SERVER_HOME}" ]]; do
        printf "Enter the server home path"
        read -e -p " > " SERVER_HOME
    done
    echo
fi
mkdir -p ${SERVER_HOME}

# export LOG_HOME="/home/www/httpd_log"
if [[ -z "${LOG_HOME}" ]]; then
    printf "Enter the server home path"
    read -e -p " > " LOG_HOME
    while [[ -z "${LOG_HOME}" ]]; do
        printf "Enter the http log path"
        read -e -p " > " LOG_HOME
    done
    echo
fi
mkdir -p ${LOG_HOME}

export SRC_HOME="${SERVER_HOME}/src"
mkdir -p ${SRC_HOME}

# ------------------------------------------------------------------------------
# .bashrc 경로 설정.
export BASH_FILE=${HOME}/.bashrc

# ------------------------------------------------------------------------------
# Apache 2.4
export HTTPD_VERSION="2.4.54"
export HTTPD_DOWNLOAD_URL="http://archive.apache.org/dist/httpd/httpd-${HTTPD_VERSION}.tar.gz"
export HTTPD_NAME=${HTTPD_DOWNLOAD_URL##+(*/)}
export HTTPD_HOME='httpd'

# ------------------------------------------------------------------------------
export OPENSSL_VERSION="3.0.7"
export OPENSSL_DOWNLOAD_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
export OPENSSL_NAME="${OPENSSL_DOWNLOAD_URL##+(*/)}"
export OPENSSL_HOME="${OPENSSL_NAME%$EXTENSION}"

# ------------------------------------------------------------------------------
# PCRE2
export PCRE2_VERSION="10.37"
export PCRE2_DOWNLOAD_URL="http://sourceforge.net/projects/pcre/files/pcre2/${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz"
export PCRE2_NAME="${PCRE2_DOWNLOAD_URL##+(*/)}"
export PCRE2_HOME="${PCRE2_NAME%$EXTENSION}"

# ------------------------------------------------------------------------------
# APR / APR Util
export APR_VERSION="1.7.0"
export APR_DOWNLOAD_URL="http://archive.apache.org/dist/apr/apr-${APR_VERSION}.tar.gz"
export APR_NAME=${APR_DOWNLOAD_URL##+(*/)}
export APR_HOME=${APR_NAME%$EXTENSION}

export APR_UTIL_VERSION="1.6.1"
export APR_UTIL_DOWNLOAD_URL="http://archive.apache.org/dist/apr/apr-util-${APR_UTIL_VERSION}.tar.gz"
export APR_UTIL_NAME=${APR_UTIL_DOWNLOAD_URL##+(*/)}
export APR_UTIL_HOME=${APR_UTIL_NAME%$EXTENSION}

export APR_ICONV_VERSION="1.2.2"
export APR_ICONV_DOWNLOAD_URL="http://archive.apache.org/dist/apr/apr-iconv-${APR_ICONV_VERSION}.tar.gz"
export APR_ICONV_NAME="${APR_ICONV_DOWNLOAD_URL##+(*/)}"
export APR_ICONV_HOME="${APR_ICONV_NAME%$EXTENSION}"

# ------------------------------------------------------------------------------
# Apache Tomcat Connector
MOD_JK_VERSION="1.2.48"
MOD_JK_DOWNLOAD_URL="http://archive.apache.org/dist/tomcat/tomcat-connectors/jk/tomcat-connectors-${MOD_JK_VERSION}-src.tar.gz"

# ------------------------------------------------------------------------------
printf "\e[00;32m+--------------+----------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SERVER_HOME  |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| SRC_HOME     |\e[00m ${SRC_HOME}\n"
printf "\e[00;32m+--------------+------------------------------------------------------------------\e[00m\n"

# ------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${HTTPD_HOME}" ]]; then
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

# ------------------------------------------------------------------------------
# Domain Name 설정.
if [[ -z "${DOMAIN_NAME}" ]]; then
    printf "\e[00;32m| Enter the domain name\e[00m"
    read -e -p " > " DOMAIN_NAME
    while [[ -z "${DOMAIN_NAME}" ]]; do
        printf "\e[00;32m| Enter the domain name\e[00m"
        read -e -p " > " DOMAIN_NAME
    done
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
fi

# ------------------------------------------------------------------------------
if [[ ! -d "${SERVER_HOME}/openssl" ]]; then
    cd ${SRC_HOME}

    printf "\e[00;32m| ${OPENSSL_NAME} download (URL : ${OPENSSL_DOWNLOAD_URL})\e[00m\n"
    curl -O ${OPENSSL_DOWNLOAD_URL}

    tar xvzf ${OPENSSL_NAME}
    cd ${SRC_HOME}/${OPENSSL_HOME}

    ./config --prefix=${SERVER_HOME}/openssl -fPIC shared
    make
    make install

    printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| ${OPENSSL_HOME} install success...\e[00m\n"
    printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
fi

# ------------------------------------------------------------------------------
# PCRE 설치
if [[ ! -d "${SERVER_HOME}/pcre2" ]]; then
    cd ${SRC_HOME}
    if [ ! -f "${SRC_HOME}/${PCRE2_NAME}" ]; then
        printf "\e[00;32m| ${PCRE2_NAME} download (URL : ${PCRE2_DOWNLOAD_URL})\e[00m\n"
        curl -L -O ${PCRE2_DOWNLOAD_URL}
    fi

    tar xvzf ${PCRE2_NAME}
    cd ${SRC_HOME}/${PCRE2_HOME}

    ./configure --prefix=${SRC_HOME}/pcre2
    make
    make install

    # Install source delete
    if [[ -d "${SRC_HOME}/${PCRE2_HOME}" ]]; then
        printf "\e[00;32m| \"${SRC_HOME}/${PCRE2_HOME}\" delete...\e[00m\n"
        rm -rf ${SRC_HOME}/${PCRE2_HOME}
    fi
fi

cd ${SRC_HOME}

# delete the compile source
if [[ -d "${SRC_HOME}/${HTTPD_NAME%$EXTENSION}" ]]; then
    printf "\e[00;32m| \"${SRC_HOME}/${HTTPD_NAME%$EXTENSION}\" delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}
fi

printf "\e[00;32m| \"${HTTPD_HOME}\" install start...\e[00m\n"

# delete the previous home
if [[ -d "${SERVER_HOME}/${HTTPD_HOME}" || -L "${SERVER_HOME}/${HTTPD_HOME}" ]]; then
    printf "\e[00;32m| \"${HTTPD_ALIAS}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${HTTPD_HOME}
fi

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${HTTPD_NAME}" ]; then
    printf "\e[00;32m| \"${HTTPD_NAME}\" download (URL : ${HTTPD_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${HTTPD_DOWNLOAD_URL}
fi

tar xvzf ${HTTPD_NAME}

# ------------------------------------------------------------------------------
# APR 추가
cd ${SRC_HOME}
if [ ! -f "${SRC_HOME}/${APR_NAME}" ]; then
    printf "\e[00;32m| ${APR_NAME} download (URL : ${APR_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${APR_DOWNLOAD_URL}
fi

tar xvzf ${APR_NAME} -C ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/srclib/
cd ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/srclib/
mv ${APR_HOME} apr

# APR Util
cd ${SRC_HOME}
if [ ! -f "${SRC_HOME}/${APR_UTIL_NAME}" ]; then
    printf "\e[00;32m| ${APR_UTIL_NAME} download (URL : ${APR_UTIL_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${APR_UTIL_DOWNLOAD_URL}
fi

tar xvzf ${APR_UTIL_NAME} -C ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/srclib/
cd ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/srclib/
mv ${APR_UTIL_HOME} apr-util

# APR Iconv
cd ${SRC_HOME}
if [ ! -f "${SRC_HOME}/${APR_ICONV_NAME}" ]; then
    printf "\e[00;32m| ${APR_ICONV_NAME} download (URL : ${APR_ICONV_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${APR_ICONV_DOWNLOAD_URL}
fi

tar xvzf ${APR_ICONV_NAME} -C ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/srclib/
cd ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/srclib/
mv ${APR_ICONV_HOME} apr-iconv

# ------------------------------------------------------------------------------
# MPM 모드 설정 변경.
if [ "$OS" == "linux" ]; then
    sed -i "75s/.*/#define DEFAULT_SERVER_LIMIT 1024/g" ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/server/mpm/prefork/prefork.c

    # ServerLimit과 ThreadsPerChild 값을 변경한다. 서버의 스팩에 따라서 적절하게 수정한다.
    sed -i "87s/.*/#define DEFAULT_SERVER_LIMIT 128/g" ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/server/mpm/worker/worker.c

    # ServerLimit과 ThreadsPerChild 값을 변경한다. 서버의 스팩에 따라서 적절하게 수정한다.
    sed -i "115s/.*/#define DEFAULT_SERVER_LIMIT 128/g" ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}/server/mpm/event/event.c
fi

# ------------------------------------------------------------------------------
INSTALL_CONFIG="--prefix=${SERVER_HOME}/${HTTPD_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-cache"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-cache-disk"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-deflate"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-expires"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-file-cache"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-http2"
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
INSTALL_CONFIG="${INSTALL_CONFIG} --with-included-apr"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-mpm=event"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-ssl=${SERVER_HOME}/openssl"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-pcre=${SRC_HOME}/pcre2/bin/pcre2-config"

cd ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}

./configure ${INSTALL_CONFIG}
make
make install

printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${HTTPD_HOME}\" install success...\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
sleep 0.5

# Apache Tomcat Connector 설치
printf "\e[00;32m| Apache Tomcat Connector install start...\e[00m\n"

MOD_JK_NAME=${MOD_JK_DOWNLOAD_URL##+(*/)}
MOD_JK_HOME=${MOD_JK_NAME%$EXTENSION}

cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${MOD_JK_NAME}" ]; then
    printf "\e[00;32m| \"${MOD_JK_NAME}\" download (URL : ${MOD_JK_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${MOD_JK_DOWNLOAD_URL}
fi

tar xvzf ${MOD_JK_NAME}
cd ${SRC_HOME}/${MOD_JK_HOME}/native

./configure --with-apxs=${SERVER_HOME}/${HTTPD_HOME}/bin/apxs
make
make install

cp -rf apache-2.0/mod_jk.so ${SERVER_HOME}/${HTTPD_HOME}/modules/

# Install source delete
if [[ -d "${SRC_HOME}/${MOD_JK_HOME}" ]]; then
    printf "\e[00;32m| \"${SRC_HOME}/${MOD_JK_HOME}\" delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${MOD_JK_HOME}
fi

# Install source delete
if [[ -d "${SRC_HOME}/${HTTPD_NAME%$EXTENSION}" ]]; then
    printf "\e[00;32m| \"${SRC_HOME}/${HTTPD_NAME%$EXTENSION}\" delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${HTTPD_NAME%$EXTENSION}
fi

# HTTPD 서버에서 필요없는 디렉토리 삭제.
rm -rf ${SERVER_HOME}/${HTTPD_HOME}/build
rm -rf ${SERVER_HOME}/${HTTPD_HOME}/cgi-bin
rm -rf ${SERVER_HOME}/${HTTPD_HOME}/error
rm -rf ${SERVER_HOME}/${HTTPD_HOME}/htdocs
rm -rf ${SERVER_HOME}/${HTTPD_HOME}/icons
rm -rf ${SERVER_HOME}/${HTTPD_HOME}/man
rm -rf ${SERVER_HOME}/${HTTPD_HOME}/manual

# 필요 디렉토리 생성.
mkdir -p ${LOG_HOME}/jk/shm
mkdir -p ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/uriworkermaps
mkdir -p ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/vhosts

# ------------------------------------------------------------------------------
## Tomcat Worker Name 설정.
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m|   ______                           __  \e[00m\n"
printf "\e[00;32m|  /_  __/___  ____ ___  _________ _/ /_ \e[00m\n"
printf "\e[00;32m|   / / / __ \/ __  __ \/ ___/ __  / __/ \e[00m\n"
printf "\e[00;32m|  / / / /_/ / / / / / / /__/ /_/ / /_   \e[00m\n"
printf "\e[00;32m| /_/  \____/_/ /_/ /_/\___/\__,_/\__/   \e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
if [[ -z" ${INSTALL_WORKER_NAME}" ]]; then
    printf "\e[00;32m| Enter the JK Connecter name\e[00m"
    read -e -p ' (default. default) > ' INSTALL_WORKER_NAME
    if [[ -z ${CHECK_TOMCAT} ]]; then
        INSTALL_WORKER_NAME="default"
    fi
fi

# ------------------------------------------------------------------------------
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
    ls=\$(ls -ld \"\$PRG\")
    link=\$(expr \"\$ls\" : '.*-> \(.*\)\$')
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\$(dirname \"\$PRG\")/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\$(dirname \"\$PRG\")

# HTTPD_HOME is the location of the configuration files of this instance of nginx
export HTTPD_HOME=\$(cd \"\$PRGDIR/..\" >/dev/null; pwd)

\$HTTPD_HOME/bin/apachectl start

if [[ ! -f \"${LOG_HOME}/httpd.pid\" ]]; then
    printf \"Apache Starting:\"

    sleep 0.5
    retval=\$?
    if [[ \$retval = 0 ]]; then
        printf \"                           [  \e[00;32mOK\e[00m  ]\\\\n\"
    else
        printf \"                           [\e[00;32mFAILED\e[00m]\\\\n\"
    fi
fi

" >${SERVER_HOME}/${HTTPD_HOME}/bin/start.sh

# ------------------------------------------------------------------------------
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
    ls=\$(ls -ld \"\$PRG\")
    link=\$(expr \"\$ls\" : '.*-> \(.*\)\$')
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\$(dirname \"\$PRG\")/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\$(dirname \"\$PRG\")

# HTTPD_HOME is the location of the configuration files of this instance of nginx
export HTTPD_HOME=\$(cd \"\$PRGDIR/..\" >/dev/null; pwd)

STOPD=
if [[ -f \"${LOG_HOME}/httpd.pid\" ]]; then
    STOPD='true'
fi

\$HTTPD_HOME/bin/apachectl stop

if [[ -n \"\$STOPD\" ]]; then
    printf \"Apache Stopping:\"

    sleep 0.5
    retval=\$?
    if [[ \$retval = 0 ]]; then
        printf \"                           [  \e[00;32mOK\e[00m  ]\\\\n\"
    else
        printf \"                           [\e[00;32mFAILED\e[00m]\\\\n\"
    fi
fi
" >${SERVER_HOME}/${HTTPD_HOME}/bin/stop.sh

# ------------------------------------------------------------------------------
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
    ls=\$(ls -ld \"\$PRG\")
    link=\$(expr \"\$ls\" : '.*-> \(.*\)\$')
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\$(dirname \"\$PRG\")/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\$(dirname \"\$PRG\")

# HTTPD_HOME is the location of the configuration files of this instance of nginx
export HTTPD_HOME=\$(cd \"\$PRGDIR/..\" >/dev/null; pwd)

STOPD=
if [[ -f \"${LOG_HOME}/httpd.pid\" ]]; then
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
" >${SERVER_HOME}/${HTTPD_HOME}/bin/restart.sh

# ------------------------------------------------------------------------------
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
    echo \$(ps aux | grep httpd | grep -v grep | grep -v status | grep -v rotatelogs | awk '{print \$2}')
}

if [[ -n \"\$(server_pid)\" ]]; then
    pid=\$(cat ${LOG_HOME}/httpd.pid)
    echo \"httpd (pid \$pid) is running.\"
    exit 0
else
    echo \"httpd (no pid file) not running.\"
    exit 1
fi
" >${SERVER_HOME}/${HTTPD_HOME}/bin/status.sh

# ------------------------------------------------------------------------------
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
    ls=\$(ls -ld \"\$PRG\")
    link=\$(expr \"\$ls\" : '.*-> \(.*\)\$')
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\$(dirname \"\$PRG\")/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\$(dirname \"\$PRG\")

# HTTPD_HOME is the location of the configuration files of this instance of nginx
export HTTPD_HOME=\$(cd \"\$PRGDIR/..\" >/dev/null; pwd)

\$HTTPD_HOME/bin/apachectl configtest
" >${SERVER_HOME}/${HTTPD_HOME}/bin/configtest.sh

# ------------------------------------------------------------------------------
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
    echo \$(ps aux | grep httpd | grep -v grep | grep -v status | grep -v rotatelogs | awk '{print \$2}')
}

if [[ -n \"\$(server_pid)\" ]]; then
    # Apache에서 실행되는 전체 Thread 숫자를 조회한다.
    PROCESS_IDS=''
    for pid in \$(ps aux | grep httpd | grep ${USERNAME} | grep -v grep | grep -v status | grep -v rotatelogs | awk '{print \$2}'); do
        PROCESS_IDS+=\"\${pid} \"
    done
    #printf \" \e[00;32m|\e[00m ps hH p \${PROCESS_IDS} | wc -l\"
    #echo

    printf \"Total thread count running on httpd: \e[00;32m\$(ps hH p \${PROCESS_IDS} | wc -l)\e[00m\\\\n\"
    exit 0
else
    echo \"httpd (no pid file) not running.\"
    exit 1
fi
" >${SERVER_HOME}/${HTTPD_HOME}/bin/check-run-thread.sh

# ------------------------------------------------------------------------------
echo "#!/bin/sh
total_request=1000
concurrency=100
times=1

cmd_idx=1
param_count=\$#
while [ \$cmd_idx -lt \$param_count ]
do
    cmd=\$1
    shift 1
    case \$cmd in
        -n)
            total_request=\$1
            shift 1;;
        -c)
            concurrency=\$1
            shift 1;;
        -t)
            times=\$1
            shift 1;;
        *)
            echo \"\$cmd, support parameter: -n, -c, -t\"
            ;;
    esac
    cmd_idx=\$(expr \$cmd_idx + 2)
done

url=\$1
if [[ \$url = '' ]]; then
    echo \"the test url must be provided...\"
    exit 2
fi

echo \"Total Request: \$total_request, Concurrency: \$concurrency, URL: \$url, Times: \$times\"

ab_dir=\""${SERVER_HOME}/${HTTPD_HOME}/bin"\"
ab_cmd=\"\$ab_dir/ab -n \$total_request -c \$concurrency \$url\"

echo \$ab_cmd
idx=1
rps_sum=0
max=-1
min=99999999
while [ \$idx -le \$times ]
do
    echo \"start loop \$idx\"
    result=\$(\$ab_cmd | grep 'Requests per second:')
    result=\$(echo \$result | awk -F ' ' '{ print \$4 }' | awk -F '.' '{ print \$1 }')

    rps_sum=\$(expr \$result + \$rps_sum)
    if [[ \$result -gt \$max ]]; then
        max=\$result
    fi
    if [[ \$result -lt \$min ]]; then
        min=\$result
    fi
    idx=\$(expr \$idx + 1)
done

echo \"avg rps: \"\$(expr \$rps_sum / \$times)
echo \"min rps: \$min\"
echo \"max rps: \$max\"
" >${SERVER_HOME}/${HTTPD_HOME}/bin/stress.sh

# ------------------------------------------------------------------------------
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
    ls=\$(ls -ld \"\$PRG\")
    link=\$(expr \"\$ls\" : '.*-> \(.*\)\$')
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\$(dirname \"\$PRG\")/\"\$link\"
    fi
done

# ------------------------------------------------------------------------------
# 현재 사용자의 아이디명과 그룹정보
USERNAME=\$(id -u -n)
GROUPNAME=\$(id -g -n)

# ------------------------------------------------------------------------------
# check-run-thread.sh
sed -i \"s/for pid in.*/for pid in \$(ps aux | grep httpd | grep \${USERNAME} | grep -v grep | grep -v status | grep -v rotatelogs | awk '{print \$2}'); do/g\" \${PRGDIR}/bin/check-run-thread.sh

# ------------------------------------------------------------------------------
# delete-log.sh
sed -i \"s/USER=.*/USER=\${USERNAME}/g\"       \${PRGDIR}/bin/*.sh
sed -i \"s/GROUP=.*/GROUP=\${GROUPNAME}/g\"    \${PRGDIR}/bin/*.sh

# ------------------------------------------------------------------------------
# Apache Config 수정.
sed -i \"s/User.*/User \${USERNAME}/g\"        \${PRGDIR}/conf/httpd.conf
sed -i \"s/Group.*/Group \${GROUPNAME}/g\"     \${PRGDIR}/conf/httpd.conf
" > ${SERVER_HOME}/${HTTPD_HOME}/bin/change-user.sh

# ------------------------------------------------------------------------------
chmod +x ${SERVER_HOME}/${HTTPD_HOME}/bin/*.sh

# ------------------------------------------------------------------------------
# Apache Config 수정.
echo "ServerRoot \"${SERVER_HOME}/${HTTPD_HOME}\"

#Listen 12.34.56.78:80
#Listen 0.0.0.0:80
Listen 80

#
# Dynamic Shared Object (DSO) Support
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
    User ${USERNAME}
    Group ${GROUPNAME}
</IfModule>

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
# ErrorLog \"|${SERVER_HOME}/${HTTPD_HOME}/bin/rotatelogs -L ${LOG_HOME}/error.log ${LOG_HOME}/archive/error.%Y-%m-%d.log 86400 +540\"
ErrorLog \"|${SERVER_HOME}/${HTTPD_HOME}/bin/rotatelogs ${LOG_HOME}/error.%Y-%m-%d.log 86400 +540\"

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

    # %T : Time taken to process the request, in seconds
    # %D : Time taken to process the request, inmicroseconds
    LogFormat \"%h %l %u %t \\\"%{Host}i\\\" \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" TIME:%T\" combined
    #LogFormat \"%h %{NS-CLIENT-IP}i %l %u %t \\\"%{Host}i\\\" \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" TIME:%D\" combined

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
    # CustomLog \"|${SERVER_HOME}/${HTTPD_HOME}/bin/rotatelogs -L ${LOG_HOME}/access.log ${LOG_HOME}/archive/access.%Y-%m-%d.log 86400 +540\" combined env=!do_not_log
    CustomLog \"|${SERVER_HOME}/${HTTPD_HOME}/bin/rotatelogs ${LOG_HOME}/access.%Y-%m-%d.log 86400 +540\" combined env=!do_not_log
</IfModule>

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
PidFile ${LOG_HOME}/httpd.pid

# Apache Tomcat JK Connect setting
Include conf/extra/httpd-jk.conf

# Setting MOD Default.
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

## Setting Expire
#<IfModule expires_module>
#    ExpiresActive On
#    ExpiresByType application/javascript \"modification plus 1 years\"
#    ExpiresByType application/x-javascript \"modification plus 1 years\"
#    ExpiresByType application/x-shockwave-flash \"modification plus 1 years\"
#    ExpiresByType image/gif \"modification plus 1 years\"
#    ExpiresByType image/jpeg \"modification plus 1 years\"
#    ExpiresByType image/png \"modification plus 1 years\"
#    ExpiresByType text/css \"modification plus 1 years\"
#    ExpiresByType text/javascript \"modification plus 1 years\"
#    ExpiresByType text/xml \"modification plus 1 years\"
#</IfModule>

##  Setting header \"Content-Security-Policy\", \"X-Content-Type-Options\", \"X-XSS-Protection\", \"Strict-Transport-Security\"
#<IfModule headers_module>
#    Header set Content-Security-Policy \"policy\"
#    Header set X-Content-Type-Options \"nosniff\"
#    Header set X-XSS-Protection \"1; mode=block\"
#    Header set Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\"
#</IfModule>

# The HTTP/2 protocol - Check normal operation in worker / event mode
#<IfModule http2_module>
#    ProtocolsHonorOrder On
#
#    # HTTP/2 in a VirtualHost context (TLS only)
#    Protocols h2 http/1.1
#
#    # HTTP/2 in a Server context (TLS and cleartext)
#    #Protocols h2 h2c http/1.1
#</IfModule>

# Allow access only to the specified Method\"HEAD GET POST PUT DELETE OPTIONS\"
# If it does not work properly, comment out the \"ErrorDocument 403\" part and proceed with the test.
<Location />
    Order allow,deny
    Allow from all
    <LimitExcept HEAD GET POST PUT DELETE OPTIONS>
        Deny from all
    </LimitExcept>
</Location>
" >${SERVER_HOME}/${HTTPD_HOME}/conf/httpd.conf

# ------------------------------------------------------------------------------
# httpd-default.conf에서 ServerTokens 설정 변경
sed -i "55s/.*/ServerTokens Prod/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-default.conf

# ------------------------------------------------------------------------------
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
    JkLogFile \"|${SERVER_HOME}/${HTTPD_HOME}/bin/rotatelogs ${LOG_HOME}/jk/mod_jk.%Y-%m-%d.log 86400 +540\"

    # Our JK log level (trace,debug,info,warn,error)
    JkLogLevel info

    # Our JK shared memory file
    JkShmFile ${LOG_HOME}/jk/shm//mod_jk.shm

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
" >${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-jk.conf

# ------------------------------------------------------------------------------
# securety settings
echo "# securety settings
# <Location /jkmanager>
#     JkMount jkstatus
#     Order deny,allow
#     AllowOverride all
#     SetEnvIf REMOTE_ADDR ^((192.168)|(27.35.74)|(203.245.5[0|3|4])) let_remote_addr
#     Require env let_remote_addr
# </Location>

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
" >${SERVER_HOME}/${HTTPD_HOME}/conf/extra/security.conf

# ------------------------------------------------------------------------------
# StartServers * ThreadsPerChild = MinSpareThreads
# MinSpareThreads * 2 = MaxSpareThreads
# ServerLimit  * ThreadsPerChild = MaxRequestWorkers
# +---------------------+-----------------------------------------------------
# | StartServers        | 처음 시작시 생성할 프로세스 수
# |---------------------|-----------------------------------------------------
# | ServerLimit         | 최대 생성할 프로세스 수
# |---------------------|-----------------------------------------------------
# | MinSpareThreads     | 여유분으로 최소 유지하는 쓰레드 개수
# |---------------------|-----------------------------------------------------
# | MaxSpareThreads     | 여유분으로 최대 유지하는 쓰레드 개수
# |---------------------|-----------------------------------------------------
# | ThreadsPerChild     | 프로세스 당 쓰레드 개수
# |---------------------|-----------------------------------------------------
# | MaxRequestWorkers   | 요청을 동시에 처리할 수 있는 쓰레드 개수
# +---------------------+-----------------------------------------------------
sed -i "61s/.*/<IfModule mpm_event_module>/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf
sed -i "62s/.*/    StartServers              8/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf
sed -i "63s/.*/    ServerLimit              32/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf
sed -i "64s/.*/    MinSpareThreads         512/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf
sed -i "65s/.*/    MaxSpareThreads        1024/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf
sed -i "66s/.*/    ThreadsPerChild          64/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf
sed -i "67s/.*/    MaxRequestWorkers      2048/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf
sed -i "68s/.*/    MaxConnectionsPerChild    0/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf
sed -i "69s/.*/<\/IfModule>\\n/g" ${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-mpm.conf

# ------------------------------------------------------------------------------
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
# Setting Tomcat APR Secret
# worker.${INSTALL_WORKER_NAME}01.secret=${INSTALL_WORKER_NAME}

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
" >${SERVER_HOME}/${HTTPD_HOME}/conf/extra/workers.properties

# ------------------------------------------------------------------------------
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
" >${SERVER_HOME}/${HTTPD_HOME}/conf/extra/uriworkermaps/${INSTALL_WORKER_NAME}.properties

# ------------------------------------------------------------------------------
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
Include conf/extra/vhosts/${INSTALL_WORKER_NAME}.conf
" >${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-vhosts.conf

# ------------------------------------------------------------------------------
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
    #CustomLog \"|${SERVER_HOME}/${HTTPD_HOME}/bin/rotatelogs ${LOG_HOME}/${INSTALL_WORKER_NAME}.access.%Y-%m-%d.log 86400 +540\" combined env=!do_not_log

    RewriteEngine On
    RewriteRule ^/?dummy\.html\$ - [R=404]
    ReWriteRule ^(.*);jsessionid=[A-Za-z0-9]+(.*)\$ \$1 [L,R=301]

    # Mount JK File
    JkMountFile conf/extra/uriworkermaps/${INSTALL_WORKER_NAME}.properties
</VirtualHost>
" >${SERVER_HOME}/${HTTPD_HOME}/conf/extra/vhosts/${INSTALL_WORKER_NAME}.conf

# ------------------------------------------------------------------------------
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
#SSLSessionCache         \"dbm:${LOG_HOME}/ssl_scache\"
SSLSessionCache        \"shmcb:${LOG_HOME}/ssl_scache(512000)\"
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
#SSLStaplingCache \"shmcb:${LOG_HOME}/ssl_stapling(32768)\"

#   Seconds before valid OCSP responses are expired from the cache
#SSLStaplingStandardCacheTimeout 3600

#   Seconds before invalid OCSP responses are expired from the cache
#SSLStaplingErrorCacheTimeout 600

##
## SSL Virtual Host Context
##
Include conf/extra/vhosts/${INSTALL_WORKER_NAME}-ssl.conf
" >${SERVER_HOME}/${HTTPD_HOME}/conf/extra/httpd-ssl.conf

# # ------------------------------------------------------------------------------
# # ${INSTALL_WORKER_NAME}-ssl.conf settings
# echo "<VirtualHost _default_:443>
#     ServerName  ${DOMAIN_NAME}
#     ServerAlias ${DOMAIN_NAME}
#     #ServerAdmin admin@kt.com

#     Include conf/extra/security.conf

#     SSLEngine on

#     # TLSv1.2, TLSv1.3만 사용하고 모두 제외
#     SSLProtocol -All +TLSv1.2 +TLSv1.3
#     # TLSv1, TLSv1.1, TLSv1.2, TLSv1.3만 사용하고 모두 제외
#     #SSLProtocol -All +TLSv1 +TLSv1.1 +TLSv1.2 +TLSv1.3
#     # SSLv2, SSLv3, TLSv1, TLSv1.1 제외하고 모두 사용
#     #SSLProtocol all -SSLv2 -SSLv3 -TLSv1 +TLSv1.1
#     SSLCipherSuite HIGH:MEDIUM:!ADH:!AECDH:!PSK:!RC4:!SRP:!SSLv2
#     # SSLCertificateFile conf/ssl/cert.pem
#     # SSLCertificateKeyFile conf/ssl/newkey.pem
#     # SSLCACertificateFile conf/ssl/TrueBusiness-Chain_sha2.pem
#     # SSLCertificateChainFile conf/ssl/Comodo_Chain.pem
#     SSLCertificateFile conf/ssl/${INSTALL_WORKER_NAME}.crt
#     SSLCertificateKeyFile conf/ssl/${INSTALL_WORKER_NAME}.key

#     DirectoryIndex index.html index.htm index.jsp

#     #Alias /document/ \"/data/document/\"
#     #<Directory \"/home/server/tomcat/webapps/ROOT\">
#     #    Options                     FollowSymLinks
#     #    AllowOverride               None
#     #    Require                     all granted
#     #</Directory>

#     Redirect 404 /favicon.ico
#     <Location /favicon.ico>
#         ErrorDocument 404 \"No favicon\"
#     </Location>

#     # AccessLog.
#     #CustomLog \"|${SERVER_HOME}/${HTTPD_HOME}/bin/rotatelogs ${LOG_HOME}/${INSTALL_WORKER_NAME}.access.%Y-%m-%d.log 86400 +540\" combined env=!do_not_log

#     RewriteEngine On
#     RewriteRule ^/?dummy\.html\$ - [R=404]
#     ReWriteRule ^(.*);jsessionid=[A-Za-z0-9]+(.*)\$ \$1 [L,R=301]

#     # Mount JK File
#     JkMountFile conf/extra/uriworkermaps/${INSTALL_WORKER_NAME}.properties
# </VirtualHost>
# " >${SERVER_HOME}/${HTTPD_HOME}/conf/extra/vhosts/${INSTALL_WORKER_NAME}-ssl.conf

# #------------------------------------------------------------------------------
# if [[ -f "${BASH_FILE}" ]]; then
#    SET_HTTPD_HOME=`awk "/# Apache Start \/ Restart \/ Stop script/" ${BASH_FILE}`
#    if [[ ! -n "${SET_HTTPD_HOME}" ]]; then
#        echo "# Apache Start / Restart / Stop script
# # Apache Start / Stop Aliases
# alias httpd-start='sudo   ${SERVER_HOME}/${HTTPD_HOME}/bin/start.sh'
# alias httpd-stop='sudo    ${SERVER_HOME}/${HTTPD_HOME}/bin/stop.sh'
# alias httpd-restart='sudo ${SERVER_HOME}/${HTTPD_HOME}/bin/restart.sh'
# alias httpd-status='sudo  ${SERVER_HOME}/${HTTPD_HOME}/bin/status.sh'
# " >> ${BASH_FILE}
#    fi
# fi

printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${HTTPD_HOME}\" install success...\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
