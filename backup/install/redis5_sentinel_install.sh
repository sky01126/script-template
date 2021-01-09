#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/redis5_sentinel_install.sh)


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
EXTENSION='.tar.gz'
TGZ_EXTENSION='.tgz'


# ----------------------------------------------------------------------------------------------------------------------
# Redis
REDIS_VERSION='5.0.7'
REDIS_DOWNLOAD_URL="http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"


# -------------------------------------------------------------------------------------------------------------------
# Friendly Logo
printf "\e[00;32m|     ____           ___         _____            __  _            __ \e[00m\n"
printf "\e[00;32m|    / __ \___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / / \e[00m\n"
printf "\e[00;32m|   / /_/ / _ \/ __  / / ___/   \__ \/ _ \/ __ \/ __/ / __ \/ _ \/ /  \e[00m\n"
printf "\e[00;32m|  / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /   \e[00m\n"
printf "\e[00;32m| /_/ |_|\___/\__,_/_/____/   /____/\___/_/ /_/\__/_/_/ /_/\___/_/    \e[00m\n"
printf "\e[00;32m| :: Version ::                                          (v${REDIS_VERSION})   \e[00m\n"


# ----------------------------------------------------------------------------------------------------------------------
# 멀티의 setting.sh 읽기
if [[ ! -f "${PRGDIR}/library/setting.sh" ]]; then
    curl -f -L -sS  http://shell.pe.kr/document/install/library/setting.sh -o /tmp/setting.sh
    source /tmp/setting.sh
    bash   /tmp/setting.sh
else
    source ${PRGDIR}/library/setting.sh
    bash   ${PRGDIR}/library/setting.sh
