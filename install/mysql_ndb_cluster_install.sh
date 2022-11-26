#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/mysql_ndb_cluster_install.sh)

# yum install -y zlib


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
# 현재 사용자의 아이디명과 그룹정보
USERNAME=`id -u -n`
GROUPNAME=`id -g -n`


#-----------------------------------------------------------------------------------------------------------------------
# 대문자 변환
uppercase() {
    echo $* | tr "[a-z]" "[A-Z]"
}

# 소문자변환
lowercase() {
    echo $* | tr "[A-Z]" "[a-z]"
}


#-----------------------------------------------------------------------------------------------------------------------
# Server Home 경로 설정.
# export SERVER_HOME=/home/server
if [[ -z ${SERVER_HOME} ]]; then
    read -e -p 'Enter the server home path> ' SERVER_HOME
    while [[ -z ${SERVER_HOME} ]]; do
        read -e -p 'Enter the server home path> ' SERVER_HOME
    done
    echo
fi
if [[ ! -d ${SERVER_HOME} ]]; then
    printf "\n\e[00;31m| \"${SERVER_HOME}\" 디렉토리를 생성 후 다시 시도해주세요.\e[00m\n"
    exit 1
fi
export SERVER_HOME=${SERVER_HOME}



#-----------------------------------------------------------------------------------------------------------------------
# 소스 디렉토리와 서버 디렉토리 설정.
if [[ -z ${SRC_HOME} ]]; then
    SRC_HOME=${HOME}/src
    if [ ! -d "${SRC_HOME}" ]; then
        printf "\n\e[00;32m| create ${SRC_HOME} dir...\e[00m\n"
        mkdir -p ${SRC_HOME}
    fi
fi


#-----------------------------------------------------------------------------------------------------------------------
# Programe Home 경로 설정.
# opt : 애드온(Add-on) 소프트웨어 패키지 디렉토리
PROGRAME_HOME='opt/local'
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}" ]]; then
    echo " | CREATE - ${SERVER_HOME}/${PROGRAME_HOME}"
    sudo mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}
fi

sudo chown -R ${USERNAME}:${GROUPNAME} ${SERVER_HOME}


#-----------------------------------------------------------------------------------------------------------------------
# File Extension
export EXTENSION='.tar.gz'


# ----------------------------------------------------------------------------------------------------------------------
# Java
JAVA_ALIAS='java'
JAVA_HOME='jdk1.8.0_151'
JAVA_DOWNLOAD_URL='http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-linux-x64.tar.gz'


# ----------------------------------------------------------------------------------------------------------------------
# OpenSSL
OPENSSL_VERSION="1.0.2n"
OPENSSL_DOWNLOAD_URL="https://ftp.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"


#-----------------------------------------------------------------------------------------------------------------------
BOOST_VERSION="1.59.0"
BOOST_DOWNLOAD_URL="https://sourceforge.net/projects/boost/files/boost/${BOOST_VERSION}/boost_${BOOST_VERSION}.tar.gz"

MYSQL_CLUSTER_VERSION="7.5.8"
MYSQL_CLUSTER_DOWNLOAD_URL="https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.5/mysql-cluster-gpl-${MYSQL_CLUSTER_VERSION}.tar.gz"


