#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/docker_tomcat_create.sh)

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
# ex. sh docker_tomcat_create.sh dev test01 211.62.48.92 10081
SPRING_ACTIVE_PROFILE=$1
CONTAINER_NAME=$2
HOST_SERVER_IP=$3
HOST_HTTP_PORT=$4


# ----------------------------------------------------------------------------------------------------------------------
# Spring profiles active 설정.
if [[ -z ${SPRING_ACTIVE_PROFILE} ]]; then
    SPRING_ACTIVE_PROFILE='dev'
fi


# ----------------------------------------------------------------------------------------------------------------------
# Docker Container Name 설정.
CONTAINER_NAME=${CONTAINER_NAME%/}
while [[ -z ${CONTAINER_NAME} ]]; do
    read -e -p 'Enter the docker container name> ' CONTAINER_NAME
done
CONTAINER_NAME=${CONTAINER_NAME%/}


# -------------------------------------------------------------------------------------------------------------------
## 서버 아이피 표시.
#PRIVATE_ADDRESS=`echo '- ' | ip addr | grep "inet " | grep brd | awk '{print $2}' | grep '^192' | awk -F/ '{print $1}'`
if [[ -z ${HOST_SERVER_IP} ]]; then
    echo
    printf "\e[00;32m------------------------------- IP Address -------------------------------\e[00m\n"
    if [[ "$OS" == "darwin" ]]; then # Mac OS
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
    else
        echo '- ' | ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'
    fi
    printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"

    ## 서버 아이피 설정.
    read -e -p 'Enter the server ip address> ' HOST_SERVER_IP
    while [[ -z ${HOST_SERVER_IP} ]]; do
        read -e -p 'Enter the server ip address> ' HOST_SERVER_IP
    done
fi


# ----------------------------------------------------------------------------------------------------------------------
# HOST 서버에서 Docker Tomcat으로 접속할 포트 설정.
echo
while [[ -z ${HOST_HTTP_PORT} ]] || [[ $HOST_HTTP_PORT != ?(-)+([0-9.]) ]]; do
    read -e -p 'Enter the host http port> ' HOST_HTTP_PORT
done
HOST_AJP_PORT=$(($HOST_HTTP_PORT + 10))


# ----------------------------------------------------------------------------------------------------------------------
echo
printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| CONTAINER_NAME :\e[00m ${CONTAINER_NAME}\n"
printf "\e[00;32m| HOST_SERVER_IP :\e[00m ${HOST_SERVER_IP}\n"
printf "\e[00;32m| HOST_HTTP_PORT :\e[00m ${HOST_HTTP_PORT}\n"
printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"
echo



# ----------------------------------------------------------------------------------------------------------------------
# 기존에 생성된 컨테이너가 있는지 확인한다.
ORG_CONTAINER_NAME=`docker ps -a | grep -v CONTAINER_ID | grep ${CONTAINER_NAME} | awk '{print $1}'`

# 컨테이너가 없으면 신규로 생성한다.
if [[ -z ${ORG_CONTAINER_NAME} ]]; then
    # 팔요한 경우 HOST의 디렉토리를 MOUNT한다.
    # ex. -v /data/server/tomcat/test01/logs:/data/server/tomcat/logs
    echo "Create new docker container: ${CONTAINER_NAME}"

    # Docker Hub에서 가져와서 설치.
    #docker run -i -t --name ${CONTAINER_NAME} -d        \
    #    -p ${HOST_HTTP_PORT}:8080                       \
    #    -p ${HOST_AJP_PORT}:8009                        \
    #    sky01126/tomcat:8.0.47-jdk8 /bin/bash

    # 로컬에 설치된 Images에서 설치.
    docker run -i -t --name ${CONTAINER_NAME} -d        \
        -p ${HOST_HTTP_PORT}:8080                       \
        -p ${HOST_AJP_PORT}:8009                        \
        tomcat:8.0.47-jdk8 /bin/bash

    sleep 2

    # Tomcat의 setenv.sh 파일에 host.server 정보 추가.
    docker exec ${CONTAINER_NAME} sh -c  "echo \"# Setting Docker Host Server Info
export JAVA_OPTS=\\\"\\\$JAVA_OPTS -Dspring.profiles.active=${SPRING_ACTIVE_PROFILE}\\\"
export JAVA_OPTS=\\\"\\\$JAVA_OPTS -Ddocker.host.server.address=${HOST_SERVER_IP}\\\"
export JAVA_OPTS=\\\"\\\$JAVA_OPTS -Ddocker.host.server.port=${HOST_HTTP_PORT}\\\"
\" >> /data/server/tomcat/bin/setenv.sh"

else
    # docker가 실행되어있는지 확인한다.
    OLD_CONTAINER_STARTED=`docker ps | grep -v CONTAINER_ID | grep ${CONTAINER_NAME} | awk '{print $1}'`
    if [[ ! -z ${OLD_CONTAINER_STARTED} ]]; then
        printf "\e[00;32m\"${CONTAINER_NAME}\" docker container는 실행 중입니다.\e[00m\n"
        echo
        exit 0
    fi

    echo "\"${CONTAINER_NAME}\" docker container를 시작합니다."
    docker start ${CONTAINER_NAME}
fi

# 소스를 배포하는 스크립트 설정.
# >>>>> 샘플 <<<<<
#docker exec ${CONTAINER_NAME} sh -c 'rm -rf /data/server/tomcat/webapps/*'
#docker cp /home/user/ROOT.war ${CONTAINER_NAME}:/data/server/tomcat/webapps/

# Tomcat start...
docker exec ${CONTAINER_NAME} /data/server/tomcat/bin/start.sh

