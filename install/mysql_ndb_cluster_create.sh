#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/mysql_ndb_cluster_create.sh)


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
MYSQL_DOWNLOAD_URL='https://빌드파일_도메인/Downloads/MySQL-5.7/mysql-cluster-gpl-7.5.5.tar.gz'


#-----------------------------------------------------------------------------------------------------------------------
MYSQL_NAME=${MYSQL_DOWNLOAD_URL##+(*/)}
MYSQL_HOME=${MYSQL_NAME%$EXTENSION}
MYSQL_ALIAS='mysql'


#-----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}" ]]; then
    printf "\e[00;32m기존에 설치된 ${MYSQL_HOME}가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    echo

    while [[ true ]]; do
        read -e -p "Enter whether to install \"${MYSQL_HOME}\" service? [Y / n] > " INSTALL_CHECK
        if [[ "$(uppercase ${INSTALL_CHECK})" = "Y" || "$(uppercase ${INSTALL_CHECK})" = "N" ]]; then
            break;
        fi
    done

    if [[ "$(uppercase ${INSTALL_CHECK})" != "Y" ]]; then
        printf "\n\e[00;31m \"${MYSQL_HOME}\" 서비스 생성 취소...\e[00m\n\n"
        exit 1
    fi
fi


#-----------------------------------------------------------------------------------------------------------------------
MYSQL_GROUP='dba'
MYSQL_USER='mysql'

## Group이 있는지 확인한다.
export GET_GROUP_INFO=`grep ${MYSQL_GROUP} /etc/group`
if [[ -z "${GET_GROUP_INFO}" ]]; then
    sudo groupadd -g 300 ${MYSQL_GROUP}
fi

export GET_USER_INFO=`grep ${MYSQL_USER} /etc/passwd`
if [[ -z "${GET_USER_INFO}" ]]; then
    sudo useradd -M -d /nonexistent  -u 300 -g ${MYSQL_GROUP} -G ${MYSQL_GROUP},wheel -s /bin/false $MYSQL_USER
fi

sudo yum install -y zlib
echo


#-----------------------------------------------------------------------------------------------------------------------
# MySQL Data Home을 입력으로 받는다.
read -e -p 'Enter the mysql data home path> ' ENTER_DATA_HOME
while [[ -z ${ENTER_DATA_HOME} ]]; do
    read -e -p 'Enter the mysql data home path> ' ENTER_DATA_HOME
done
export DATA_HOME=${ENTER_DATA_HOME%/}


#-----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME         :\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME      :\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| MYSQL_HOME       :\e[00m ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}\n"
printf "\e[00;32m| MYSQL_DATA_HOME  :\e[00m ${DATA_HOME}\n"
printf "\e[00;32m--------------------------------------------------------------------------\e[00m\n"
echo


# ----------------------------------------------------------------------------------------------------------------------
# Java Home Setting
JAVA_HOME=${SERVER_HOME}/${JAVA_ALIAS}
PATH=${JAVA_HOME}/bin:${PATH}


#-----------------------------------------------------------------------------------------------------------------------
# MySQL 설치.
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}
sudo rm -rf ${SERVER_HOME}/${MYSQL_ALIAS}*
sudo rm -rf ${DATA_HOME}/*

MYSQL_DATADIR=${DATA_HOME}/data
sudo mkdir -p ${MYSQL_DATADIR}

MYSQL_TMPDIR=${DATA_HOME}/tmp
sudo mkdir -p ${MYSQL_TMPDIR}

MYSQL_LOG_BIN=${DATA_HOME}/binlog/mysql-bin
sudo mkdir -p ${MYSQL_LOG_BIN}

MYSQL_RELAY_LOG=${DATA_HOME}/binlog/mysql-relay
sudo mkdir -p ${MYSQL_RELAY_LOG}

MYSQL_INNODB_DATA_HOME_DIR=${DATA_HOME}/data
sudo mkdir -p ${MYSQL_INNODB_DATA_HOME_DIR}

MYSQL_INNODB_LOG_GROUP_HOME_DIR=${DATA_HOME}/iblog
sudo mkdir -p ${MYSQL_INNODB_LOG_GROUP_HOME_DIR}

MYSQL_LOGS_DIR=${DATA_HOME}/logs
sudo mkdir -p ${MYSQL_LOGS_DIR}

MYSQL_WORD_DIR=${DATA_HOME}/work
sudo mkdir -p ${MYSQL_WORD_DIR}

cd ${SRC_HOME}

sudo tar xvzf ${MYSQL_NAME} -C ${SERVER_HOME}/..

sudo chown root:${MYSQL_GROUP}            -R ${SERVER_HOME}/${MYSQL_ALIAS}*
sudo chown root:${MYSQL_GROUP}            -R ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}*
sudo chown ${MYSQL_USER}.${MYSQL_GROUP} -R ${DATA_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${MYSQL_NAME}" ]; then
    printf "\n \e[00;32m ${MYSQL_NAME} download...\e[00m\n"
    curl -O ${MYSQL_DOWNLOAD_URL}
fi


#-----------------------------------------------------------------------------------------------------------------------
# MySQL Cluster Master Server IP
read -e -p 'Enter the mysql cluster master server ip> ' ENTER_NDB_MGMD_IP
while [[ -z ${ENTER_NDB_MGMD_IP} ]]; do
    read -e -p 'Enter the mysql cluster master server ip> ' ENTER_NDB_MGMD_IP
done


#-----------------------------------------------------------------------------------------------------------------------
echo "[client]
port                                = 3306
socket                              = ${MYSQL_WORD_DIR}/${MYSQL_ALIAS}.sock

[mysqld]
port                                = 3306
pid_file                            = ${MYSQL_WORD_DIR}/${MYSQL_ALIAS}.pid
socket                              = ${MYSQL_WORD_DIR}/${MYSQL_ALIAS}.sock
skip-external-locking
key_buffer_size                     = 16K
max_allowed_packet                  = 1M
table_open_cache                    = 4
sort_buffer_size                    = 64K
read_buffer_size                    = 256K
read_rnd_buffer_size                = 256K
net_buffer_length                   = 2K
thread_stack                        = 128K

server-id                           = 1

## config server and data path
basedir                             = ${SERVER_HOME}/${MYSQL_ALIAS}
datadir                             = ${MYSQL_DATADIR}
tmpdir                              = ${MYSQL_TMPDIR}
log_bin                             = ${MYSQL_LOG_BIN}
relay_log                           = ${MYSQL_RELAY_LOG}
innodb_data_home_dir                = ${MYSQL_INNODB_DATA_HOME_DIR}
innodb_log_group_home_dir           = ${MYSQL_INNODB_LOG_GROUP_HOME_DIR}

## log
log_error                           = ${MYSQL_LOGS_DIR}/${MYSQL_ALIAS}.log
slow_query_log_file                 = ${MYSQL_LOGS_DIR}/${MYSQL_ALIAS}_slow_query.log

## config character set (utf8 / euckr)
character_set_client_handshake      = FALSE
character_set_server                = utf8
collation_server                    = utf8_general_ci
init_connect                        = \"SET collation_connection = utf8_general_ci\"
init_connect                        = \"SET NAMES utf8\"

[mysqldump]
quick
max_allowed_packet                  = 16M

[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates

[myisamchk]
key_buffer_size                     = 8M
sort_buffer_size                    = 8M

[mysqlhotcopy]
interactive-timeout

# enable ndbcluster storage engine, and provide connection string for management
# server host to the default port 1186
[mysqld]
# Options for mysqld process: run NDB storage engine
ndbcluster

# cluster-specific settings
[mysql_cluster]
# Options for NDB Cluster  processes: location of management server
ndb-connectstring=${ENTER_NDB_MGMD_IP}" | sudo tee ${SERVER_HOME}/${MYSQL_ALIAS}/my.cnf

sudo rm -rf /etc/my.cnf
sudo cp -r ${SERVER_HOME}/${MYSQL_ALIAS}/my.cnf /etc/my.cnf

printf " | \e[00;32mCopy${SERVER_HOME}/${MYSQL_ALIAS}/support-files/mysql.server to /etc/init.d/mysqld\e[00m\n"
sudo rm -rf /etc/init.d/mysqld
sudo cp ${SERVER_HOME}/${MYSQL_ALIAS}/support-files/mysql.server /etc/init.d/mysqld

echo
printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
printf " \e[00;32m ${MYSQL_HOME} install success...\e[00m\n"
printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"

#### 아래부터는
#printf " | \e[00;32mRun ./mysql_install_db --user=${MYSQL_USER} --basedir=${SERVER_HOME}/${MYSQL_ALIAS} --datadir=${MYSQL_DATADIR}\e[00m\n"
#cd ${SERVER_HOME}/${MYSQL_ALIAS}/bin
#sudo ./mysql_install_db --user=${MYSQL_USER} --basedir=${SERVER_HOME}/${MYSQL_ALIAS} --datadir=${MYSQL_DATADIR}
#
#printf " | \e[00;32mCopy${SERVER_HOME}/${MYSQL_ALIAS}/support-files/mysql.server to /etc/init.d/mysqld\e[00m\n"
#sudo rm -rf /etc/init.d/mysqld
#sudo cp ${SERVER_HOME}/${MYSQL_ALIAS}/support-files/mysql.server /etc/init.d/mysqld
#sleep 0.5
#
#echo
#printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
#printf " \e[00;32m ${MYSQL_HOME} install success...\e[00m\n"
#printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
#printf " \e[00;32m - 설치 후 초기 비밀번호 변경.\e[00m\n"
#printf " \e[00;32m   shell>\e[00m sudo cat /root/.mysql_secret\n"
#printf " \e[00;32m   shell>\e[00m sudo /etc/init.d/mysqld start\n"
#printf " \e[00;32m   shell>\e[00m ${SERVER_HOME}/${MYSQL_ALIAS}/bin/mysql -u root -p\n"
#printf " \e[00;32m   mysql>\e[00m SET PASSWORD = PASSWORD('비밀번호');\n"
#printf " \e[00;32m   mysql>\e[00m FLUSH PRIVILEGES;\n"
#printf "\n"
#printf " \e[00;32m - 보안을 위한 설정체크를 위한 스크립트 수행.\e[00m\n"
#printf " \e[00;32m   shell>\e[00m sudo rm -rf /root/.mysql_secret\n"
#printf " \e[00;32m   shell>\e[00m sudo ${SERVER_HOME}/${MYSQL_ALIAS}/bin/mysql_secure_installation\n"
#printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
#printf "\n"


#echo
#printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
#printf " \e[00;32m ${MYSQL_HOME} install success...\e[00m\n"
#printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
#printf " \e[00;32m - 설치 후 초기 실행.\e[00m\n"
#printf " \e[00;32m   shell>\e[00m sudo /etc/init.d/mysqld start --skip-grant-tables\n"
#printf " \e[00;32m   shell>\e[00m ${SERVER_HOME}/${MYSQL_ALIAS}/bin/mysql -u root mysql\n"
#printf "\n"
#printf " \e[00;32m - 임시 비밀번호 변경.\e[00m\n"
#printf " \e[00;32m   mysql>\e[00m UPDATE user SET authentication_string=PASSWORD('비밀번호') WHERE user='root';\n"
#printf " \e[00;32m   mysql>\e[00m FLUSH PRIVILEGES;\n"
#printf "\n"
#printf " \e[00;32m - MySQL 재시작.\e[00m\n"
#printf " \e[00;32m   shell>\e[00m sudo /etc/init.d/mysqld restart\n"
#printf "\n"
#printf " \e[00;32m - 비밀번호 변경.\e[00m\n"
#printf " \e[00;32m   shell>\e[00m ${SERVER_HOME}/${MYSQL_ALIAS}/bin/mysql -u root -p\n"
#printf " \e[00;32m   mysql>\e[00m SET PASSWORD = PASSWORD('비밀번호');\n"
#printf "\n"
#printf " \e[00;32m - 보안을 위한 설정체크를 위한 스크립트 수행.\e[00m\n"
#printf " \e[00;32m   shell>\e[00m ${SERVER_HOME}/${MYSQL_ALIAS}/bin/mysql_secure_installation\n"
#printf " \e[00;32m-----------------------------------------------------------------------------------------------------\e[00m\n"
#printf "\n"
