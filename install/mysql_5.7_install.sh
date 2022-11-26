#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/mysql_5.7_install.sh)

# yum install -y zlib


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
PRG="$0"
while [[ -h "$PRG" ]]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`/"$link"
    fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`


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


#-----------------------------------------------------------------------------------------------------------------------
BOOST_VERSION="1.59.0"
BOOST_DOWNLOAD_URL="https://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz"


#-----------------------------------------------------------------------------------------------------------------------
MYSQL_VERSION="5.7.22"
MYSQL_DOWNLOAD_URL="https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-boost-${MYSQL_VERSION}.tar.gz"


#-----------------------------------------------------------------------------------------------------------------------
MYSQL_NAME=${MYSQL_DOWNLOAD_URL##+(*/)}
MYSQL_HOME="mysql-${MYSQL_VERSION}"
MYSQL_ALIAS='mysql'


#-----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+------------------+------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME         |\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME      |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| MYSQL_HOME       |\e[00m ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}\n"
printf "\e[00;32m| MYSQL_DATA_HOME  |\e[00m ${DATA_HOME}\n"
printf "\e[00;32m+------------------+------------------------------------------------------\e[00m\n"


# ----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}" ]]; then
    printf "\e[00;32m| 기존에 설치된 \"${MYSQL_ALIAS}\"가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${MYSQL_ALIAS}\" service?\e[00m"
    read -e -p ' [Y / n] > ' INSTALL_CHECK
    if [[ -z "${INSTALL_CHECK}" ]]; then
        INSTALL_CHECK="n"
    fi

    if [[ "$(uppercase ${INSTALL_CHECK})" != "Y" ]]; then
        printf "\e[00;32m|\e[00m \e[00;31m\"${MYSQL_ALIAS}\" 서비스 설치 취소...\e[00m\n"
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        exit 1
    fi
fi
sudo rm -rf ${SERVER_HOME}/${MYSQL_ALIAS}
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}


# ----------------------------------------------------------------------------------------------------------------------
# OpenSSL 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}" ]]; then
    if [[ ! -f "${PRGDIR}/library/openssl.sh" ]]; then
        curl -f -L -sS  http://shell.pe.kr/document/install/library/openssl.sh -o /tmp/openssl.sh
        bash   /tmp/openssl.sh
    else
        bash  ${PRGDIR}/library/openssl.sh
    fi
