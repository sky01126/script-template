#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/rabbitmq_install.sh)


# ----------------------------------------------------------------------------------------------------------------------
# Exit on error
set -e

# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

## OS를 확인한다.
OS='unknown'
if [[ "$(uname)" == "Darwin" ]]; then
    OS="darwin"
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    OS="linux"
fi

unset TMOUT


# -------------------------------------------------------------------------------------------------------------------
# 현재 사용자의 아이디명과 그룹정보
USERNAME=`id -u -n`
GROUPNAME=`id -g -n`


# ----------------------------------------------------------------------------------------------------------------------
# File Extension
EXTENSION='.tar.gz'


# ----------------------------------------------------------------------------------------------------------------------
# RabbitMQ
RABBITMQ_VERSION="${RABBITMQ_VERSION}"
RABBITMQ_DOWNLOAD_URL='http://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz'

# Erlang
ERLANG_VERSION="19.1"
ERLANG_DOWNLOAD_URL='http://www.erlang.org/download/otp_src_${ERLANG_VERSION}.tar.gz'


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
# Server Home을 입력으로 받는다.
SERVER_HOME=${HOME}/server
if [[ -z "${SERVER_HOME}" ]]; then
    read -e -p 'Enter the server home path> ' ENTER_SERVER_HOME
    while [ -z ${ENTER_SERVER_HOME} ]; do
        read -e -p 'Enter the server home path> ' ENTER_SERVER_HOME
    done
    SERVER_HOME=${ENTER_SERVER_HOME}
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
# opt : 애드온(Add-on) 소프트웨어 패키지 디렉토리
PROGRAME_HOME='opt/local'

# 서버홈은 .bashrc에 설정.
if [ ! -d "${SERVER_HOME}" ]; then
    printf "\e[00;32mCreate server home directory... [${SERVER_HOME}]\e[00m\n"
    mkdir -p ${SERVER_HOME}
fi
if [ ! -d "${SERVER_HOME}/${PROGRAME_HOME}" ]; then
    printf "\e[00;32mCreate library home directory... [${SERVER_HOME}/${PROGRAME_HOME}]\e[00m\n"
    mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}
fi


