#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/docker_tomcat_delete.sh)

# -------------------------------------------------------------
# docker의 인스턴스를 이용해서 RUN을 실행한다.
# 현재의 스크립트는 Tomcat 8.0.47 버전으로 생성하는 샘플이다.
# -------------------------------------------------------------


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


# -------------------------------------------------------------------------------------------------------------------
# 대문자 변환
uppercase() {
    echo $* | tr "[a-z]" "[A-Z]"
}

# 소문자변환
lowercase() {
    echo $* | tr "[A-Z]" "[a-z]"
}


# ----------------------------------------------------------------------------------------------------------------------
# 아래 정보를 미리 설정하면 바로 등록된다.
# ex. sh docker_tomcat_delete.sh test01
CONTAINER_NAME=$1


# ----------------------------------------------------------------------------------------------------------------------
# Docker Container Name 설정.
CONTAINER_NAME=${CONTAINER_NAME%/}
while [[ -z ${CONTAINER_NAME} ]]; do
    read -e -p 'Enter the docker container name> ' CONTAINER_NAME
done
CONTAINER_NAME=${CONTAINER_NAME%/}


# ----------------------------------------------------------------------------------------------------------------------
# 기존에 생성된 컨테이너가 있는지 확인한다.
OLD_CONTAINER_NAME=`docker ps -a | grep -v CONTAINER_ID | grep ${CONTAINER_NAME} | awk '{print $1}'`

# 컨테이너가 없으면 노티 후 종료한다.
if [[ -z ${OLD_CONTAINER_NAME} ]]; then
    echo
    printf "\e[00;31m | \"${CONTAINER_NAME}\" Container는 존재하지 않습니다.\e[00m\n"
    echo
    exit 0
fi

# docker가 실행중이면 stop한다.
OLD_CONTAINER_STARTED=`docker ps | grep -v CONTAINER_ID | grep ${CONTAINER_NAME} | awk '{print $1}'`
if [[ ! -z ${OLD_CONTAINER_STARTED} ]]; then
    echo
    printf "\e[00;32m | \"${CONTAINER_NAME}\" stop docker tomcat...\e[00m\n"
    echo
    docker exec ${CONTAINER_NAME} /data/server/tomcat/bin/stop.sh

    echo
    printf "\e[00;32m | \"${CONTAINER_NAME}\" stop docker container...\e[00m\n"
    echo
    docker stop ${CONTAINER_NAME}
fi

echo
printf "\e[00;32m | \"${CONTAINER_NAME}\" delete docker tomcat...\e[00m\n"
echo
docker rm ${CONTAINER_NAME}
