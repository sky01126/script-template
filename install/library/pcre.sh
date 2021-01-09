#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티의 setting.sh 읽기
# source /dev/stdin  <<< "$(curl -f -L -sS  http://shell.pe.kr/document/install/library/setting.sh)"

# Exit on error
set -e

# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

if [[ ! -z ${PCRE_ALIAS} ]]; then
    rm -rf ${SERVER_HOME}/${PCRE_ALIAS}
fi
rm -rf ${SERVER_HOME}${PROGRAME_HOME}/${PCRE_HOME}

cd ${SRC_HOME}

printf "\e[00;32m| ${PCRE_HOME} install start...\e[00m\n"

# delete the compile source
if [[ -d "${SRC_HOME}/${PCRE_HOME}" ]]; then
    printf "\e[00;32m| ${SRC_HOME}/${PCRE_HOME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${PCRE_HOME}
fi

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${PCRE_NAME}" ]; then
    printf "\e[00;32m| ${PCRE_NAME} download (URL : ${PCRE_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${PCRE_DOWNLOAD_URL}
fi

tar xvzf ${PCRE_NAME}
cd ${SRC_HOME}/${PCRE_HOME}

./configure --prefix=${SERVER_HOME}${PROGRAME_HOME}/${PCRE_HOME} --enable-pcre16 --enable-pcre32 --enable-utf
make
make install


if [[ ! -z ${PCRE_ALIAS} ]]; then
    cd ${SERVER_HOME}
    ln -s .${PROGRAME_HOME}/${PCRE_HOME} ${PCRE_ALIAS}
fi


# Install source delete
if [[ -d "${SRC_HOME}/${PCRE_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${PCRE_HOME}
fi

printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| ${PCRE_HOME} install success...\e[00m\n"
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
sleep 0.5

