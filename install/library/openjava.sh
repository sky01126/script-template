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
# CentOS 7 에서 "/lib/ld-linux.so.2: bad ELF interpreter" 에러 발생 시 아래 패키지 설치
# sudo yum install -y ld-linux.so.2

# Exit on error
set -e


# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

rm -rf ${SERVER_HOME}/${OPENJAVA_ALIAS}
rm -rf ${SERVER_HOME}${PROGRAME_HOME}/${OPENJAVA_HOME}

printf "\e[00;32m| ${OPENJAVA_HOME} install start...\e[00m\n"

cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${OPENJAVA_DOWNLOAD_URL##+(*/)}" ]; then
    printf "\e[00;32m| ${OPENJAVA_DOWNLOAD_URL##+(*/)} download (URL : ${OPENJAVA_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${OPENJAVA_DOWNLOAD_URL}
fi

tar xvzf ${OPENJAVA_DOWNLOAD_URL##+(*/)} -C ${SERVER_HOME}${PROGRAME_HOME}

cd ${SERVER_HOME}
ln -s ./${PROGRAME_HOME}/${OPENJAVA_HOME} ${OPENJAVA_ALIAS}

if [[ -f ${BASH_FILE} ]]; then
    SET_OPENJAVA_HOME=`awk "/# Java Home/" ${BASH_FILE}`
    if [[ ! -n ${SET_OPENJAVA_HOME} ]]; then
        printf "\e[00;32m| Setting java home path...\e[00m\n"

        echo "# Java Home
export JAVA_HOME=\"${SERVER_HOME%/}/${OPENJAVA_ALIAS}\"
export PATH=\$JAVA_HOME/bin:\$PATH
" >> ${BASH_FILE}

        source ${BASH_FILE}
    fi
fi

printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| ${OPENJAVA_HOME} install success...\e[00m\n"
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
sleep 0.5

