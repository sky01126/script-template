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

echo "---------------- OpenSSL - v2022.01.10.003 ----------------"

# Exit on error
set -e

# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

if [[ ! -z ${OPENSSL_ALIAS} ]]; then
    rm -rf ${SERVER_HOME}/${OPENSSL_ALIAS}
fi
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}

echo ${SRC_HOME}
cd ${SRC_HOME}

printf "\e[00;32m| ${OPENSSL_HOME} install start...\e[00m\n"

# delete the compile source
if [[ -d "${SRC_HOME}/${OPENSSL_HOME}" ]]; then
    printf "\e[00;32m| ${SRC_HOME}/${OPENSSL_HOME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${OPENSSL_HOME}
fi

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${OPENSSL_NAME}" ]; then
    printf "\e[00;32m| ${OPENSSL_NAME} download (URL : ${OPENSSL_DOWNLOAD_URL})\e[00m\n"
    curl -O ${OPENSSL_DOWNLOAD_URL}
fi

tar xvzf ${OPENSSL_NAME}
cd ${SRC_HOME}/${OPENSSL_HOME}

# Apache HTTP 구동시 Cannot load modules/mod_ssl.so into server: libssl.so.1.1.1: cannot open shared object file
# 출처: https://springboot.cloud/22
# libssl.so.1.1, libcrypto.so.1.1 라이브러리를 /usr/lib64/ 디렉토리에 복사
# sudo cp libssl.so.1.1 /usr/lib64/
# sudo cp libcrypto.so.1.1 /usr/lib64/

./config --prefix=${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME} -fPIC shared
make
make install

if [[ ! -z ${OPENSSL_ALIAS} ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${OPENSSL_HOME} ${OPENSSL_ALIAS}

#    if [[ -f ${BASH_FILE} ]]; then
#        SET_OPENSSL_HOME=`awk "/# OpenSSL Home/" ${BASH_FILE}`
#        if [[ ! -n ${SET_OPENSSL_HOME} ]]; then
#            printf "\e[00;32m| Setting openssl home path...\e[00m\n"
#
#            echo "# OpenSSL Home
#export OPENSSL_HOME=\"${SERVER_HOME}/${OPENSSL_ALIAS}\"
#export PATH=\$OPENSSL_HOME/bin:\$PATH
#export LD_LIBRARY_PATH=\$OPENSSL_HOME/lib:\$LD_LIBRARY_PATH
#    " >> ${BASH_FILE}
#
#            source ${BASH_FILE}
#        fi
#    fi

    sudo cp ${SERVER_HOME}/${OPENSSL_ALIAS}/lib/libssl.so.1.1 /usr/lib64/
    sudo cp ${SERVER_HOME}/${OPENSSL_ALIAS}/lib/libcrypto.so.1.1 /usr/lib64/
else
    sudo cp ${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}/lib/libssl.so.1.1 /usr/lib64/
    sudo cp ${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}/lib/libcrypto.so.1.1 /usr/lib64/
fi

# Install source delete
if [[ -d "${SRC_HOME}/${OPENSSL_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${OPENSSL_HOME}
fi


printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| ${OPENSSL_HOME} install success...\e[00m\n"
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
sleep 0.5