fi


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME         :\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME      :\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| PROGRAME_HOME    :\e[00m ${SERVER_HOME}/${PROGRAME_HOME}\n"


# ----------------------------------------------------------------------------------------------------------------------
# Redis 설치 여부 확인
REDIS_NAME=${REDIS_DOWNLOAD_URL##+(*/)}
REDIS_SRC_HOME=${SERVER_HOME}/${PROGRAME_HOME}/${REDIS_NAME%$EXTENSION}
if [[ -z ${REDIS_SRC_HOME} ]] || [[ ! -d ${REDIS_SRC_HOME} ]]; then
    printf "\e[00;32m| ${REDIS_SRC_HOME} install start...\e[00m\n"

    # delete the previous home
    if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${REDIS_SRC_HOME}" ]]; then
        printf "\e[00;32m| ${REDIS_SRC_HOME} delete...\e[00m\n"
        rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${REDIS_SRC_HOME}
    fi

    cd ${SRC_HOME}

    # verify that the source exists download
    if [ ! -f "${SRC_HOME}/${REDIS_NAME}" ]; then
        printf "\e[00;32m| \"${REDIS_NAME}\" download (URL : ${REDIS_DOWNLOAD_URL})\e[00m\n"
        curl -L -O ${REDIS_DOWNLOAD_URL}
    fi

    tar xvzf ${REDIS_NAME} -C ${SERVER_HOME}/${PROGRAME_HOME}
    cd ${REDIS_SRC_HOME}

    make
    #make test
fi

# 디렉토리에서 마지막 /를 제거한다.
REDIS_SRC_HOME=${REDIS_SRC_HOME%/}


# ----------------------------------------------------------------------------------------------------------------------
# Redis Base 경로 설정.
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| Enter the redis base name\e[00m"
read -e -p ' (default. redis-sentinel)> ' REDIS_SENTINEL_HOME
if [[ -z ${REDIS_SENTINEL_HOME} ]]; then
    REDIS_SENTINEL_HOME="redis-sentinel"
fi
REDIS_SENTINEL_HOME=${REDIS_SENTINEL_HOME%/}


# ----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${REDIS_SENTINEL_HOME}" ]]; then
    printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m|\e[00m \e[00;31m기존에 생성된 디렉토리가 있습니다. 삭제하고 다시 생성하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${REDIS_SENTINEL_HOME}\" service\e[00m"
    read -e -p ' [Y / n](enter)] (default. n) > ' CHECK
    if [[ -z "${CHECK}" ]]; then
        CHECK="n"
    fi

    if [[ "$(uppercase ${CHECK})" != "Y" ]]; then
        printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
        printf "\e[00;32m|\e[00m \e[00;31m\"${REDIS_SENTINEL_HOME}\" 서비스 생성 취소...\e[00m\n"
        printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
        exit 1
    fi
fi


# -------------------------------------------------------------------------------------------------------------------
# Read the redis port
if [[ -z ${REDIS_SENTINEL_PORT} ]]; then
    while [[ true ]]; do
        printf "\e[00;32m| Enter the http port\e[00m"
        read -e -p " (default. 26379) > " REDIS_SENTINEL_PORT
        if [[ -z ${REDIS_SENTINEL_PORT} ]]; then
            REDIS_SENTINEL_PORT=26379
            break
        #elif [[ "$REDIS_SENTINEL_PORT" != ^[0-9]+$ ]]; then
        #    REDIS_SENTINEL_PORT=26379
        #    break
        elif [[ "$REDIS_SENTINEL_PORT" -lt 10001 ]] || [[ "$REDIS_SENTINEL_PORT" -ge 49999 ]]; then
            printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
            printf "\e[00;32m|\e[00m \e[00;31m포트 번호는 숫자로\e[00m \e[00;31m\"10001 ~ 49999\"\e[00m \e[00;32m까지만 입력 가능...\e[00m\n"
            printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
        else
            break
        fi
    done
fi
REDIS_SENTINEL_PORT=`echo ${REDIS_SENTINEL_PORT} | tr -d ' '`


# -------------------------------------------------------------------------------------------------------------------
# Redis Password 설정.
if [[ -z ${REDIS_PASSWORD} ]]; then
    printf "\e[00;32m| Enter the redis password\e[00m"
    read -e -p ' > ' REDIS_PASSWORD
fi


# -------------------------------------------------------------------------------------------------------------------
# 서버 아이피 표시.
if [[ -z ${SERVER_IP} ]]; then
    printf "\e[00;32m|---------------------------------- IP Address -----------------------------------\e[00m\n"
    #if [ "$OS" == "darwin" ]; then # Mac OS
    #    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
    #else
    #    # echo '- ' | ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'
    #    ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'
    #fi
    #ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'
    for ipaddr in `ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'`; do
        printf "\e[00;32m|\e[00m ${ipaddr}\n"
    done
    printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"

    ## 서버 아이피 설정.
    printf "\e[00;32m| Enter the server ip address\e[00m"
    read -e -p " > " SERVER_IP
fi


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| REDIS_SENTINEL_HOME  :\e[00m ${SERVER_HOME}/${REDIS_SENTINEL_HOME}\n"
printf "\e[00;32m| REDIS_SENTINEL_PORT  :\e[00m ${REDIS_SENTINEL_PORT}\n"

# 서버 디렉토리 생성
mkdir -p ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin
mkdir -p ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf
mkdir -p ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/data
mkdir -p ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/logs
mkdir -p ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/work

## 바이너리 복사
cp ${REDIS_SRC_HOME}/src/redis-benchmark  ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/
cp ${REDIS_SRC_HOME}/src/redis-check-aof  ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/
cp ${REDIS_SRC_HOME}/src/redis-check-rdb  ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/
cp ${REDIS_SRC_HOME}/src/redis-cli        ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/
cp ${REDIS_SRC_HOME}/src/redis-sentinel   ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/
cp ${REDIS_SRC_HOME}/src/redis-server     ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/
cp ${REDIS_SRC_HOME}/src/redis-trib.rb    ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/


# ----------------------------------------------------------------------------------------------------------------------
# redis-sentinel.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#      ____           ___         _____            __  _            __
#     / __ \\___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / /
#    / /_/ / _ \\/ __  / / ___/   \\__ \\/ _ \\/ __ \\/ __/ / __ \\/ _ \\/ /
#   / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /
#  /_/ |_|\\___/\\__,_/_/____/   /____/\\___/_/ /_/\\__/_/_/ /_/\\___/_/
#  :: Version ::                                          (v${REDIS_VERSION})
#
# redis - this script starts and stops the redis-sentinel daemon
#
# chkconfig:   - 85 15
# description:  Redis is a persistent key-value database
# processname: redis-sentinel
# config:      ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf
# pidfile:     ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/work/redis-sentinel.pid
#
# Source networking configuration.
[[ -f \"/etc/sysconfig/network\" ]] && . /etc/sysconfig/network

# Check that networking is up.
[ \"\$NETWORKING\" = \"no\" ] && exit 0

# ---------------------------------------------------------------------------------
# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [[ -h \"\$PRG\" ]]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\\\`expr \"\$ls\" : '.*-> \\(.*\\)\$'\\\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\\\`dirname \"\$PRG\"\\\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# ---------------------------------------------------------------------------------
# Redis sentinel user is the default user of redis
export REDIS_SENTINEL_USER='$USERNAME'

# ---------------------------------------------------------------------------------
# Redis sentinel home is the location of the configuration files of this instance of redis
export REDIS_SENTINEL_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

# Redis sentinel server
export REDIS_SENTINEL_SERVER=\"\${REDIS_SENTINEL_HOME}/bin/redis-sentinel\"

# Redis sentinel pid
export REDIS_SENTINEL_PID=\"\${REDIS_SENTINEL_HOME}/work/redis-sentinel.pid\"

# Redis sentinel configuration file
export REDIS_SENTINEL_CONF_FILE=\"\${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf\"

# Redis sentinel log file
export REDIS_SENTINEL_LOG=\"\${REDIS_SENTINEL_HOME}/logs/redis-sentinel.log\"

# 기본 디렉토리가 없는 경우 생성
if [[ ! -d \"\${REDIS_SENTINEL_HOME}/logs\" ]]; then
    mkdir -p \${REDIS_SENTINEL_HOME}/logs
fi
if [[ ! -d \"\${REDIS_SENTINEL_HOME}/work\" ]]; then
    mkdir -p \${REDIS_SENTINEL_HOME}/work
fi

# ---------------------------------------------------------------------------------
# Friendly Logo
logo() {
    printf \"\e[00;32m     ____           ___         _____            __  _            __ \e[00m\\\\n\"
    printf \"\e[00;32m    / __ \\___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / / \e[00m\\\\n\"
    printf \"\e[00;32m   / /_/ / _ \\/ __  / / ___/   \\__ \\/ _ \\/ __ \\/ __/ / __ \\/ _ \\/ /  \e[00m\\\\n\"
    printf \"\e[00;32m  / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /   \e[00m\\\\n\"
    printf \"\e[00;32m /_/ |_|\\___/\\__,_/_/____/   /____/\\___/_/ /_/\\__/_/_/ /_/\\___/_/    \e[00m\\\\n\"
    printf \"\e[00;32m :: Version ::                                          (v${REDIS_VERSION})   \e[00m\\\\n\"
    echo
    printf \"Using REDIS_SENTINEL_HOME: \${REDIS_SENTINEL_HOME}\\\\n\"
    printf \"Using REDIS_SENTINEL_PORT: ${REDIS_SENTINEL_PORT}\\\\n\"
    echo
}

# ---------------------------------------------------------------------------------
# Help
usage() {
    echo \"Script start and stop a Transcoder web instance by invoking the standard \${REDIS_SENTINEL_HOME}/bin/redis-sentinel.sh file.\"
    printf \"Usage: \$0 {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;32mstatus\e[00m|\e[00;31mrestart\e[00m|\e[00;32mlog\e[00m}\"
    echo
    exit 1
}

# ---------------------------------------------------------------------------------
# 파라미터가 없는 경우 종료.
if [[ -z  \"\$1\" ]]; then
    logo
    usage
    exit 1
fi

# ---------------------------------------------------------------------------------
# print friendly logo and information useful for debugging
logo

# ---------------------------------------------------------------------------------
# shutdown wait is wait time in seconds for redis proccess to stop (120 sec)
SHUTDOWN_WAIT=120

# ---------------------------------------------------------------------------------
server_pid() {
    # pgrep -f \"\${REDIS_SENTINEL_SERVER}\"
    echo \`ps aux | grep -v grep | grep \"\${REDIS_SENTINEL_SERVER}\" | grep ${REDIS_SENTINEL_PORT} | awk '{ print \$2 }'\`
}

# ---------------------------------------------------------------------------------
start() {
    pid=\$(server_pid)
    if [[ -n \"\$pid\" ]]; then
        printf \"Redis is already running (PID: \e[00;32m\$pid\e[00m)\\n\"
        return 0
    fi

    # Start daemons.
    # \"daemonize yes\"를 사용하지 않고 데몬을 띄우면, Running in cluster mode 라는 로그를 볼 수 있다.
    if [[ \"\${USER}\" = \"root\" ]]; then
        printf \"Redis 시작 중:\"
        su - \${REDIS_SENTINEL_USER} -c \"\${REDIS_SENTINEL_SERVER} \$REDIS_SENTINEL_CONF_FILE\"
    elif [[ \"\${USER}\" = \"\${REDIS_SENTINEL_USER}\" ]]; then
        printf \"Redis 시작 중:\"
        \${REDIS_SENTINEL_SERVER} \$REDIS_SENTINEL_CONF_FILE
    else
        printf \"You can not start this redis with \e[00;31m\${USER}.\e[00m\\n\"
        printf \"Do start with \e[00;32m\${REDIS_SENTINEL_USER}\e[00m.\\n\"
        return 1
    fi

    sleep 0.5
    retval=\$?
    if [[ \$retval = 0 ]]; then
        printf \"                                          [  \e[00;32mOK\e[00m  ]\\\\n\"
    else
        printf \"                                          [\e[00;32mFAILED\e[00m]\\\\n\"
    fi
    return \$retval
}

# ---------------------------------------------------------------------------------
stop() {
    pid=\$(server_pid)
    if [[ -n \"\$pid\" ]]; then
        # Stop daemons.
        if [ \"\${USER}\" != \"root\" ] && [ \"\${USER}\" != \"\${REDIS_SENTINEL_USER}\" ]; then
            printf \"\e[00;31mYou can not start this redis with \${USER}.\e[00m\\n\"
            printf \"\e[00;31mDo stop with \${REDIS_SENTINEL_USER}.\e[00m\\n\"
            return 1
        fi

        printf \$\" Redis 종료 중:\"

        [ -n \"\$pid\" ] && kill \$pid
        sleep 1

        let kwait=\${SHUTDOWN_WAIT}
        count=0;
        until [[ \`ps -p \$pid | grep -c \$pid\` = '0' ]] || [[ \$count -gt \$kwait ]]
        do
            if [[ \$count -le 0 ]]; then
                echo
            fi
            printf \"\e[00;31mWaiting for processes to exit.\e[00m\\\\n\"
            sleep 1
            let count=\$count+1;
        done

        if [[ \$count -gt \$kwait ]]; then
            printf \"\e[00;31mKilling processes didn't stop after \${SHUTDOWN_WAIT} seconds\e[00m\\\\n\"
            kill -9 \$pid
        fi

        if [[ \$count -gt 0 ]]; then
            printf \"Redis 종료:\"
        fi

        retval=\$?
        if [[ \$retval = 0 ]]; then
            printf \"                                          [  \e[00;32mOK\e[00m  ]\\\\n\"
        else
            printf \"                                          [\e[00;32mFAILED\e[00m]\\\\n\"
        fi
        return \$retval;
    else
        printf \"\e[00;31mRedis is not running\e[00m\\n\"
        return 0
    fi
}

# ---------------------------------------------------------------------------------
status() {
    pid=\$(server_pid)
    if [ -n \"\$pid\" ]; then
        printf \"Redis (PID: \e[00;32m\$pid\e[00m) is running...\\n\"
        return 0
    fi
    if [ -f \"\${REDIS_SENTINEL_PID}\" ]; then
        echo \$\" Redis dead but subsys locked\"
        rm -rf \${REDIS_SENTINEL_PID}
        return 2
    fi
    echo \" Redis is stopped\"
    return 3
}

# ---------------------------------------------------------------------------------
log() {
    tail -f \$REDIS_SENTINEL_LOG
}

case \"\$1\" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    status)
        status
        ;;
    log)
        log
        ;;
    *)
    usage
    exit 1
esac

exit \$retval
" > ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/redis-sentinel.sh

echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#      ____           ___         _____            __  _            __
#     / __ \\___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / /
#    / /_/ / _ \\/ __  / / ___/   \\__ \\/ _ \\/ __ \\/ __/ / __ \\/ _ \\/ /
#   / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /
#  /_/ |_|\\___/\\__,_/_/____/   /____/\\___/_/ /_/\\__/_/_/ /_/\\___/_/
#  :: Version ::                                          (v${REDIS_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [[ -h \"\$PRG\" ]]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\\\`expr \"\$ls\" : '.*-> \\(.*\\)\$'\\\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\\\`dirname \"\$PRG\"\\\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# REDIS_SENTINEL_HOME is the location of the configuration files of this instance of redis
export REDIS_SENTINEL_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

\${REDIS_SENTINEL_HOME}/bin/redis-sentinel.sh start
" > ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/start.sh

echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#      ____           ___         _____            __  _            __
#     / __ \\___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / /
#    / /_/ / _ \\/ __  / / ___/   \\__ \\/ _ \\/ __ \\/ __/ / __ \\/ _ \\/ /
#   / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /
#  /_/ |_|\\___/\\__,_/_/____/   /____/\\___/_/ /_/\\__/_/_/ /_/\\___/_/
#  :: Version ::                                          (v${REDIS_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [[ -h \"\$PRG\" ]]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\\\`expr \"\$ls\" : '.*-> \\(.*\\)\$'\\\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\\\`dirname \"\$PRG\"\\\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# REDIS_SENTINEL_HOME is the location of the configuration files of this instance of redis
export REDIS_SENTINEL_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

\${REDIS_SENTINEL_HOME}/bin/redis-sentinel.sh stop
" > ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/stop.sh

echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#      ____           ___         _____            __  _            __
#     / __ \\___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / /
#    / /_/ / _ \\/ __  / / ___/   \\__ \\/ _ \\/ __ \\/ __/ / __ \\/ _ \\/ /
#   / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /
#  /_/ |_|\\___/\\__,_/_/____/   /____/\\___/_/ /_/\\__/_/_/ /_/\\___/_/
#  :: Version ::                                          (v${REDIS_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [[ -h \"\$PRG\" ]]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\\\`expr \"\$ls\" : '.*-> \\(.*\\)\$'\\\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\\\`dirname \"\$PRG\"\\\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# REDIS_SENTINEL_HOME is the location of the configuration files of this instance of redis
export REDIS_SENTINEL_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

\${REDIS_SENTINEL_HOME}/bin/redis-sentinel.sh restart
" > ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/restart.sh

echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#      ____           ___         _____            __  _            __
#     / __ \\___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / /
#    / /_/ / _ \\/ __  / / ___/   \\__ \\/ _ \\/ __ \\/ __/ / __ \\/ _ \\/ /
#   / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /
#  /_/ |_|\\___/\\__,_/_/____/   /____/\\___/_/ /_/\\__/_/_/ /_/\\___/_/
#  :: Version ::                                          (v${REDIS_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [[ -h \"\$PRG\" ]]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\\\`expr \"\$ls\" : '.*-> \\(.*\\)\$'\\\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\\\`dirname \"\$PRG\"\\\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# REDIS_SENTINEL_HOME is the location of the configuration files of this instance of redis
export REDIS_SENTINEL_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

\${REDIS_SENTINEL_HOME}/bin/redis-sentinel.sh status
" > ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/status.sh

echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#      ____           ___         _____            __  _            __
#     / __ \\___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / /
#    / /_/ / _ \\/ __  / / ___/   \\__ \\/ _ \\/ __ \\/ __/ / __ \\/ _ \\/ /
#   / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /
#  /_/ |_|\\___/\\__,_/_/____/   /____/\\___/_/ /_/\\__/_/_/ /_/\\___/_/
#  :: Version ::                                          (v${REDIS_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [[ -h \"\$PRG\" ]]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\\\`expr \"\$ls\" : '.*-> \\(.*\\)\$'\\\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\\\`dirname \"\$PRG\"\\\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# REDIS_SENTINEL_HOME is the location of the configuration files of this instance of redis
export REDIS_SENTINEL_HOME=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

\${REDIS_SENTINEL_HOME}/bin/redis-sentinel.sh log
" > ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/log.sh

# -------------------------------------------------------------------------------------------------------------------
# redis-sentinel.conf
echo "# Example sentinel.conf

# *** IMPORTANT ***
#
# By default Sentinel will not be reachable from interfaces different than
# localhost, either use the 'bind' directive to bind to a list of network
# interfaces, or disable protected mode with \"protected-mode no\" by
# adding it to this configuration file.
#
# Before doing that MAKE SURE the instance is protected from the outside
# world via firewalling or other means.
#
# For example you may use one of the following:
#" > ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf

if [[ -z ${SERVER_IP} ]]; then
    echo "# bind 127.0.0.1 192.168.1.1
#
# protected-mode no
    " >> ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf
else
    echo "bind ${SERVER_IP}
#
protected-mode yes
    " >> ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf
fi

echo "# port <sentinel-port>
# The port that this sentinel instance will run on
port ${REDIS_SENTINEL_PORT}

# By default Redis Sentinel does not run as a daemon. Use 'yes' if you need it.
# Note that Redis will write a pid file in /var/run/redis-sentinel.pid when
# daemonized.
daemonize yes

# When running daemonized, Redis Sentinel writes a pid file in
# /var/run/redis-sentinel.pid by default. You can specify a custom pid file
# location here.
pidfile ${SERVER_HOME}/${REDIS_HOME}/work/redis-sentinel.pid

# Specify the log file name. Also the empty string can be used to force
# Sentinel to log on the standard output. Note that if you use standard
# output for logging but daemonize, logs will be sent to /dev/null
logfile \"${SERVER_HOME}/${REDIS_SENTINEL_HOME}/logs/redis-sentinel.log\"

# sentinel announce-ip <ip>
# sentinel announce-port <port>
#
# The above two configuration directives are useful in environments where,
# because of NAT, Sentinel is reachable from outside via a non-local address.
#
# When announce-ip is provided, the Sentinel will claim the specified IP address
# in HELLO messages used to gossip its presence, instead of auto-detecting the
# local address as it usually does.
#
# Similarly when announce-port is provided and is valid and non-zero, Sentinel
# will announce the specified TCP port.
#
# The two options don't need to be used together, if only announce-ip is
# provided, the Sentinel will announce the specified IP and the server port
# as specified by the \"port\" option. If only announce-port is provided, the
# Sentinel will announce the auto-detected local IP and the specified port.
#
# Example:
#
# sentinel announce-ip 1.2.3.4

# dir <working-directory>
# Every long running process should have a well-defined working directory.
# For Redis Sentinel to chdir to /tmp at startup is the simplest thing
# for the process to don't interfere with administrative tasks such as
# unmounting filesystems.
dir ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/data/

# sentinel monitor <master-name> <ip> <redis-port> <quorum>
#
# Tells Sentinel to monitor this master, and to consider it in O_DOWN
# (Objectively Down) state only if at least <quorum> sentinels agree.
#
# Note that whatever is the ODOWN quorum, a Sentinel will require to
# be elected by the majority of the known Sentinels in order to
# start a failover, so no failover can be performed in minority.
#
# Replicas are auto-discovered, so you don't need to specify replicas in
# any way. Sentinel itself will rewrite this configuration file adding
# the replicas using additional configuration options.
# Also note that the configuration file is rewritten when a
# replica is promoted to master.
#
# Note: master name should not include special characters or spaces.
# The valid charset is A-z 0-9 and the three characters \".-_\".
sentinel monitor mymaster 127.0.0.1 6379 2

# sentinel auth-pass <master-name> <password>
#
# Set the password to use to authenticate with the master and replicas.
# Useful if there is a password set in the Redis instances to monitor.
#
# Note that the master password is also used for replicas, so it is not
# possible to set a different password in masters and replicas instances
# if you want to be able to monitor these instances with Sentinel.
#
# However you can have Redis instances without the authentication enabled
# mixed with Redis instances requiring the authentication (as long as the
# password set is the same for all the instances requiring the password) as
# the AUTH command will have no effect in Redis instances with authentication
# switched off.
#
# Example:
#" >> ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf

if [[ -z ${REDIS_PASSWORD} ]]; then
    echo "# sentinel auth-pass mymaster MySUPER--secret-0123passw0rd
" >> ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf
else
    echo "sentinel auth-pass mymaster ${REDIS_PASSWORD}
" >> ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf
fi

echo "# sentinel down-after-milliseconds <master-name> <milliseconds>
#
# Number of milliseconds the master (or any attached replica or sentinel) should
# be unreachable (as in, not acceptable reply to PING, continuously, for the
# specified period) in order to consider it in S_DOWN state (Subjectively
# Down).
#
# Default is 30 seconds.
sentinel down-after-milliseconds mymaster 3000

# sentinel parallel-syncs <master-name> <numreplicas>
#
# How many replicas we can reconfigure to point to the new replica simultaneously
# during the failover. Use a low number if you use the replicas to serve query
# to avoid that all the replicas will be unreachable at about the same
# time while performing the synchronization with the master.
sentinel parallel-syncs mymaster 1

# sentinel failover-timeout <master-name> <milliseconds>
#
# Specifies the failover timeout in milliseconds. It is used in many ways:
#
# - The time needed to re-start a failover after a previous failover was
#   already tried against the same master by a given Sentinel, is two
#   times the failover timeout.
#
# - The time needed for a replica replicating to a wrong master according
#   to a Sentinel current configuration, to be forced to replicate
#   with the right master, is exactly the failover timeout (counting since
#   the moment a Sentinel detected the misconfiguration).
#
# - The time needed to cancel a failover that is already in progress but
#   did not produced any configuration change (SLAVEOF NO ONE yet not
#   acknowledged by the promoted replica).
#
# - The maximum time a failover in progress waits for all the replicas to be
#   reconfigured as replicas of the new master. However even after this time
#   the replicas will be reconfigured by the Sentinels anyway, but not with
#   the exact parallel-syncs progression as specified.
#
# Default is 3 minutes.
sentinel failover-timeout mymaster 180000

# SCRIPTS EXECUTION
#
# sentinel notification-script and sentinel reconfig-script are used in order
# to configure scripts that are called to notify the system administrator
# or to reconfigure clients after a failover. The scripts are executed
# with the following rules for error handling:
#
# If script exits with \"1\" the execution is retried later (up to a maximum
# number of times currently set to 10).
#
# If script exits with \"2\" (or an higher value) the script execution is
# not retried.
#
# If script terminates because it receives a signal the behavior is the same
# as exit code 1.
#
# A script has a maximum running time of 60 seconds. After this limit is
# reached the script is terminated with a SIGKILL and the execution retried.

# NOTIFICATION SCRIPT
#
# sentinel notification-script <master-name> <script-path>
#
# Call the specified notification script for any sentinel event that is
# generated in the WARNING level (for instance -sdown, -odown, and so forth).
# This script should notify the system administrator via email, SMS, or any
# other messaging system, that there is something wrong with the monitored
# Redis systems.
#
# The script is called with just two arguments: the first is the event type
# and the second the event description.
#
# The script must exist and be executable in order for sentinel to start if
# this option is provided.
#
# Example:
#
# sentinel notification-script mymaster /var/redis/notify.sh

# CLIENTS RECONFIGURATION SCRIPT
#
# sentinel client-reconfig-script <master-name> <script-path>
#
# When the master changed because of a failover a script can be called in
# order to perform application-specific tasks to notify the clients that the
# configuration has changed and the master is at a different address.
#
# The following arguments are passed to the script:
#
# <master-name> <role> <state> <from-ip> <from-port> <to-ip> <to-port>
#
# <state> is currently always \"failover\"
# <role> is either \"leader\" or \"observer\"
#
# The arguments from-ip, from-port, to-ip, to-port are used to communicate
# the old address of the master and the new address of the elected replica
# (now a master).
#
# This script should be resistant to multiple invocations.
#
# Example:
#
# sentinel client-reconfig-script mymaster /var/redis/reconfig.sh

# SECURITY
#
# By default SENTINEL SET will not be able to change the notification-script
# and client-reconfig-script at runtime. This avoids a trivial security issue
# where clients can set the script to anything and trigger a failover in order
# to get the program executed.

sentinel deny-scripts-reconfig yes

# REDIS COMMANDS RENAMING
#
# Sometimes the Redis server has certain commands, that are needed for Sentinel
# to work correctly, renamed to unguessable strings. This is often the case
# of CONFIG and SLAVEOF in the context of providers that provide Redis as
# a service, and don't want the customers to reconfigure the instances outside
# of the administration console.
#
# In such case it is possible to tell Sentinel to use different command names
# instead of the normal ones. For example if the master \"mymaster\", and the
# associated replicas, have \"CONFIG\" all renamed to \"GUESSME\", I could use:
#
# SENTINEL rename-command mymaster CONFIG GUESSME
#
# After such configuration is set, every time Sentinel would use CONFIG it will
# use GUESSME instead. Note that there is no actual need to respect the command
# case, so writing \"config guessme\" is the same in the example above.
#
# SENTINEL SET can also be used in order to perform this configuration at runtime.
#
# In order to set a command back to its original name (undo the renaming), it
# is possible to just rename a command to itsef:
#
# SENTINEL rename-command mymaster CONFIG CONFIG
" >> ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/conf/redis-sentinel.conf


# -------------------------------------------------------------------------------------------------------------------
# log_rotate.sh
echo "#!/bin/bash
# ---------------------------------------------------------------------------------
#      ____           ___         _____            __  _            __
#     / __ \\___  ____/ (_)____   / ___/___  ____  / /_(_)___  ___  / /
#    / /_/ / _ \\/ __  / / ___/   \\__ \\/ _ \\/ __ \\/ __/ / __ \\/ _ \\/ /
#   / _, _/  __/ /_/ / (__  )   ___/ /  __/ / / / /_/ / / / /  __/ /
#  /_/ |_|\\___/\\__,_/_/____/   /____/\\___/_/ /_/\\__/_/_/ /_/\\___/_/
#  :: Version ::                                          (v${REDIS_VERSION})

#-----------------------------------------------
# 시스템에 맞게 계정과 그룹을 변경한다.
#-----------------------------------------------
USER=${USERNAME}
GROUP=${GROUPNAME}

# crontab 에 등록
# 0 0 * * * ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/log_rotate.sh

# 스크립트에 에러가 있는 경우 즉시 종료.
set -e

# 파일 경로와 파일명 분리.
FILE_PATH='${SERVER_HOME}/${REDIS_SENTINEL_HOME}/logs'
FILE_EXTENSION='.log'

# File Extension
EXTENSION='${EXTENSION}'

# 파일 백업 경로에서 끝에 \"/\"가 있으면 제거.
BACKUP_PATH='${SERVER_HOME}/${REDIS_SENTINEL_HOME}/logs/archive'
BACKUP_LOG_NAME=\"backup-\$(date -d \"1 day ago\" +\"%Y-%m\").log\"

# 예외 디렉토리
EXCEPTION_PATH=\`basename \"\${BACKUP_PATH}\"\`

# 백업 디렉토리 생성 및 사용자, 그룹을 변경.
if [[ ! -d \"\${BACKUP_PATH}\" ]]; then
    mkdir -p \${BACKUP_PATH}
    chown -R \${USER}:\${GROUP} \${BACKUP_PATH}
fi

echo \"-----------------------------------------------------------------------------------------------------------------\" | tee -a \${BACKUP_PATH}/\${BACKUP_LOG_NAME}
echo \"- 파일 백업 : \$(date +\"%Y:%m:%d %H-%M-%S\")\" | tee -a \${BACKUP_PATH}/\${BACKUP_LOG_NAME}

# 파일의 디렉토리로 이동.
pushd \${FILE_PATH} > /dev/null

# 파일을 백업한다.
find . ! \\( -path \"./\${EXCEPTION_PATH}\" -prune \\) -name \"*\${FILE_EXTENSION}*\" -type f | while IFS= read -r FILE; do
    pushd \${FILE_PATH} > /dev/null

    BACKUP_FILE=\`basename \"\${FILE}\"\`
    BACKUP_NAME=\"\${BACKUP_FILE}.\$(date -d \"1 day ago\" +\"%Y-%m-%d\")\"

    COUNT=100001;
    while [[ -f \"\${BACKUP_PATH}/\${BACKUP_NAME}-\${COUNT}.\${EXTENSION}\" ]]; do
        let COUNT=\${COUNT}+1;
    done

    BACKUP_NAME=\"\${BACKUP_NAME}-\${COUNT}\${EXTENSION}\"

    echo \"FILE - \${FILE}\"
    echo \"BACKUP_FILE - \${BACKUP_FILE}\"
    echo \"BACKUP_NAME - \${BACKUP_NAME}\"

    FILE_SIZE=\`stat -c %s \${BACKUP_FILE}\`
    echo \"FILE_SIZE - \${FILE_SIZE}\"

    if [[ \${FILE_SIZE} = 0 ]]; then
        echo \"  . Backup file name : '\${BACKUP_FILE}' is empty.\" | tee -a \${BACKUP_PATH}/\${BACKUP_LOG_NAME}
    else
        # 백업 파일을 백업 디렉토리에 옮긴다.
        cp \${BACKUP_FILE} \${BACKUP_PATH}

        ## OUT 파일을 초기화한다.
        cat /dev/null > \${BACKUP_FILE}

        # 백업 디렉토리로 이동한다.
        pushd \${BACKUP_PATH} > /dev/null

        # 파일을 압축한다.
        tar cvzf \${BACKUP_NAME} \${BACKUP_FILE}

        # 원본파일을 삭제한다.
        rm -rf \${BACKUP_FILE}

        echo \"  . Backup file name : '\${BACKUP_FILE}' is initialization complete...\" | tee -a \${BACKUP_PATH}/\${BACKUP_LOG_NAME}

        chown -R \${USER}:\${GROUP} \${BACKUP_PATH}/\${BACKUP_NAME}
    fi
done
" > ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/log_rotate.sh

# 실행권한 할당.
chmod +x ${SERVER_HOME}/${REDIS_SENTINEL_HOME}/bin/*.sh


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| ${REDIS_SENTINEL_HOME} create success...\e[00m\n"
printf "\e[00;32m|---------------------------------------------------------------------------------\e[00m\n"
