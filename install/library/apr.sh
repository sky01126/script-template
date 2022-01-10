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

if [[ ! -z ${APR_ALIAS} ]]; then
    rm -rf ${SERVER_HOME}/${APR_ALIAS}
fi
rm -rf ${SERVER_HOME}${PROGRAME_HOME}/${APR_HOME}

printf "\e[00;32m| ${APR_HOME} / ${APR_ICONV_NAME} / ${APR_UTIL_HOME} install start...\e[00m\n"

# delete the compile source
if [[ -d "${SRC_HOME}/${APR_HOME}" ]]; then
    printf "\e[00;32m| ${APR_HOME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${APR_HOME}
fi
if [[ -d "${SRC_HOME}/${APR_UTIL_HOME}" ]]; then
    printf "\e[00;32m| ${APR_UTIL_HOME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${APR_UTIL_HOME}
fi
if [[ -d "${SRC_HOME}/${APR_ICONV_HOME}" ]]; then
    printf "\e[00;32m| ${APR_ICONV_HOME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${APR_ICONV_HOME}
fi

# ----------------------------------------------------------------------------------------------------------------------
# APR Install
cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${APR_NAME}" ]; then
    printf "\e[00;32m| ${APR_NAME} download (URL : ${APR_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${APR_DOWNLOAD_URL}
fi

tar xvzf ${APR_NAME}
cd ${SRC_HOME}/${APR_HOME}

./configure --prefix=${SERVER_HOME}${PROGRAME_HOME}/${APR_HOME}
make
make install
sleep 0.5

# ----------------------------------------------------------------------------------------------------------------------
# APR Util Install
cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${APR_UTIL_NAME}" ]; then
    printf "\e[00;32m| ${APR_UTIL_NAME} download (URL : ${APR_UTIL_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${APR_UTIL_DOWNLOAD_URL}
fi

tar xvzf ${APR_UTIL_NAME}
cd ${SRC_HOME}/${APR_UTIL_HOME}

./configure --prefix=${SERVER_HOME}${PROGRAME_HOME}/${APR_HOME}                 \
            --with-apr=${SERVER_HOME}${PROGRAME_HOME}/${APR_HOME}
make
make install

# # ----------------------------------------------------------------------------------------------------------------------
# # APR Iconv Install
# cd ${SRC_HOME}

# # verify that the source exists download
# if [ ! -f "${SRC_HOME}/${APR_ICONV_NAME}" ]; then
#     printf "\e[00;32m| ${APR_ICONV_NAME} download (URL : ${APR_ICONV_DOWNLOAD_URL})\e[00m\n"
#     curl -L -O ${APR_ICONV_DOWNLOAD_URL}
# fi

# tar xvzf ${APR_ICONV_NAME}
# cd ${SRC_HOME}/${APR_ICONV_HOME}

# ./configure --prefix=${SERVER_HOME}${PROGRAME_HOME}/${APR_HOME}                 \
#             --with-apr=${SERVER_HOME}${PROGRAME_HOME}/${APR_HOME}
# make
# make install
# sleep 0.5

# ----------------------------------------------------------------------------------------------------------------------
if [[ ! -z ${APR_ALIAS} ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${APR_HOME} ${APR_ALIAS}
fi

# ----------------------------------------------------------------------------------------------------------------------
# Install source delete
if [[ -d "${SRC_HOME}/${APR_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${APR_HOME}
fi
if [[ -d "${SRC_HOME}/${APR_UTIL_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${APR_UTIL_HOME}
fi
if [[ -d "${SRC_HOME}/${APR_ICONV_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${APR_ICONV_HOME}
fi

printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| ${APR_HOME} / ${APR_ICONV_NAME} / ${APR_UTIL_HOME} install success...\e[00m\n"
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
sleep 0.5