#-----------------------------------------------------------------------------------------------------------------------
MYSQL_CLUSTER_NAME=${MYSQL_CLUSTER_DOWNLOAD_URL##+(*/)}
MYSQL_CLUSTER_HOME=${MYSQL_CLUSTER_NAME%$EXTENSION}
MYSQL_CLUSTER_ALIAS='mysql'


#-----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME                 :\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME              :\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| MYSQL_CLUSTER_HOME       :\e[00m ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_CLUSTER_HOME}\n"
printf "\e[00;32m| MYSQL_CLUSTER_DATA_HOME  :\e[00m ${DATA_HOME}\n"
printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"
echo


#-----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_CLUSTER_HOME}" ]]; then
    printf "\e[00;32m기존에 설치된 ${MYSQL_CLUSTER_HOME}가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    echo

    while [[ true ]]; do
        read -e -p "Enter whether to install \"${MYSQL_CLUSTER_HOME}\" service? [Y / n] > " INSTALL_CHECK
        if [[ "$(uppercase ${INSTALL_CHECK})" = "Y" || "$(uppercase ${INSTALL_CHECK})" = "N" ]]; then
            break;
        fi
    done

    if [[ "$(uppercase ${INSTALL_CHECK})" != "Y" ]]; then
        printf "\n\e[00;31m \"${MYSQL_CLUSTER_HOME}\" 서비스 생성 취소...\e[00m\n\n"
        exit 1
    fi
fi


# ----------------------------------------------------------------------------------------------------------------------
# Java 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${JAVA_HOME}" ]]; then
    printf "\n \e[00;32m ${JAVA_HOME} install start...\e[00m\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [ ! -f "${SRC_HOME}/${JAVA_DOWNLOAD_URL##+(*/)}" ]; then
        printf "\n \e[00;32m ${JAVA_DOWNLOAD_URL##+(*/)} download...\e[00m\n"
        curl -L -b "oraclelicense=a" -O ${JAVA_DOWNLOAD_URL}
    fi

    tar xvzf ${JAVA_DOWNLOAD_URL##+(*/)} -C ${SERVER_HOME}/${PROGRAME_HOME}

    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${JAVA_HOME} ${JAVA_ALIAS}

    printf " \e[00;32m----------------------------------------------\e[00m\n"
    printf " \e[00;32m ${JAVA_HOME} install success...\e[00m\n"
    printf " \e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
elif [[ ! -d "${SERVER_HOME}/${JAVA_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${JAVA_HOME} ${JAVA_ALIAS}

    printf " \e[00;32m----------------------------------------------\e[00m\n"
    printf " \e[00;32m ${JAVA_ALIAS} link success...\e[00m\n"
    printf " \e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# ----------------------------------------------------------------------------------------------------------------------
# OpenSSL 설치 여부 확인
OPENSSL_NAME=${OPENSSL_DOWNLOAD_URL##+(*/)}
OPENSSL_HOME=${OPENSSL_NAME%$EXTENSION}
OPENSSL_ALIAS='openssl'
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}" ]]; then
    cd ${SRC_HOME}

    printf "\n \e[00;32m ${OPENSSL_HOME} install start...\e[00m\n"

    # delete the compile source
    if [[ -d "${SRC_HOME}/${OPENSSL_HOME}" ]]; then
        printf "\n \e[00;32m ${SRC_HOME}/${OPENSSL_HOME} delete...\e[00m\n"
        rm -rf ${SRC_HOME}/${OPENSSL_HOME}
    fi

    # verify that the source exists download
    if [ ! -f "${SRC_HOME}/${OPENSSL_NAME}" ]; then
        printf "\n \e[00;32m ${OPENSSL_NAME} download...\e[00m\n"
        curl -O ${OPENSSL_DOWNLOAD_URL}
    fi

    tar xvzf ${OPENSSL_NAME}
    cd ${SRC_HOME}/${OPENSSL_HOME}

    ./config --prefix=${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME} -fPIC
    make
    make install

    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${OPENSSL_HOME} ${OPENSSL_ALIAS}

    # Install source delete
    if [[ -d "${SRC_HOME}/${OPENSSL_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${OPENSSL_HOME}
    fi

    printf " \e[00;32m----------------------------------------------\e[00m\n"
    printf " \e[00;32m ${OPENSSL_HOME} install success...\e[00m\n"
    printf " \e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
elif [[ ! -d "${SERVER_HOME}/${OPENSSL_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${OPENSSL_HOME} ${OPENSSL_ALIAS}

    printf " \e[00;32m----------------------------------------------\e[00m\n"
    printf " \e[00;32m ${OPENSSL_ALIAS} link success...\e[00m\n"
    printf " \e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


#-----------------------------------------------------------------------------------------------------------------------
# Boost 다운로드.
BOOST_NAME=${BOOST_DOWNLOAD_URL##+(*/)}
BOOST_HOME=${BOOST_NAME%$EXTENSION}

cd ${SRC_HOME}
if [ ! -f "${SRC_HOME}/${BOOST_NAME}" ]; then
    printf "\n \e[00;32m ${BOOST_NAME} download...\e[00m\n"
    curl -L -O ${BOOST_DOWNLOAD_URL}
fi

tar xvzf ${BOOST_NAME}


# ----------------------------------------------------------------------------------------------------------------------
# Java Home Setting
JAVA_HOME=${SERVER_HOME}/${JAVA_ALIAS}
PATH=${JAVA_HOME}/bin:${PATH}


#-----------------------------------------------------------------------------------------------------------------------
# MySQL Cluster 설치.
cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${MYSQL_CLUSTER_NAME}" ]; then
    printf "\n \e[00;32m ${MYSQL_CLUSTER_NAME} download...\e[00m\n"
    # curl -O ${MYSQL_DOWNLOAD_URL}
    wget ${MYSQL_DOWNLOAD_URL}
else
    printf "\n \e[00;32m ${MYSQL_CLUSTER_NAME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${MYSQL_CLUSTER_HOME}
fi

tar xvzf ${MYSQL_CLUSTER_NAME}
cd ${SRC_HOME}/${MYSQL_CLUSTER_HOME}

# cmake 를 이용한 configure
INSTALL_CONFIG="-DCMAKE_INSTALL_PREFIX=${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_CLUSTER_HOME}"
#INSTALL_CONFIG="${INSTALL_CONFIG} -DMYSQL_CLUSTER_DATADIR=${MYSQL_CLUSTER_DATADIR}"
INSTALL_CONFIG="${INSTALL_CONFIG} -DCMAKE_BUILD_TYPE=Release"
#INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_EMBEDDED_SERVER=ON"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_SSL=${SERVER_HOME}/${OPENSSL_ALIAS}"
#INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_SSL=system"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_ZLIB=system"
INSTALL_CONFIG="${INSTALL_CONFIG} -DDOWNLOAD_BOOST=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_BOOST=${SRC_HOME}/${BOOST_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} -DDEFAULT_CHARSET=utf8"
INSTALL_CONFIG="${INSTALL_CONFIG} -DDEFAULT_COLLATION=utf8_general_ci"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_EXTRA_CHARSETS=all"
INSTALL_CONFIG="${INSTALL_CONFIG} -DENABLED_LOCAL_INFILE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_MYISAM_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_ARCHIVE_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_ARCHIVE_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_INNOBASE_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_PARTITION_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_BLACKHOLE_STORAGE_ENGINE=1"

# cmake 를 이용한 configure
cmake ${INSTALL_CONFIG}

# 컴파일
make

# 설치
make install

cd ${SERVER_HOME}
sudo ln -s ./${PROGRAME_HOME}/${MYSQL_CLUSTER_HOME} ${MYSQL_CLUSTER_ALIAS}

if [[ -d "${SRC_HOME}/${BOOST_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${BOOST_HOME}
fi

if [[ -d "${SRC_HOME}/${MYSQL_CLUSTER_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${MYSQL_CLUSTER_HOME}
fi

echo
printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
printf " \e[00;32m ${MYSQL_HOME} install success...\e[00m\n"
printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
