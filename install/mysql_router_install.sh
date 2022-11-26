#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/mysql_router_install.sh)

# MySQL Router는 c++11을 이용해서 빌드한다.
# yum install centos-release-scl-rh
# yum install devtoolset-3-gcc devtoolset-3-binutils devtoolset-3-gcc-c++
# . /opt/rh/devtoolset-3/enable


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


#-----------------------------------------------------------------------------------------------------------------------
MYSQL_ROUTER_DOWNLOAD_URL='https://dev.mysql.com/get/Downloads/MySQL-Router/mysql-router-2.0.4.tar.gz'


#-----------------------------------------------------------------------------------------------------------------------
MYSQL_ALIAS='mysql'


#-----------------------------------------------------------------------------------------------------------------------
# MySQL Router 설치.
MYSQL_ROUTER_NAME=${MYSQL_ROUTER_DOWNLOAD_URL##+(*/)}
MYSQL_ROUTER_HOME=${MYSQL_ROUTER_NAME%$EXTENSION}
MYSQL_ROUTER_ALIAS='mysqlrouter'


#-----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME                 :\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME              :\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| MYSQL_ROUTER_HOME        :\e[00m ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_ROUTER_HOME}\n"
printf "\e[00;32m| MYSQL_ROUTER_DATA_HOME   :\e[00m ${DATA_HOME}\n"
printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"
echo


#-----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_ROUTER_HOME}" ]]; then
    printf "\e[00;32m기존에 설치된 ${MYSQL_ROUTER_HOME}가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    echo

    while [[ true ]]; do
        read -e -p "Enter whether to install \"${MYSQL_ROUTER_HOME}\" service? [Y / n] > " INSTALL_CHECK
        if [[ "$(uppercase ${INSTALL_CHECK})" = "Y" || "$(uppercase ${INSTALL_CHECK})" = "N" ]]; then
            break;
        fi
    done

    if [[ "$(uppercase ${INSTALL_CHECK})" != "Y" ]]; then
        printf "\n\e[00;31m \"${MYSQL_ROUTER_HOME}\" 서비스 생성 취소...\e[00m\n\n"
        exit 1
    fi
fi


#-----------------------------------------------------------------------------------------------------------------------
# MySQL Router 설치.
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_ROUTER_HOME}
sudo rm -rf ${SERVER_HOME}/${MYSQL_ROUTER_ALIAS}*

cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${MYSQL_ROUTER_NAME}" ]; then
    printf "\n \e[00;32m ${MYSQL_ROUTER_NAME} download...\e[00m\n"
    wget ${MYSQL_ROUTER_DOWNLOAD_URL}
else
    printf "\n \e[00;32m ${MYSQL_ROUTER_NAME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${MYSQL_ROUTER_HOME}
fi

tar xvzf ${MYSQL_ROUTER_NAME}
cd ${SRC_HOME}/${MYSQL_ROUTER_HOME}

. /opt/rh/devtoolset-3/enable

# cmake 를 이용한 configure
INSTALL_CONFIG="-DCMAKE_INSTALL_PREFIX=${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_ROUTER_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_MYSQL=${SERVER_HOME}/${MYSQL_ALIAS}"
INSTALL_CONFIG="${INSTALL_CONFIG} -DINSTALL_LAYOUT=STANDALONE"

# cmake 를 이용한 configure
cmake ${INSTALL_CONFIG}

# 컴파일
make

# 설치
make install

cd ${SERVER_HOME}
sudo ln -s ./${PROGRAME_HOME}/${MYSQL_ROUTER_HOME} ${MYSQL_ROUTER_ALIAS}

if [[ -d "${SRC_HOME}/${MYSQL_ROUTER_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${MYSQL_ROUTER_HOME}
fi

echo
printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
printf " \e[00;32m ${MYSQL_HOME} install success...\e[00m\n"
printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