# ----------------------------------------------------------------------------------------------------------------------
# Erlang 설치 여부 확인 및 설치.
FIND="_src_"
REPLACE="_"
ERLANG_NAME=${ERLANG_DOWNLOAD_URL##+(*/)}
ERLANG_HOME=${ERLANG_NAME%$EXTENSION}
ERLANG_ALIAS='otp'
ERLANG_INSTALL_HOME=${ERLANG_HOME//$FIND/$REPLACE}


# ----------------------------------------------------------------------------------------------------------------------
# Erlang 설치 여부 확인 및 설치.
FIND="_src_"
REPLACE="_"
ERLANG_NAME=${ERLANG_DOWNLOAD_URL##+(*/)}
ERLANG_HOME=${ERLANG_NAME%$EXTENSION}
ERLANG_ALIAS='otp'
ERLANG_INSTALL_HOME=${ERLANG_HOME//$FIND/$REPLACE}

# 기존에 설치되어있는지 확인한다.
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${ERLANG_INSTALL_HOME}" ]]; then
    # delete the erlang alias home
    if [[ -d "${SERVER_HOME}/${ERLANG_ALIAS}" ]]; then
        printf "\n \e[00;32m ${ERLANG_ALIAS} alias delete...\e[00m\n"
        rm -rf ${SERVER_HOME}/${ERLANG_ALIAS}
    fi

    cd ${SRC_HOME}

    # verify that the source exists download
    if [ ! -f "${SRC_HOME}/${ERLANG_NAME}" ]; then
        printf "\n \e[00;32m ${ERLANG_NAME} download...\e[00m\n"
        curl -L -O ${ERLANG_DOWNLOAD_URL}
    elif [[ -d "${SRC_HOME}/${ERLANG_HOME}" ]]; then
        printf "\n \e[00;32m ${ERLANG_HOME} source delete...\e[00m\n"
        rm -rf ${SRC_HOME}/${ERLANG_HOME}
    fi

    tar xvzf ${ERLANG_NAME}
    cd ${SRC_HOME}/${ERLANG_HOME}

    ./configure --prefix=${SERVER_HOME}/${PROGRAME_HOME}/${ERLANG_INSTALL_HOME}
    make
    make install

    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${ERLANG_INSTALL_HOME} ${ERLANG_ALIAS}

    if [[ -d "${SRC_HOME}/${ERLANG_HOME}" ]]; then
        printf "\n \e[00;32m ${ERLANG_HOME} source delete...\e[00m\n"
        rm -rf ${SRC_HOME}/${ERLANG_HOME}
    fi
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\e[00;32m ${ERLANG_INSTALL_HOME} install success...\e[00m\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
else
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\e[00;32m ${ERLANG_INSTALL_HOME} installd...\e[00m\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
fi


# ----------------------------------------------------------------------------------------------------------------------
# RabbitMQ 설치 여부 확인
FIND="-server-generic-unix-"
REPLACE="_server-"
EXTENSION='.tar.xz'
RABBITMQ_NAME=${RABBITMQ_DOWNLOAD_URL##+(*/)}
RABBITMQ_HOME=${RABBITMQ_NAME%$EXTENSION}
RABBITMQ_ALIAS='rabbitmq'
RABBITMQ_INSTALL_HOME=${RABBITMQ_HOME//$FIND/$REPLACE}

# 기존에 설치되어있는지 확인한다.
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}" ]]; then
    # HOSTNAME / NODENAME 추가.
    read -p "Enter the hostname (ex. ${HOSTNAME}) > " RABBITMQ_HOSTNAME
    while [[ -z ${RABBITMQ_HOSTNAME} ]]; do
        read -p "Enter the hostname (ex. ${HOSTNAME}) > " RABBITMQ_HOSTNAME
    done
    RABBITMQ_NODENAME="${USERNAME}@${RABBITMQ_HOSTNAME}"

    # delete the erlang alias home
    if [[ -d "${SERVER_HOME}/${RABBITMQ_ALIAS}" ]]; then
        printf "\n \e[00;32m ${RABBITMQ_ALIAS} alias delete...\e[00m\n"
        rm -rf ${SERVER_HOME}/${RABBITMQ_ALIAS}
    fi

    cd ${SRC_HOME}

    # verify that the source exists download
    if [ ! -f "${SRC_HOME}/${RABBITMQ_NAME}" ]; then
        printf "\n \e[00;32m ${RABBITMQ_NAME} download...\e[00m\n"
        curl -L -O ${RABBITMQ_DOWNLOAD_URL}
    fi

    tar xvfJ ${RABBITMQ_NAME} -C ${SERVER_HOME}/${PROGRAME_HOME}/

    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME} ${RABBITMQ_ALIAS}

    # 신규 디렉토리 생성
    mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/bin
    mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/conf
    mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/mnesia

    # directory / file delete
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/etc
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/var
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/INSTALL
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/LICENSE*

    # RabbitMQ start / stop script 추가.
    echo "#!/bin/sh
# ==================================================================
#     ____        __    __    _ __  __  _______
#    / __ \____ _/ /_  / /_  (_) /_/  |/  / __ \
#   / /_/ / __ \`/ __ \/ __ \/ / __/ /|_/ / / / /
#  / _, _/ /_/ / /_/ / /_/ / / /_/ /  / / /_/ /
# /_/ |_|\__,_/_.___/_.___/_/\__/_/  /_/\___\_\
#  :: RabbitMQ Server ::               (v1.0.0)
#
# rabbitmq-server RabbitMQ broker
#
# chkconfig: - 80 05
# description: Enable AMQP service provided by RabbitMQ
#

### BEGIN INIT INFO
# Provides:          rabbitmq-server
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs \$network
# Description:       RabbitMQ broker
# Short-Description: Enable AMQP service provided by RabbitMQ broker
### END INIT INFO

# ==================================================================
# Source function library.
# RedHat / CentOS
[[ -f \"/etc/rc.d/init.d/functions\" ]] && . /etc/rc.d/init.d/functions

# Mac OS/X
[[ -f \"/etc/rc.common\" ]] && source /etc/rc.common

# ==================================================================
# Friendly Logo
logo() {
    echo
    printf \"     ____        __    __    _ __  __  _______  \n\"
    printf \"    / __ \____ _/ /_  / /_  (_) /_/  |/  / __ \ \n\"
    printf \"   / /_/ / __ \\\`/ __ \/ __ \/ / __/ /|_/ / / / / \n\"
    printf \"  / _, _/ /_/ / /_/ / /_/ / / /_/ /  / / /_/ /  \n\"
    printf \" /_/ |_|\__,_/_.___/_.___/_/\__/_/  /_/\___\_\  \n\"
    printf \"  :: RabbitMQ Server ::               (v1.0.0)  \n\"
    echo
}

# ==================================================================
# Help
usage() {
    printf \"Usage: \$0 {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;32mstatus\e[00m|\e[00;31mrotate-logs\e[00m|\e[00;32mrestart\e[00m|\e[00;31mcondrestart\e[00m|\e[00;31mtry-restart\e[00m|\e[00;32mreload\e[00m|\e[00;31mforce-reload\e[00m}\"
    echo
    echo
    exit 1
}

# ==================================================================
# 파라미터가 없는 경우 종료.
if [[ -z  \"\$1\" ]]; then
    logo
    usage
    exit 0
fi
PARAM1=\$1

# ==================================================================
RABBITMQ_HOME=${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}
RABBITMQ_BASE=${SERVER_HOME}/${RABBITMQ_ALIAS}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:${SERVER_HOME}/${ERLANG_ALIAS}/bin
NAME=rabbitmq-server
DAEMON=\${RABBITMQ_BASE}/sbin/\${NAME}
CONTROL=\${RABBITMQ_BASE}/sbin/rabbitmqctl
DESC=rabbitmq-server
#USER=${USER}
ROTATE_SUFFIX=
PID_FILE=\${RABBITMQ_BASE}/work/\${NAME}.pid
LOG_BASE=\${RABBITMQ_BASE}/logs

START_PROG=\"daemon\"
LOCK_FILE=\${RABBITMQ_BASE}/work/\${NAME}.lock

test -x \${DAEMON}  || exit 0
test -x \${CONTROL} || exit 0

RETVAL=0
set -e

[[ -f /etc/default/\${NAME} ]] && . /etc/default/\${NAME}

RABBITMQ_ENV=\${RABBITMQ_BASE}/sbin/rabbitmq-env
RABBITMQ_SCRIPTS_DIR=\$(dirname \"\${RABBITMQ_ENV}\")
. \"\${RABBITMQ_ENV}\"

# ==================================================================
# 기본 디렉토리가 없는 경우 생성
if [[ ! -d \"\${LOG_BASE}\" ]]; then
    mkdir -p \${LOG_BASE}
fi

# ==================================================================
# print friendly logo and information useful for debugging
logo

# ==================================================================
printf \" \e[00;32m-------------------------------------------------\e[00m\n\"
printf \" \e[00;32m| NAME       : \${NAME}\e[00m\n\"
printf \" \e[00;32m| DESC       : \${DESC}\e[00m\n\"
printf \" \e[00;32m-------------------------------------------------\e[00m\n\"
printf \" \e[00;32m| PID_FILE   : \${PID_FILE}\e[00m\n\"
printf \" \e[00;32m| LOCK_FILE  : \${LOCK_FILE}\e[00m\n\"
printf \" \e[00;32m-------------------------------------------------\e[00m\n\"
printf \" \e[00;32m| LOG_BASE   : \${LOG_BASE}\e[00m\n\"
printf \" \e[00;32m-------------------------------------------------\e[00m\n\"
printf \" \e[00;32m| HOSTNAME   : ${RABBITMQ_HOSTNAME}\e[00m\n\"
printf \" \e[00;32m| NODENAME   : ${RABBITMQ_NODENAME}\e[00m\n\"
printf \" \e[00;32m-------------------------------------------------\e[00m\n\"
echo

# ==================================================================
# Nginx run 사용자 확인.
check_user() {
    if [ \"\${USER}\" != \"${USERNAME}\" ]; then
        printf \"\e[00;31m Please RabbitMQ \\\"\${PARAM1}\\\" with the \\\"${USERNAME}\\\" account.\e[00m\"
    #if [ \"\${USER}\" != \"root\" ]; then
    #    printf \"\e[00;31m Please RabbitMQ \\\"\${PARAM1}\\\" with the \\\"root\\\" account.\e[00m\"
        echo
        echo
        exit 1
    fi
}

# ==================================================================
ensure_pid_dir() {
    PID_DIR=\`dirname \${PID_FILE}\`
    if [ ! -d \${PID_DIR} ] ; then
        mkdir -p    \${PID_DIR}
        chown -R    ${USERNAME}:${GROUPNAME} \${PID_DIR}
        chmod 755   \${PID_DIR}
    fi
    LOG_DIR=\`dirname \"\${LOG_BASE}\"\`
    if [[ ! -d \"\${LOG_DIR}\" ]]; then
        mkdir -p    \${LOG_DIR}
        chown -R    ${USERNAME}:${GROUPNAME} \${LOG_DIR}
        chmod 755   \${LOG_DIR}
    fi
}

# ==================================================================
remove_pid() {
    rm -f \${PID_FILE}
    #rmdir \`dirname \${PID_FILE}\` || :
}

# ==================================================================
start() {
    check_user
    status quiet
    if [[ \$RETVAL = 0 ]]; then
        echo RabbitMQ is currently running
    else
        RETVAL=0
        ensure_pid_dir
        set +e
        RABBITMQ_PID_FILE=\${PID_FILE} \${START_PROG} \${DAEMON} \\
            > \"\${LOG_BASE}/startup_log\" \\
            2> \"\${LOG_BASE}/startup_err\" \\
            0<&- &
        \${CONTROL} wait \${PID_FILE} >/dev/null 2>&1
        RETVAL=\$?
        set -e
        case \"\${RETVAL}\" in
            0)
                echo SUCCESS
                if [[ -n \"\${LOCK_FILE}\" ]]; then
                    touch \${LOCK_FILE}
                fi
                ;;
            *)
                remove_pid
                echo FAILED - check \${LOG_BASE}/startup_\{log, _err\}
                cat \${LOG_BASE}/startup_err
                echo
                RETVAL=1
                ;;
        esac
    fi
}

# ==================================================================
stop() {
    check_user
    status quiet
    if [[ \${RETVAL} = 0 ]]; then
        set +e
        \${CONTROL} stop \${PID_FILE} \\
            > \${LOG_BASE}/shutdown_log \\
            2> \${LOG_BASE}/shutdown_err
        RETVAL=\$?
        set -e
        if [ \${RETVAL} = 0 ] ; then
            remove_pid
            if [[ -n \"\${LOCK_FILE}\" ]]; then
                rm -f \${LOCK_FILE}
            fi
        else
            echo FAILED - check \${LOG_BASE}/shutdown_log, _err
            cat \${LOG_BASE}/shutdown_err
            echo
        fi
    else
        echo RabbitMQ is not running
        RETVAL=0
    fi
}

# ==================================================================
status() {
    set +e
    if [[ \"\$1\" != \"quiet\" ]]; then
        \${CONTROL} status 2>&1
    else
        \${CONTROL} status > /dev/null 2>&1
    fi
    if [[ \$? != 0 ]]; then
        RETVAL=3
    fi
    set -e
}

# ==================================================================
rotate_logs() {
    set +e
    \${CONTROL} rotate_logs \${ROTATE_SUFFIX}
    if [[ \$? != 0 ]]; then
        RETVAL=1
    fi
    set -e
}

# ==================================================================
restart_running() {
    check_user
    status quiet
    if [[ \${RETVAL} = 0 ]]; then
        restart
    else
        echo RabbitMQ is not runnning
        RETVAL=0
    fi
}

# ==================================================================
restart() {
    check_user
    stop
    start
}

# ==================================================================
case \"\$1\" in
    start)
        echo -n \"Starting \${DESC}: \"
        start
        echo \"\${NAME}.\"
        ;;
    stop)
        echo -n \"Stopping \${DESC}: \"
        stop
        echo \"\${NAME}.\"
        ;;
    status)
        status
        ;;
    rotate-logs)
        echo -n \"Rotating log files for \${DESC}: \"
        rotate_logs
        ;;
    force-reload|reload|restart)
        echo -n \"Restarting \${DESC}: \"
        restart
        echo \"\${NAME}.\"
        ;;
    try-restart)
        echo -n \"Restarting \${DESC}: \"
        restart_running
        echo \"\${NAME}.\"
        ;;
    *)
        usage
        ;;
esac

exit \${RETVAL}
" > ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/bin/rabbitmq-server


    # RabbitMQ start script 수정.
    echo "#!/bin/sh
# ==================================================================
#     ____        __    __    _ __  __  _______
#    / __ \____ _/ /_  / /_  (_) /_/  |/  / __ \
#   / /_/ / __ \`/ __ \/ __ \/ / __/ /|_/ / / / /
#  / _, _/ /_/ / /_/ / /_/ / / /_/ /  / / /_/ /
# /_/ |_|\__,_/_.___/_.___/_/\__/_/  /_/\___\_\
#  :: RabbitMQ Server ::               (v1.0.0)
#
# rabbitmq-server RabbitMQ broker
#
RABBITMQ_HOME=${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}
RABBITMQ_BASE=${SERVER_HOME}/${RABBITMQ_ALIAS}

\$RABBITMQ_BASE/bin/rabbitmq-server start
" > ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/bin/start.sh


    # RabbitMQ stop script 수정.
    echo "#!/bin/sh
# ==================================================================
#     ____        __    __    _ __  __  _______
#    / __ \____ _/ /_  / /_  (_) /_/  |/  / __ \
#   / /_/ / __ \`/ __ \/ __ \/ / __/ /|_/ / / / /
#  / _, _/ /_/ / /_/ / /_/ / / /_/ /  / / /_/ /
# /_/ |_|\__,_/_.___/_.___/_/\__/_/  /_/\___\_\
#  :: RabbitMQ Server ::               (v1.0.0)
#
# rabbitmq-server RabbitMQ broker
#
RABBITMQ_HOME=${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}
RABBITMQ_BASE=${SERVER_HOME}/${RABBITMQ_ALIAS}

\$RABBITMQ_BASE/bin/rabbitmq-server stop
" > ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/bin/stop.sh


    # RabbitMQ restart script 수정.
    echo "#!/bin/sh
# ==================================================================
#     ____        __    __    _ __  __  _______
#    / __ \____ _/ /_  / /_  (_) /_/  |/  / __ \
#   / /_/ / __ \`/ __ \/ __ \/ / __/ /|_/ / / / /
#  / _, _/ /_/ / /_/ / /_/ / / /_/ /  / / /_/ /
# /_/ |_|\__,_/_.___/_.___/_/\__/_/  /_/\___\_\
#  :: RabbitMQ Server ::               (v1.0.0)
#
# rabbitmq-server RabbitMQ broker
#
RABBITMQ_HOME=${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}
RABBITMQ_BASE=${SERVER_HOME}/${RABBITMQ_ALIAS}

\$RABBITMQ_BASE/bin/rabbitmq-server restart
" > ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/bin/restart.sh


    # RabbitMQ status script 수정.
    echo "#!/bin/sh
# ==================================================================
#     ____        __    __    _ __  __  _______
#    / __ \____ _/ /_  / /_  (_) /_/  |/  / __ \
#   / /_/ / __ \`/ __ \/ __ \/ / __/ /|_/ / / / /
#  / _, _/ /_/ / /_/ / /_/ / / /_/ /  / / /_/ /
# /_/ |_|\__,_/_.___/_.___/_/\__/_/  /_/\___\_\
#  :: RabbitMQ Server ::               (v1.0.0)
#
# rabbitmq-server RabbitMQ broker
#
RABBITMQ_HOME=${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}
RABBITMQ_BASE=${SERVER_HOME}/${RABBITMQ_ALIAS}

\$RABBITMQ_BASE/bin/rabbitmq-server status
" > ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/bin/status.sh

    chmod +x ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/bin/*


    # RabbitMQ defaults script 수정.
    echo "#!/bin/sh -e
##  The contents of this file are subject to the Mozilla Public License
##  Version 1.1 (the \"License\"); you may not use this file except in
##  compliance with the License. You may obtain a copy of the License
##  at http://www.mozilla.org/MPL/
##
##  Software distributed under the License is distributed on an \"AS IS\"
##  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
##  the License for the specific language governing rights and
##  limitations under the License.
##
##  The Original Code is RabbitMQ.
##
##  The Initial Developer of the Original Code is GoPivotal, Inc.
##  Copyright (c) 2012-2015 Pivotal Software, Inc.  All rights reserved.
##

### next line potentially updated in package install steps
SYS_PREFIX=\"${SERVER_HOME}/${RABBITMQ_ALIAS}\"

### next line will be updated when generating a standalone release
ERL_DIR=\"${SERVER_HOME}/${ERLANG_ALIAS}/bin/\"

CLEAN_BOOT_FILE=start_clean
SASL_BOOT_FILE=start_sasl

if [ -f \"\${RABBITMQ_HOME}/erlang.mk\" ]; then
    # RabbitMQ is executed from its source directory. The plugins
    # directory and ERL_LIBS are tuned based on this.
    RABBITMQ_DEV_ENV=1
fi

## Set default values

BOOT_MODULE=\"rabbit\"

# Config  File
CONFIG_FILE=\"\${SYS_PREFIX}/conf/rabbitmq\"
LOG_BASE=\"\${SYS_PREFIX}/logs\"
MNESIA_BASE=\"\${SYS_PREFIX}/mnesia\"
ENABLED_PLUGINS_FILE=\"\${SYS_PREFIX}/conf/enabled_plugins\"

PLUGINS_DIR=\"\${SYS_PREFIX}/plugins\"
IO_THREAD_POOL_SIZE=64

CONF_ENV_FILE=\"\${SYS_PREFIX}/conf/rabbitmq-env.conf\"
" > ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/sbin/rabbitmq-defaults


    # RabbitMQ defaults script 수정.
    echo "HOSTNAME=${RABBITMQ_HOSTNAME}
NODENAME=${RABBITMQ_NODENAME}
" > ${SERVER_HOME}/${PROGRAME_HOME}/${RABBITMQ_INSTALL_HOME}/conf/rabbitmq-env.conf


    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\e[00;32m ${RABBITMQ_INSTALL_HOME} install success...\e[00m\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"


    # printf "\e[00;32m--------------------------------------------------------------------------------------------\e[00m\n"
    # printf "\e[00;32m| RabbitMQ Server Port        :\e[00m 5672\n"
    # printf "\e[00;32m| RabbitMQ Management UI Port :\e[00m 15672\n"
    # printf "\e[00;32m--------------------------------------------------------------------------------------------\e[00m\n"
    # printf "\e[00;32m| RabbitMQ Start\e[00m\n"
    # printf "\e[00;32m|   shell>\e[00m ${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}/bin/start.sh\n"
    # printf "\e[00;32m--------------------------------------------------------------------------------------------\e[00m\n"
    # printf "\e[00;32m| RabbitMQ Management Plugin Activation\e[00m\n"
    # printf "\e[00;32m|   shell>\e[00m ${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}/sbin/rabbitmq-plugins enable rabbitmq_management\n"
    # printf "\e[00;32m--------------------------------------------------------------------------------------------\e[00m\n"
    # printf "\e[00;32m| RabbitMQ Create Account\e[00m\n"
    # printf "\e[00;32m|   shell>\e[00m ${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}/sbin/rabbitmqctl add_user ${USER} ${USER}\n"
    # printf "\e[00;32m|   shell>\e[00m ${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}/sbin/rabbitmqctl set_user_tags ${USER} administrator\n"
    # printf "\e[00;32m--------------------------------------------------------------------------------------------\e[00m\n"
    # printf "\e[00;32m| RabbitMQ Set Permission\e[00m\n"
    # printf "\e[00;32m|   shell>\e[00m ${SERVER_HOME}/${RABBITMQ_INSTALL_HOME}/sbin/rabbitmqctl set_permissions -p / ${USER} \".*\" \".*\" \".*\"\n"
    # printf "\e[00;32m--------------------------------------------------------------------------------------------\e[00m\n"
    # printf "\n"
else
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\e[00;32m ${RABBITMQ_INSTALL_HOME} installd...\e[00m\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
fi
