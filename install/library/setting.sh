#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/


# ----------------------------------------------------------------------------------------------------------------------
# 현재 사용자의 아이디명과 그룹정보
export USERNAME=`id -u -n`
export GROUPNAME=`id -g -n`


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
export EXTENSION='.tar.gz'
export GIT_EXTENSION='.git'
export XZ_EXTENSION='.tar.xz'
export BZ2_EXTENSION='.tar.bz2'


# ----------------------------------------------------------------------------------------------------------------------
# .bashrc 경로 설정.
export BASH_FILE=${HOME}/.bashrc


# ----------------------------------------------------------------------------------------------------------------------
# Server Home 경로 설정.
if [[ -z ${SERVER_HOME} ]]; then
    printf "Enter the server home path"
    read -e -p " > " SERVER_HOME
    while [[ -z ${SERVER_HOME} ]]; do
        printf "Enter the server home path"
        read -e -p " > " SERVER_HOME
    done
    echo
fi

mkdir -p ${SERVER_HOME}
if [[ ! -d ${SERVER_HOME} ]]; then
    echo
    printf "\"\e[00;31m${SERVER_HOME}\e[00m\" 디렉토리를 생성 후 다시 시도해주세요.\n"
    exit 1
fi
export SERVER_HOME=${SERVER_HOME%/}


#-----------------------------------------------------------------------------------------------------------------------
# 소스 디렉토리와 서버 디렉토리 설정.
# if [[ -z ${SRC_HOME} ]]; then
#     export SRC_HOME=${HOME}/src
#     if [ ! -d "${SRC_HOME}" ]; then
#         printf "\n\e[00;32m| create ${SRC_HOME} dir...\e[00m\n"
#         mkdir -p ${SRC_HOME}
#     fi
# fi
# export SRC_HOME=${SRC_HOME}
export SRC_HOME=/var/tmp


# ----------------------------------------------------------------------------------------------------------------------
# Programe Home 경로 설정.
# opt : 애드온(Add-on) 소프트웨어 패키지 디렉토리
#export PROGRAME_HOME='/opt/local'
if [[ -z ${PROGRAME_HOME} ]]; then
    printf "Enter the program install path (ex. /opt/local)"
    read -e -p " > " PROGRAME_HOME
    echo
fi
if [[ ! -z ${PROGRAME_HOME} ]] && [[ ! -d "${SERVER_HOME}${PROGRAME_HOME}" ]]; then
    export PROGRAME_HOME=/${PROGRAME_HOME%/}
    PROGRAME_HOME=${PROGRAME_HOME/\/\//\/}
    printf "Create program install directory : \e[00;32m${SERVER_HOME}${PROGRAME_HOME}\e[00m\n"
    mkdir -p ${SERVER_HOME}${PROGRAME_HOME}
fi


# ----------------------------------------------------------------------------------------------------------------------
# Java 설정.
export JAVA_ALIAS='java'

#export JAVA_HOME='jdk1.8.0_191'
#export JAVA_DOWNLOAD_URL='http://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/server-jre-8u191-linux-x64.tar.gz'

# export JAVA_HOME='jdk1.7.0_79'
# export JAVA_DOWNLOAD_URL='http://shell.pe.kr/document/java/jdk-7u79/jdk-7u79-linux-x64.tar.gz'
#export JAVA_DOWNLOAD_URL='http://shell.pe.kr/document/java/jdk-7u79/server-jre-7u79-linux-x64.tar.gz'


# ----------------------------------------------------------------------------------------------------------------------
# Open Java 설정.
#export OPENJAVA_ALIAS='java'
#export OPENJAVA_HOME='openjdk-11.0.8'
#export OPENJAVA_DOWNLOAD_URL='https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_11.0.8_10.tar.gz'
export OPENJAVA_ALIAS='java'
export OPENJAVA_HOME='openjdk-8u275-b01'
export OPENJAVA_DOWNLOAD_URL='https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_x64_linux_8u275b01.tar.gz'

# ----------------------------------------------------------------------------------------------------------------------
# PCRE
# export PCRE_ALIAS='pcre'
if [[ -z ${PCRE_ALIAS} ]]; then
    printf "Enter the pcre alias (ex. pcre)"
    read -e -p " > " PCRE_ALIAS
    echo
fi

export PCRE_VERSION="8.44"
export PCRE_DOWNLOAD_URL="http://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz"
export PCRE_NAME=${PCRE_DOWNLOAD_URL##+(*/)}
export PCRE_HOME=${PCRE_NAME%$EXTENSION}


# ----------------------------------------------------------------------------------------------------------------------
# OpenSSL 설정.
# export OPENSSL_ALIAS='openssl'
if [[ -z ${OPENSSL_ALIAS} ]]; then
    printf "Enter the openssl alias (ex. openssl)"
    read -e -p " > " OPENSSL_ALIAS
    echo
fi

export OPENSSL_VERSION="1.1.1i"
export OPENSSL_DOWNLOAD_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
export OPENSSL_NAME=${OPENSSL_DOWNLOAD_URL##+(*/)}
export OPENSSL_HOME=${OPENSSL_NAME%$EXTENSION}


# ----------------------------------------------------------------------------------------------------------------------
# APR
# export APR_ALIAS='apr'
if [[ -z ${APR_ALIAS} ]]; then
    printf "Enter the apr alias (ex. apr)"
    read -e -p " > " APR_ALIAS
    echo
fi

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
export APR_ICONV_NAME=${APR_ICONV_DOWNLOAD_URL##+(*/)}
export APR_ICONV_HOME=${APR_ICONV_NAME%$EXTENSION}

