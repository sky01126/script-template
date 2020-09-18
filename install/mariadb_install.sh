#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/mariadb_install.sh)

# xtrabackup 설치 시 필요한 라이브러리.
# yum install cmake gcc gcc-c++ libaio libaio-devel automake autoconf bison libtool ncurses-devel libgcrypt-devel libev-devel libcurl-devel vim-common


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
#MARIADB_VERSION="10.2.14"
MARIADB_VERSION="10.1.34"
MARIADB_DOWNLOAD_URL="http://ftp.kaist.ac.kr/mariadb/mariadb-${MARIADB_VERSION}/source/mariadb-${MARIADB_VERSION}.tar.gz"


#-----------------------------------------------------------------------------------------------------------------------
MARIADB_NAME=${MARIADB_DOWNLOAD_URL##+(*/)}
MARIADB_HOME=${MARIADB_NAME%$EXTENSION}
MARIADB_ALIAS='mariadb'


#-----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+--------------------+----------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME           |\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME        |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| MARIADB_HOME       |\e[00m ${SERVER_HOME}/${PROGRAME_HOME}/${MARIADB_HOME}\n"
printf "\e[00;32m| MARIADB_DATA_HOME  |\e[00m ${DATA_HOME}\n"
printf "\e[00;32m+--------------------+----------------------------------------------------\e[00m\n"
echo


# ----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${MARIADB_HOME}" ]]; then
    printf "\e[00;32m| 기존에 설치된 \"${MARIADB_ALIAS}\"가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${MARIADB_ALIAS}\" service?\e[00m"
    read -e -p ' [Y / n] > ' INSTALL_CHECK
    if [[ -z "${INSTALL_CHECK}" ]]; then
        INSTALL_CHECK="n"
    fi

    if [[ "$(uppercase ${INSTALL_CHECK})" != "Y" ]]; then
        printf "\e[00;32m|\e[00m \e[00;31m\"${MARIADB_ALIAS}\" 서비스 설치 취소...\e[00m\n"
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        exit 1
    fi
fi
sudo rm -rf ${SERVER_HOME}/${MARIADB_ALIAS}
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${MARIADB_HOME}


#-----------------------------------------------------------------------------------------------------------------------
# MariaDB 설치.
cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${MARIADB_NAME}" ]; then
    printf "\n \e[00;32m ${MARIADB_NAME} download...\e[00m\n"
    wget ${MARIADB_DOWNLOAD_URL}
else
    printf "\n \e[00;32m ${MARIADB_NAME} delete...\e[00m\n"
    rm -rf ${SRC_HOME}/${MARIADB_HOME}
fi

tar xvzf ${MARIADB_NAME}
cd ${SRC_HOME}/${MARIADB_HOME}

# cmake 를 이용한 configure
INSTALL_CONFIG="-DCMAKE_INSTALL_PREFIX=${SERVER_HOME}/${PROGRAME_HOME}/${MARIADB_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} -DCMAKE_BUILD_TYPE=Release"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_EXTRA_CHARSETS=complex"
INSTALL_CONFIG="${INSTALL_CONFIG} -DWITH_EMBEDDED_SERVER=ON"
INSTALL_CONFIG="${INSTALL_CONFIG} -DSKIP_TESTS=ON"
INSTALL_CONFIG="${INSTALL_CONFIG} -DTOKUDB_OK=0"

# cmake 를 이용한 configure
cmake ${INSTALL_CONFIG}

# 컴파일
make

# 설치
make install

cd ${SERVER_HOME}
ln -s ./${PROGRAME_HOME}/${MARIADB_HOME} ${MARIADB_ALIAS}

sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/COPYING
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/COPYING.LESSER
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/COPYING.thirdparty
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/CREDITS
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/EXCEPTIONS-CLIENT
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/INSTALL-BINARY
sudo rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/README README-wsrep


# 소스 삭제.
rm -rf ${SRC_HOME}/${MARIADB_HOME}


#-----------------------------------------------------------------------------------------------------------------------
MARIADB_GROUP='dba'
MARIADB_USER='mysql'

## Group이 있는지 확인한다.
export GET_GROUP_INFO=`grep ${MARIADB_GROUP} /etc/group`
if [[ -z "${GET_GROUP_INFO}" ]]; then
    sudo groupadd -g 300 ${MARIADB_GROUP}
fi

export GET_USER_INFO=`grep ${MARIADB_USER} /etc/passwd`
if [[ -z "${GET_USER_INFO}" ]]; then
    sudo useradd -M -d /nonexistent  -u 300 -g ${MARIADB_GROUP} -G ${MARIADB_GROUP},wheel -s /bin/false $MARIADB_USER
fi

sudo yum install -y zlib
echo


#-----------------------------------------------------------------------------------------------------------------------
# MariaDB Data Home을 입력으로 받는다.
printf "\e[00;32m| Enter the mysql data home path\e[00m"
read -e -p ' > ' ENTER_DATA_HOME
while [[ -z ${ENTER_DATA_HOME} ]]; do
    printf "\e[00;32m| Enter the mysql data home path\e[00m"
    read -e -p ' > ' ENTER_DATA_HOME
done
export DATA_HOME=${ENTER_DATA_HOME%/}


#-----------------------------------------------------------------------------------------------------------------------
# MariaDB 디렉토리 설정.
sudo rm -rf ${DATA_HOME}/*

MARIADB_DATADIR=${DATA_HOME}/data
sudo mkdir -p ${MARIADB_DATADIR}

MARIADB_TMPDIR=${DATA_HOME}/tmp
sudo mkdir -p ${MARIADB_TMPDIR}

MARIADB_LOG_BIN=${DATA_HOME}/binlog/mariadb-bin
sudo mkdir -p ${MARIADB_LOG_BIN}

MARIADB_RELAY_LOG=${DATA_HOME}/binlog/mariadb-relay
sudo mkdir -p ${MARIADB_RELAY_LOG}

MARIADB_INNODB_DATA_HOME_DIR=${DATA_HOME}/data
sudo mkdir -p ${MARIADB_INNODB_DATA_HOME_DIR}

MARIADB_INNODB_LOG_GROUP_HOME_DIR=${DATA_HOME}/iblog
sudo mkdir -p ${MARIADB_INNODB_LOG_GROUP_HOME_DIR}

MARIADB_LOGS_DIR=${DATA_HOME}/logs
sudo mkdir -p ${MARIADB_LOGS_DIR}

MARIADB_WORD_DIR=${DATA_HOME}/work
sudo mkdir -p ${MARIADB_WORD_DIR}

cd ${SERVER_HOME}

sudo chown root:${MARIADB_GROUP} -R ${SERVER_HOME}/${MARIADB_ALIAS}*
sudo chown root:${MARIADB_GROUP} -R ${SERVER_HOME}/${PROGRAME_HOME}/${MARIADB_HOME}*
sudo chown ${MARIADB_USER}.${MARIADB_GROUP} -R ${DATA_HOME}


#-----------------------------------------------------------------------------------------------------------------------
echo "[client]
port                                = 3306
socket                              = ${MARIADB_WORD_DIR}/${MARIADB_ALIAS}.sock

[mysqld]
port                                = 3306
pid_file                            = ${MARIADB_WORD_DIR}/${MARIADB_ALIAS}.pid
socket                              = ${MARIADB_WORD_DIR}/${MARIADB_ALIAS}.sock
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
basedir                             = ${SERVER_HOME}/${MARIADB_ALIAS}
datadir                             = ${MARIADB_DATADIR}
tmpdir                              = ${MARIADB_TMPDIR}
log_bin                             = ${MARIADB_LOG_BIN}
relay_log                           = ${MARIADB_RELAY_LOG}
innodb_data_home_dir                = ${MARIADB_INNODB_DATA_HOME_DIR}
innodb_log_group_home_dir           = ${MARIADB_INNODB_LOG_GROUP_HOME_DIR}

## log
log_error                           = ${MARIADB_LOGS_DIR}/${MARIADB_ALIAS}.log
slow_query_log_file                 = ${MARIADB_LOGS_DIR}/${MARIADB_ALIAS}_slow_query.log

## config character set (utf8 / euckr)
character_set_client_handshake      = FALSE
character_set_server                = utf8
collation_server                    = utf8_general_ci
init_connect                        = \"SET collation_connection = utf8_general_ci\"
init_connect                        = \"SET NAMES utf8\"

## Do not distinguish platoon characters
lower_case_table_names              = 1

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
interactive-timeout" | sudo tee ${SERVER_HOME}/${MARIADB_ALIAS}/my.cnf

sudo rm -rf /etc/my.cnf
sudo cp -r ${SERVER_HOME}/${MARIADB_ALIAS}/my.cnf /etc/my.cnf

printf "\e[00;32mRun ./scripts/mysql_install_db --user=${MARIADB_USER} --defaults-file=/etc/my.cnf\e[00m\n"
cd ${SERVER_HOME}/${MARIADB_ALIAS}
sudo ./scripts/mysql_install_db --user=${MARIADB_USER} --defaults-file=/etc/my.cnf

printf "\e[00;32mCopy ${SERVER_HOME}/${MARIADB_ALIAS}/support-files/mysql.server to /etc/init.d/mysqld\e[00m\n"
sudo rm -rf /etc/init.d/mysql*
sudo cp ${SERVER_HOME}/${MARIADB_ALIAS}/support-files/mysql.server /etc/init.d/mysqld
sleep 0.5

printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| - 설치 후 초기 비밀번호 변경.\e[00m\n"
printf "\e[00;32m|   shell>\e[00m sudo cat /root/.mysql_secret\n"
printf "\e[00;32m|   shell>\e[00m sudo /etc/init.d/mysqld start\n"
printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| - 보안을 위한 설정체크를 위한 스크립트 수행.\e[00m\n"
printf "\e[00;32m|   shell>\e[00m sudo ${SERVER_HOME}/${MARIADB_ALIAS}/bin/mysql_secure_installation  --socket ${MARIADB_WORD_DIR}/${MARIADB_ALIAS}.sock\n"
printf "\e[00;32m|   shell>\e[00m sudo rm -rf /root/.mysql_secret\n"
printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| ${MYSQL_HOME} install success...\e[00m\n"
printf "\e[00;32m|-------------------------------------------------------------------------\e[00m\n"