elif [[ ! -d "${SERVER_HOME}/${OPENSSL_ALIAS}" || ! -L "${SERVER_HOME}/${OPENSSL_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${OPENSSL_HOME} ${OPENSSL_ALIAS}
fi


#-----------------------------------------------------------------------------------------------------------------------
# Boost 다운로드.
BOOST_NAME=${BOOST_DOWNLOAD_URL##+(*/)}
BOOST_HOME=${BOOST_NAME%$EXTENSION}

cd ${SRC_HOME}
if [ ! -f "${SRC_HOME}/${BOOST_NAME}" ]; then
    printf "\e[00;32m| ${BOOST_NAME} download (URL : ${BOOST_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${BOOST_DOWNLOAD_URL}
fi

tar xvzf ${BOOST_NAME}


#-----------------------------------------------------------------------------------------------------------------------
# MySQL 설치.
cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${MYSQL_NAME}" ]; then
    printf "\e[00;32m| ${MYSQL_NAME} download (URL : ${MYSQL_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${MYSQL_DOWNLOAD_URL}
else
    printf "\e[00;32m| ${MYSQL_NAME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${MYSQL_HOME}
fi

tar xvzf ${MYSQL_NAME}
cd ${SRC_HOME}/${MYSQL_HOME}

# cmake 를 이용한 configure
INSTALL_CONFIG="-DCMAKE_INSTALL_PREFIX=${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} -DCMAKE_BUILD_TYPE=Release"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_SSL=${SERVER_HOME}/${OPENSSL_ALIAS}"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_ZLIB=system"
INSTALL_CONFIG="${INSTALL_CONFIG} -DDOWNLOAD_BOOST=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_BOOST=${SRC_HOME}/${BOOST_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} -DDEFAULT_CHARSET=utf8"
INSTALL_CONFIG="${INSTALL_CONFIG} -DDEFAULT_COLLATION=utf8_general_ci"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_EXTRA_CHARSETS=all"
INSTALL_CONFIG="${INSTALL_CONFIG} -DENABLED_LOCAL_INFILE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_MYISAM_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_ARCHIVE_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_ARCHIVE_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_INNOBASE_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_PARTITION_STORAGE_ENGINE=1"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_BLACKHOLE_STORAGE_ENGINE=1"

# cmake 를 이용한 configure
cmake ${INSTALL_CONFIG}

# 컴파일
make

# 설치
make install

cd ${SERVER_HOME}
ln -s ./${PROGRAME_HOME}/${MYSQL_HOME} ${MYSQL_ALIAS}

# 소스 삭제.
rm -rf ${SRC_HOME}/${BOOST_HOME}
rm -rf ${SRC_HOME}/${MYSQL_HOME}


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
printf "\e[00;32m| Enter the mysql data home path\e[00m"
read -e -p ' > ' ENTER_DATA_HOME
while [[ -z ${ENTER_DATA_HOME} ]]; do
    printf "\e[00;32m| Enter the mysql data home path\e[00m"
    read -e -p ' > ' ENTER_DATA_HOME
done
export DATA_HOME=${ENTER_DATA_HOME%/}


#-----------------------------------------------------------------------------------------------------------------------
# MySQL 디렉토리 설정.
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

cd ${SERVER_HOME}

sudo chown root:${MYSQL_GROUP} -R ${SERVER_HOME}/${MYSQL_ALIAS}*
sudo chown root:${MYSQL_GROUP} -R ${SERVER_HOME}/${PROGRAME_HOME}/${MYSQL_HOME}*
sudo chown ${MYSQL_USER}.${MYSQL_GROUP} -R ${DATA_HOME}


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
interactive-timeout" | sudo tee ${SERVER_HOME}/${MYSQL_ALIAS}/my.cnf

sudo rm -rf /etc/my.cnf
sudo cp -r ${SERVER_HOME}/${MYSQL_ALIAS}/my.cnf /etc/my.cnf

printf "\e[00;32m| Run \"./mysqld --initialize --user=${MYSQL_USER} --basedir=${SERVER_HOME}/${MYSQL_ALIAS} --datadir=${MYSQL_DATADIR}\"\e[00m\n"
cd ${SERVER_HOME}/${MYSQL_ALIAS}/bin
sudo ./mysqld --initialize --user=${MYSQL_USER} --basedir=${SERVER_HOME}/${MYSQL_ALIAS} --datadir=${MYSQL_DATADIR}

printf "\e[00;32m| Copy \"${SERVER_HOME}/${MYSQL_ALIAS}/support-files/mysql.server\" to \"/etc/init.d/mysqld\"\e[00m\n"
sudo rm -rf /etc/init.d/mysql*
sudo cp ${SERVER_HOME}/${MYSQL_ALIAS}/support-files/mysql.server /etc/init.d/mysql
sleep 0.5

printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| - 설치 후 초기 비밀번호 변경.\e[00m\n"
printf "\e[00;32m|   shell>\e[00m sudo /etc/init.d/mysqld start\n"
printf "\e[00;32m|   shell>\e[00m sudo grep 'temporary password' ${MYSQL_LOGS_DIR}/mysqld.log\n"
printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m|   shell>\e[00m ${SERVER_HOME}/${MYSQL_ALIAS}/bin/mysql -u root -p\n"
printf "\e[00;32m|   mysql>\e[00m SET PASSWORD = PASSWORD('비밀번호');\n"
printf "\e[00;32m|   mysql>\e[00m FLUSH PRIVILEGES;\n"
printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| - 보안을 위한 설정체크를 위한 스크립트 수행.\e[00m\n"
printf "\e[00;32m|   shell>\e[00m sudo ${SERVER_HOME}/${MYSQL_ALIAS}/bin/mysql_secure_installation\n"
printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| ${MYSQL_HOME} install success...\e[00m\n"
printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
