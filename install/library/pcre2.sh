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

if [[ -n "${PCRE2_ALIAS}" ]]; then
    rm -rf ${SERVER_HOME}/${PCRE2_ALIAS}
fi
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${PCRE2_HOME}

cd ${SRC_HOME}

printf "\e[00;32m| ${PCRE2_HOME} install start...\e[00m\n"

# delete the compile source
if [[ -d "${SRC_HOME}/${PCRE2_HOME}" ]]; then
    printf "\e[00;32m| ${SRC_HOME}/${PCRE2_HOME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${PCRE2_HOME}
fi

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${PCRE2_NAME}" ]; then
    printf "\e[00;32m| ${PCRE2_NAME} download (URL : ${PCRE2_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${PCRE2_DOWNLOAD_URL}
fi

tar xvzf ${PCRE2_NAME}
cd ${SRC_HOME}/${PCRE2_HOME}

./configure --prefix=${SERVER_HOME}/${PROGRAME_HOME}/${PCRE2_HOME}              \
            --enable-pcre2-16                                                   \
            --enable-pcre2-32                                                   \
            --enable-jit
make
make install


if [[ -n "${PCRE2_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s .${PROGRAME_HOME}/${PCRE2_HOME} ${PCRE2_ALIAS}
fi


# Install source delete
if [[ -d "${SRC_HOME}/${PCRE2_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${PCRE2_HOME}
fi

printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| ${PCRE2_HOME} install success...\e[00m\n"
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
sleep 0.5

