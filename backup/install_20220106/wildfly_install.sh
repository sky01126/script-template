#!/bin/bash
# VERSION : 1.0.0
# ----------------------------------------------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/wildfly_install.sh)


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


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+------------------+--------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME         |\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME      |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| PROGRAME_HOME    |\e[00m ${SERVER_HOME}/${PROGRAME_HOME}\n"
printf "\e[00;32m+------------------+--------------------------------------------------------------\e[00m\n"


# ----------------------------------------------------------------------------------------------------------------------
# JBoss(Wildfly) 다운로드 버전 설정.
JBOSS_VERSION='19.0.0.Final'
JBOSS_DOWNLOAD_URL="https://download.jboss.org/wildfly/${JBOSS_VERSION}/wildfly-${JBOSS_VERSION}.tar.gz"
#JBOSS_DOWNLOAD_URL="https://download.jboss.org/wildfly/${JBOSS_VERSION}/servlet/wildfly-servlet-${JBOSS_VERSION}.tar.gz"


# ----------------------------------------------------------------------------------------------------------------------
# JBoss Service Mode 설정
JBOSS_SERVICE_MODE='standalone'


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m|  _       ___ __    ________         \e[00m\n"
printf "\e[00;32m| | |     / (_) /___/ / __/ /_  __    \e[00m\n"
printf "\e[00;32m| | | /| / / / / __  / /_/ / / / /    \e[00m\n"
printf "\e[00;32m| | |/ |/ / / / /_/ / __/ / /_/ /     \e[00m\n"
printf "\e[00;32m| |__/|__/_/_/\__,_/_/ /_/\__, /      \e[00m\n"
printf "\e[00;32m|                        /____/       \e[00m\n"
printf "\e[00;32m| :: Version :: (v${JBOSS_VERSION}) \e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"


## ----------------------------------------------------------------------------------------------------------------------
## Java 설치 여부 확인
#if [[ "${OS}" == "linux" ]] && [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${JAVA_HOME}" ]]; then
#    if [[ ! -f "${PRGDIR}/library/java.sh" ]]; then
#        curl -f -L -sS  http://shell.pe.kr/document/install/library/java.sh -o /tmp/java.sh
#        bash   /tmp/java.sh
#    else
#        bash  ${PRGDIR}/library/java.sh
#    fi
#fi


# ----------------------------------------------------------------------------------------------------------------------
# Open Java 설치 여부 확인
if [[ "${OS}" == "linux" ]] && [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${REPLACE_OPENJAVA_HOME}" ]]; then
   if [[ ! -f "${PRGDIR}/library/openjava.sh" ]]; then
       curl -f -L -sS  http://shell.pe.kr/document/install/library/openjava.sh -o /tmp/openjava.sh
       bash   /tmp/openjava.sh
   else
       bash  ${PRGDIR}/library/openjava.sh
   fi
fi


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


# ----------------------------------------------------------------------------------------------------------------------
# Java Home Setting
if [[ "${OS}" == "linux" ]]; then
    JAVA_HOME=${SERVER_HOME}/${JAVA_ALIAS}
    PATH=${JAVA_HOME}/bin:${PATH}
fi


# ----------------------------------------------------------------------------------------------------------------------
# Java Version 확인
TMP_JAVA_VERSION=`java -version 2>&1 |awk 'NR==1{ gsub(/"/,""); print $3 }'`
if [[ ${TMP_JAVA_VERSION} = "1.7"* ]]; then
    JAVA_VERSION=7
elif [[ ${TMP_JAVA_VERSION} = "1.8"* ]]; then
    JAVA_VERSION=8
elif [[ ${TMP_JAVA_VERSION} = "1.9"* ]]; then
    JAVA_VERSION=9
elif [[ ${TMP_JAVA_VERSION} = "10"* ]]; then
    JAVA_VERSION=10
else
    JAVA_VERSION=11
fi


# ----------------------------------------------------------------------------------------------------------------------
# JBoss(Wildfly) 설치 여부 확인
TMP_JBOSS_NAME=${JBOSS_DOWNLOAD_URL##+(*/)}
TMP_JBOSS_HOME=${TMP_JBOSS_NAME%$EXTENSION}

# JBoss(Wildfly) Home 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${TMP_JBOSS_HOME}" ]]; then
    printf "\e[00;32m| ${TMP_JBOSS_HOME} install start...\e[00m\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [ ! -f "${SRC_HOME}/${TMP_JBOSS_NAME}" ]; then
        printf "\e[00;32m| ${TMP_JBOSS_HOME} download (URL : ${JBOSS_DOWNLOAD_URL})\e[00m\n"
        curl -L -O ${JBOSS_DOWNLOAD_URL}
    fi

    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TMP_JBOSS_HOME}
    tar xvzf ${TMP_JBOSS_NAME} -C ${SERVER_HOME}/${PROGRAME_HOME}/

    # 불필요한 파일 삭제
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TMP_JBOSS_HOME}/bin/*.bat
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TMP_JBOSS_HOME}/bin/*.ps1
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TMP_JBOSS_HOME}/copyright.txt
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TMP_JBOSS_HOME}/LICENSE.txt
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TMP_JBOSS_HOME}/RELEASE.txt

    cd ${SRC_HOME}
fi


# ----------------------------------------------------------------------------------------------------------------------
JBOSS_HOME="${SERVER_HOME}/${PROGRAME_HOME}/${TMP_JBOSS_HOME}"
JBOSS_BASE="${SERVER_HOME%/}/jboss"


# ----------------------------------------------------------------------------------------------------------------------
## JBoss(Wildfly) Base 경로 설정.
if [[ -z ${TMP_JBOSS_BASE} ]]; then
    printf "\e[00;32m| Enter the jboss base name\e[00m"
    read -e -p " (ex. test) > " TMP_JBOSS_BASE
    if [[ -z ${TMP_JBOSS_BASE} ]]; then
        TMP_JBOSS_BASE=${JBOSS_BASE##*/}
    else
        JBOSS_BASE=${JBOSS_BASE}/${TMP_JBOSS_BASE}
    fi
fi
JBOSS_BASE=${JBOSS_BASE%/}


# ----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${JBOSS_BASE}" ]]; then
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m|\e[00m \e[00;31m기존에 생성된 디렉토리가 있습니다. 삭제하고 다시 생성하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${TMP_JBOSS_BASE}\" service\e[00m"
    read -e -p ' [Y / n](enter)] (default. n) > ' CHECK
    if [[ -z "${CHECK}" ]]; then
        CHECK="n"
    fi

    if [[ "$(uppercase ${CHECK})" != "Y" ]]; then
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        printf "\e[00;32m|\e[00m \e[00;31m\"${TMP_JBOSS_BASE}\" 서비스 생성 취소...\e[00m\n"
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        exit 1
    fi
fi


# ----------------------------------------------------------------------------------------------------------------------
## Xms 설정.
if [[ -z ${MIN_MEMORY} ]]; then
    while [[ true ]]; do
        printf "\e[00;32m| Enter the Xms\e[00m"
        read -e -p " (default. 1024m) > " MIN_MEMORY
        if [[ -z ${MIN_MEMORY} ]]; then
            MIN_MEMORY=1024
            break
        elif [[ "$MIN_MEMORY" -lt 512 ]]; then
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
            printf "\e[00;32m|\e[00m \e[00;31m메모리의 최소값은\e[00m \e[00;31m\"512m\"\e[00m \e[00;32m이상 입력 가능...\e[00m\n"
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        else
            break
        fi
    done
fi


# ----------------------------------------------------------------------------------------------------------------------
## Xms 설정.
if [[ -z ${MAX_MEMORY} ]]; then
    while [[ true ]]; do
        printf "\e[00;32m| Enter the Xmx\e[00m"
        read -e -p " (default. 2048m) > " MAX_MEMORY
        if [[ -z ${MAX_MEMORY} ]]; then
            MAX_MEMORY=2048
            break
        elif [[ "${MAX_MEMORY}" -lt ${MIN_MEMORY} ]]; then
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
            printf "\e[00;32m|\e[00m \e[00;31m메모리의 최대값은\e[00m \e[00;31m\"1024m\"\e[00m \e[00;32m이상 입력 가능...\e[00m\n"
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        else
            break
        fi
    done
fi


# ----------------------------------------------------------------------------------------------------------------------
## 서버 아이피 표시.
if [[ -z ${SERVER_IP} ]]; then
    printf "\e[00;32m+---------------------------------- IP Address -----------------------------------\e[00m\n"
    #if [ "${OS}" == "darwin" ]; then # Mac OS
    #    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
    #else
    #    # echo '- ' | ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'
    #    ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'
    #fi
    #ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'
    for ipaddr in `ip addr | grep "inet " | grep brd | awk '{print $2}' | awk -F/ '{print $1}'`; do
        printf "\e[00;32m|\e[00m ${ipaddr}\n"
    done
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"

    ## 서버 아이피 설정.
    printf "\e[00;32m| Enter the server ip address\e[00m"
    read -e -p " > " SERVER_IP
fi


# ----------------------------------------------------------------------------------------------------------------------
## HTTP 포트 설정.
if [[ -z ${HTTP_PORT} ]]; then
    while [[ true ]]; do
        printf "\e[00;32m| Enter the http port\e[00m"
        read -e -p " (default. 8080) > " HTTP_PORT
        if [[ -z ${HTTP_PORT} ]]; then
            HTTP_PORT=8080
            break
        #elif [[ "$HTTP_PORT" != ^[0-9]+$ ]]; then
        #    HTTP_PORT=8080
        #    break
        elif [[ "$HTTP_PORT" -lt 1000 ]] || [[ "$HTTP_PORT" -ge 10000 ]]; then
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
            printf "\e[00;32m| 포트 번호는 숫자로\e[00m \e[00;31m\"1000 ~ 10000\"\e[00m \e[00;32m까지만 입력 가능...\e[00m\n"
            printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        else
            break
        fi
    done
fi
HTTP_PORT=`echo ${HTTP_PORT} | tr -d ' '`


# ----------------------------------------------------------------------------------------------------------------------
## AJP13 포트 설정.
AJP_PORT="$((HTTP_PORT - 71))"


# ----------------------------------------------------------------------------------------------------------------------
## MANAGER 포트 설정.
HTTP_MANAGER_PORT="$((HTTP_PORT + 1910))"


# ----------------------------------------------------------------------------------------------------------------------
# 기타 포트 설정.
HTTPS_PORT="$((HTTP_PORT + 363))"
HTTPS_MANAGER_PORT="$((HTTP_PORT + 1913))"


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+------------------+--------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SERVER_HOME      |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| JBOSS_HOME       |\e[00m ${JBOSS_HOME}\n"
printf "\e[00;32m| JBOSS_BASE       |\e[00m ${JBOSS_BASE}\n"
printf "\e[00;32m| AUTO_RUN_SCRIPT  |\e[00m ${JBOSS_BASE}/bin/${TMP_JBOSS_BASE}\n"
printf "\e[00;32m| MIN_MEMORY       |\e[00m ${MIN_MEMORY}\n"
printf "\e[00;32m| MAX_MEMORY       |\e[00m ${MAX_MEMORY}\n"

# 아아피 주소가 공백이 아닌 경우에만 설정한다.
if [[ ! -z ${SERVER_IP} ]]; then
    printf "\e[00;32m| SERVER_IP        |\e[00m ${SERVER_IP}\n"
fi

printf "\e[00;32m| HTTP_PORT        |\e[00m ${HTTP_PORT}\n"
printf "\e[00;32m| AJP_PORT         |\e[00m ${AJP_PORT}\n"
printf "\e[00;32m| MANAGER_PORT     |\e[00m ${HTTP_MANAGER_PORT}\n"

# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| 위의 정보와 같이 서비스를 생성하려면 \"Y\"를 입력하세요.\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| Enter whether to install \"${TMP_JBOSS_BASE}\" service\e[00m"
read -e -p ' [Y / n(enter)] (default. Y) > ' CHECK
if [[ -z "${CHECK}" ]]; then
    CHECK="Y"
fi

if [[ "$(uppercase ${CHECK})" != "Y" ]]; then
    printf "\e[00;31m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m|\e[00m \e[00;31m\"${TMP_JBOSS_BASE}\" 서비스 생성 취소...\e[00m\n"
    printf "\e[00;31m+---------------------------------------------------------------------------------\e[00m\n"
    exit 1
fi


# ----------------------------------------------------------------------------------------------------------------------
# 이전 디렉토리 삭제.
if [[ -d "${JBOSS_BASE}" ]]; then
    printf "\e[00;32m| \"${JBOSS_BASE}\" delete...\e[00m\n"
    rm -rf ${JBOSS_BASE}
fi


# ----------------------------------------------------------------------------------------------------------------------
# 이전 서버 디렉토리 삭제
rm -rf ${JBOSS_BASE}

# 서버 디렉토리 생성
mkdir -p ${JBOSS_BASE}/bin

# 설정 디렉토리 복사.
cp -R ${JBOSS_HOME}/${JBOSS_SERVICE_MODE}/* ${JBOSS_BASE}/
rm -rf ${JBOSS_BASE}/deployments/README.txt


# ----------------------------------------------------------------------------------------------------------------------
# appenv.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#  _       ___ __    ________
# | |     / (_) /___/ / __/ /_  __
# | | /| / / / / __  / /_/ / / / /
# | |/ |/ / / / /_/ / __/ / /_/ /
# |__/|__/_/_/\\__,_/_/ /_/\\__, /
#                        /____/
# :: Version :: (v${JBOSS_VERSION})
# ---------------------------------------------------------------------------------
# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [[ -h \"\$PRG\" ]]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done
PRGDIR=\`dirname \"\$PRG\"\`
" > ${JBOSS_BASE}/bin/appenv.sh


if [[ -z ${SERVER_IP} ]]; then
    echo "# ---------------------------------------------------------------------------------
export DOMAIN_BIND_IP='0.0.0.0'
export MULTICAST_BIND_IP='224.0.1.11'
" >> ${JBOSS_BASE}/bin/appenv.sh
else
    echo "# ---------------------------------------------------------------------------------
export DOMAIN_BIND_IP='${SERVER_IP}'
export MULTICAST_BIND_IP='224.0.1.11'
" >> ${JBOSS_BASE}/bin/appenv.sh
fi


echo "# ---------------------------------------------------------------------------------
# Custom Configuration Here

# Server home is the location
export SERVER_HOME=\""${SERVER_HOME%/}"\"

# Java home is the location of the bin files of Java
if [[ -z \"\$JAVA_HOME\" ]]; then
    export JAVA_HOME=\"${SERVER_HOME%/}/java\"
else
    export JAVA_HOME=\$JAVA_HOME
fi

# JBoss home is the location of the bin files of JBoss(Wildfly)
export JBOSS_HOME=\"${JBOSS_HOME}\"

# determine the default base dir, if not set
export JBOSS_BASE_DIR=\`cd \"\$PRGDIR/..\" >/dev/null; pwd\`

# determine the default log dir, if not set
export JBOSS_LOG_DIR=\"\$JBOSS_BASE_DIR/log\"

# determine the default configuration dir, if not set
export JBOSS_CONFIG_DIR=\"\$JBOSS_BASE_DIR/configuration\"

# JBOSS_USER is the default user of JBoss(Wildfly)
export JBOSS_USER=\"${USERNAME}\"
export JBOSS_GROUP=\"${GROUPNAME}\"
" >> ${JBOSS_BASE}/bin/appenv.sh


# ----------------------------------------------------------------------------------------------------------------------
# setenv.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#  _       ___ __    ________
# | |     / (_) /___/ / __/ /_  __
# | | /| / / / / __  / /_/ / / / /
# | |/ |/ / / / /_/ / __/ / /_/ /
# |__/|__/_/_/\\__,_/_/ /_/\\__, /
#                        /____/
# :: Version :: (v${JBOSS_VERSION})
# ---------------------------------------------------------------------------------
# The hotspot server JVM has specific code-path optimizations
# which yield an approximate 10% gain over the client version.
export JAVA_OPTS=\"\$JAVA_OPTS -server\"
export JAVA_OPTS=\"\$JAVA_OPTS -Djboss.modules.system.pkgs=org.jboss.byteman\"

# ---------------------------------------------------------------------------------
export OPENSSL_HOME=\"${SERVER_HOME%/}/openssl\"

# export CLASSPATH=\$CLASSPATH
" > ${JBOSS_BASE}/bin/setenv.sh

# Mac OS는 java.library.path를 설정하고 Linux는 LD_LIBRARY_PATH를 설정한다.
if [[ "${OS}" == "darwin" ]]; then
    echo "# Library path setting
if [[ -n \"\$LD_LIBRARY_PATH\" ]]; then
    export JAVA_OPTS=\"\$JAVA_OPTS -Djava.library.path=\$JBOSS_HOME/lib:\$LD_LIBRARY_PATH\"
else
    export JAVA_OPTS=\"\$JAVA_OPTS -Djava.library.path=\$JBOSS_HOME/lib\"
fi
" >> ${JBOSS_BASE}/bin/setenv.sh
else
    echo "# Library path setting
if [[ -n \"\$LD_LIBRARY_PATH\" ]]; then
    export LD_LIBRARY_PATH=\$APR_HOME/lib:\$OPENSSL_HOME/lib:\$JBOSS_HOME/lib:\$LD_LIBRARY_PATH
else
    export LD_LIBRARY_PATH=\$APR_HOME/lib:\$OPENSSL_HOME/lib:\$JBOSS_HOME/lib
fi
" >> ${JBOSS_BASE}/bin/setenv.sh
fi

echo "# ---------------------------------------------------------------------------------
# discourage address map swapping by setting Xms and Xmx to the same value
# http://confluence.atlassian.com/display/DOC/Garbage+Collector+Performance+Issues
export JAVA_OPTS=\"\$JAVA_OPTS -Xms"${MIN_MEMORY}"m\"
export JAVA_OPTS=\"\$JAVA_OPTS -Xmx"${MAX_MEMORY}"m\"
# export JAVA_OPTS=\"\$JAVA_OPTS -XX:NewSize=256mm\"
# export JAVA_OPTS=\"\$JAVA_OPTS -XX:MaxNewSize=512m\"
" >> ${JBOSS_BASE}/bin/setenv.sh


if [[ ${JAVA_VERSION} -ge 8 ]]; then
    echo "# Java >= 8 : -XX:MetaspaceSize=<metaspace size>[g|m|k] -XX:MaxMetaspaceSize=<metaspace size>[g|m|k]
export JAVA_OPTS=\"\$JAVA_OPTS -XX:MetaspaceSize=256m\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:MaxMetaspaceSize=512m\"
" >> ${JBOSS_BASE}/bin/setenv.sh
else
    echo "# Java < 8 : -XX:PermSize=<perm gen size>[g|m|k] -XX:MaxPermSize=<perm gen size>[g|m|k]
export JAVA_OPTS=\"\$JAVA_OPTS -XX:PermSize=256m\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:MaxPermSize=512m\"
" >> ${JBOSS_BASE}/bin/setenv.sh
fi

echo "# Setting GC option
export JAVA_OPTS=\"\$JAVA_OPTS -XX:+UseG1GC\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:MaxGCPauseMillis=20\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:InitiatingHeapOccupancyPercent=35\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:+ExplicitGCInvokesConcurrent\"

# Disable remote (distributed) garbage collection by Java clients
# and remove ability for applications to call explicit GC collection
export JAVA_OPTS=\"\$JAVA_OPTS -XX:+DisableExplicitGC\"
" >> ${JBOSS_BASE}/bin/setenv.sh

if [[ ${JAVA_VERSION} -ge 9 ]]; then
    echo "# Java 9 이상에서 GC 로그 기록, 서버에 많은 부하를 주지는 않음, 별도의 GC 모니터링이 필요 하다면 추가
export JAVA_OPTS=\"\$JAVA_OPTS -Xlog:gc*:file=\$JBOSS_BASE_DIR/log/gc.log::filecount=10,filesize=10M\"
" >> ${JBOSS_BASE}/bin/setenv.sh
else
    echo "# GC 로그 기록, 서버에 많은 부하를 주지는 않음, 별도의 GC 모니터링이 필요 하다면 추가
export JAVA_OPTS=\"\$JAVA_OPTS -Xloggc:\$JBOSS_BASE_DIR/log/gc.log\"
export JAVA_OPTS=\"\$JAVA_OPTS -verbose:gc\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintGCDetails\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintGCDateStamps\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintGCTimeStamps\"

# Rolling Java GC Logs
export JAVA_OPTS=\"\$JAVA_OPTS -XX:+UseGCLogFileRotation\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:NumberOfGCLogFiles=10\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:GCLogFileSize=10M\"
" >> ${JBOSS_BASE}/bin/setenv.sh
fi

echo "# Save OutOfMemoryError to dump file
export JAVA_OPTS=\"\$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError\"
export JAVA_OPTS=\"\$JAVA_OPTS -XX:HeapDumpPath=\$JBOSS_BASE_DIR/tmp/\"

# ----------------------------------------------------------------------------------------------------
# 난수발생기를 /dev/random이 아닌 /dev/urandom으로 바꾸는 옵션임
export JAVA_OPTS=\"\$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom\"

# Globalization and Headless Environment
export JAVA_OPTS=\"\$JAVA_OPTS -Dfile.encoding=UTF8\"
export JAVA_OPTS=\"\$JAVA_OPTS -Dclient.encoding.override=UTF-8\"
export JAVA_OPTS=\"\$JAVA_OPTS -Duser.timezone=GMT+09:00\"
export JAVA_OPTS=\"\$JAVA_OPTS -Dsun.java2d.opengl=false\"
export JAVA_OPTS=\"\$JAVA_OPTS -Djava.awt.headless=true\"
export JAVA_OPTS=\"\$JAVA_OPTS -Djava.net.preferIPv4Stack=true\"

# Setting spring boot profiles
#export JAVA_OPTS=\"\$JAVA_OPTS -Dspring.profiles.active=dev\"

# Setting spring boot external properties file
#export JAVA_OPTS=\"\$JAVA_OPTS -Dspring.config.location=\$JBOSS_BASE_DIR/conf\"
#export JAVA_OPTS=\"\$JAVA_OPTS -Dspring.config.name=application\"

# ----------------------------------------------------------------------------------------------------
# Setting JBoss port
#export JAVA_OPTS=\"\$JAVA_OPTS -Djboss.management.http.port=${HTTP_MANAGER_PORT}\"
#export JAVA_OPTS=\"\$JAVA_OPTS -Djboss.management.https.port=${HTTPS_MANAGER_PORT}\"
#export JAVA_OPTS=\"\$JAVA_OPTS -Djboss.ajp.port=${AJP_PORT}\"
#export JAVA_OPTS=\"\$JAVA_OPTS -Djboss.http.port=${HTTP_PORT}\"
#export JAVA_OPTS=\"\$JAVA_OPTS -Djboss.https.port=${HTTPS_PORT}\"
" >> ${JBOSS_BASE}/bin/setenv.sh


# ----------------------------------------------------------------------------------------------------------------------
# jboss.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#  _       ___ __    ________
# | |     / (_) /___/ / __/ /_  __
# | | /| / / / / __  / /_/ / / / /
# | |/ |/ / / / /_/ / __/ / /_/ /
# |__/|__/_/_/\\__,_/_/ /_/\\__, /
#                        /____/
# :: Version :: (v${JBOSS_VERSION})
# ---------------------------------------------------------------------------------
# OS 확인.
OS='unknown'
if [[ \"\$(uname)\" == \"Darwin\" ]]; then
    OS=\"darwin\"
elif [[ \"\$(expr substr \$(uname -s) 1 5)\" == \"Linux\" ]]; then
    OS=\"linux\"
fi

# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\`realpath \$0\`
PRGDIR=\`dirname \"\$PRG\"\`

# ---------------------------------------------------------------------------------
source \$PRGDIR/appenv.sh
source \$PRGDIR/setenv.sh

# ---------------------------------------------------------------------------------
# 기본 디렉토리가 없는 경우 생성
if [[ ! -d \"\$JBOSS_LOG_DIR\" ]]; then
    mkdir -p \$JBOSS_LOG_DIR
fi

# Java Home이 환경 설정에 없는 경우 종료.
if [[ -z \"\$JAVA_HOME\" ]]; then
    printf \"\e[00;31mError: JAVA_HOME이 설정되지 않았습니다.\e[00m\\\\n\"
    exit 1
elif [[ ! -d \"\$JAVA_HOME\" ]]; then
    printf \"\e[00;31mError: JAVA_HOME은 디렉토리가 아닙니다.\e[00\\\\n\"
    exit 1
fi

# JBOSS_HOME 설정 여부 확인.
if [[ -z \"\$JBOSS_HOME\" ]]; then
    printf \"\e[00;31mError: JBOSS_HOME이 설정되지 않았습니다.\e[00m\\\\n\"
    echo \"error: JBOSS_HOME is not set\"
    exit 1
elif [[ ! -d \"\$JBOSS_HOME\" ]]; then
    printf \"\e[00;31mError: JBOSS_HOME은 디렉토리가 아닙니다.\e[00m\\\\n\"
    exit 1
fi

# JBOSS_USER 설정 여부 확인.
if [[ -z \"\$JBOSS_USER\" ]]; then
    printf \"\e[00;31mError: JBOSS_USER가 설정되지 않았습니다.\e[00m\\\\n\"
    echo \"error: JBOSS_USER is not set\"
    exit 1
fi

# ---------------------------------------------------------------------------------
# JBOSS Logo
logo() {
    printf \"\e[00;32m  _       ___ __    ________      \e[00m\\\\n\"
    printf \"\e[00;32m | |     / (_) /___/ / __/ /_  __ \e[00m\\\\n\"
    printf \"\e[00;32m | | /| / / / / __  / /_/ / / / / \e[00m\\\\n\"
    printf \"\e[00;32m | |/ |/ / / / /_/ / __/ / /_/ /  \e[00m\\\\n\"
    printf \"\e[00;32m |__/|__/_/_/\__,_/_/ /_/\__, /   \e[00m\\\\n\"
    printf \"\e[00;32m                        /____/    \e[00m\\\\n\"
    printf \"\e[00;32m :: Version :: (v${JBOSS_VERSION})    \e[00m\\\\n\"
    printf \"Using JBOSS_BASE : \$JBOSS_BASE_DIR\\\\n\"
    printf \"Using JBOSS_HOME : \$JBOSS_HOME\\\\n\"
    printf \"Using JAVA_HOME  : \$JAVA_HOME\\\\n\"
    echo
}

# ---------------------------------------------------------------------------------
# Help
usage() {
    printf \"Script start and stop a JBOSS web instance by invoking the standard \$JBOSS_HOME/bin/${JBOSS_SERVICE_MODE}.sh file.\"
    echo
    printf \"Usage: \$0 {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;31mkill\e[00m|\e[00;31mterminate\e[00m|\e[00;32mstatus\e[00m|\e[00;31mrestart\e[00m|\e[00;32mversion\e[00m|\e[00;32mlog\e[00m}\"
    echo
    exit 1
}

# ---------------------------------------------------------------------------------
# 파라미터가 없는 경우 종료.
if [[ -z \"\$1\" ]]; then
    logo
    usage
    exit 1
fi

# ---------------------------------------------------------------------------------
# print friendly logo and information useful for debugging
logo

# ---------------------------------------------------------------------------------
# shutdown wait is wait time in seconds for java proccess to stop (120 sec)
SHUTDOWN_WAIT=120

# ---------------------------------------------------------------------------------
## [중요] OS 계정이 8자가 넘어가면 프로세스 정보에서 계정명으로 보이지 않고 PID 번호로 보여주는 문제가 있음.
server_pid() {
    bootstrap=\"org.jboss.as.${JBOSS_SERVICE_MODE}\"
    jboss=\"/\$(basename \`cd \"\$JBOSS_BASE_DIR/..\" >/dev/null; pwd\`)/\$(basename \$JBOSS_BASE_DIR)/\"
    echo \`ps aux | grep -v grep | grep \$bootstrap | grep \$jboss | grep \$JBOSS_USER | awk '{ print \$2 }'\`
}

# ---------------------------------------------------------------------------------
start() {
    # conf 디렉토리에서 start 스크립트를 실행하면 logback에서 에러 발생해서 디렉토리를 이동한 후 실행하는 스크립트 추가.
    cd \$HOME

    pid=\$(server_pid)
    if [[ -n \"\$pid\" ]]; then
        printf \"JBoss\"
        if [[ \"\$(basename \$JBOSS_BASE_DIR)\" != \"jboss\" ]]; then
            printf \" (\$(basename \$JBOSS_BASE_DIR))\"
        fi
        printf \" is already running. (PID: \e[00;32m\$pid\e[00m)\\\\n\"
        exit 1
    elif [[ \"\$USER\" != \"\$JBOSS_USER\" ]]; then
        printf \"You can not start this JBOSS\"
        if [[ \"\$(basename \$JBOSS_BASE_DIR)\" != \"jboss\" ]]; then
            printf \"(\$(basename \$JBOSS_BASE_DIR))\"
        fi
        printf \" with. \e[00;31m'\$JBOSS_USER'\e[00m\\\\n\"
        exit 1
    fi

    nohup sh \$JBOSS_HOME/bin/${JBOSS_SERVICE_MODE}.sh -b \$DOMAIN_BIND_IP -u \$MULTICAST_BIND_IP >> \$JBOSS_LOG_DIR/server.out 2>&1 &

    printf \"JBoss\"
    if [[ \"\$(basename \$JBOSS_BASE_DIR)\" != \"jboss\" ]]; then
        printf \"(\$(basename \$JBOSS_BASE_DIR))\"
    fi
    printf \" Starting:\"

    sleep 0.5
    retval=\$?
    if [[ \$retval = 0 ]]; then
        printf \"                                           [  \e[00;32mOK\e[00m  ]\\\\n\"
    else
        printf \"                                           [\e[00;32mFAILED\e[00m]\\\\n\"
    fi
    return \$retval
}

# ---------------------------------------------------------------------------------
stop() {
    pid=\$(server_pid)
    if [[ -n \"\$pid\" ]]; then
        if [[ \"\$USER\" != \"\$JBOSS_USER\" ]]; then
            printf \"\e[00;31mYou can not stop this JBoss\"
            if [[ \"\$(basename \$JBOSS_BASE_DIR)\" != \"jboss\" ]]; then
                printf \"(\$(basename \$JBOSS_BASE_DIR))\"
            fi
            printf \" with. '\$JBOSS_USER'\e[00m\\\\n\"
            exit 1
        fi

        printf \"JBoss\"
        if [[ \"\$(basename \$JBOSS_BASE_DIR)\" != \"jboss\" ]]; then
            printf \"(\$(basename \$JBOSS_BASE_DIR))\"
        fi
        printf \" Stopping:\"

        sh \$JBOSS_HOME/bin/jboss-cli.sh --controller=localhost:${HTTP_MANAGER_PORT} --connect --command=:shutdown >> /dev/null 2>&1 &
        sleep 5

        let kwait=\$SHUTDOWN_WAIT
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
            printf \"\e[00;31mKilling processes didn't stop after \$SHUTDOWN_WAIT seconds\e[00m\\\\n\"
            terminate
        fi

        if [[ \$count -gt 0 ]]; then
            printf \"JBoss\"
            if [[ \"\$(basename \$JBOSS_BASE_DIR)\" != \"jboss\" ]]; then
                printf \"(\$(basename \$JBOSS_BASE_DIR))\"
            fi
            printf \" Stop:    \"
        fi

        retval=\$?
        if [[ \$retval = 0 ]]; then
            printf \"                                           [  \e[00;32mOK\e[00m  ]\\\\n\"
        else
            printf \"                                           [\e[00;32mFAILED\e[00m]\\\\n\"
        fi
    else
        printf \"\e[00;31mJBoss\"
        if [[ \"\$(basename \$JBOSS_BASE_DIR)\" != \"jboss\" ]]; then
            printf \"(\$(basename \$JBOSS_BASE_DIR))\"
        fi
        printf \" is not running.\e[00m\\\\n\"
    fi
    return \$retval
}

# ---------------------------------------------------------------------------------
status() {
    pid=\$(server_pid)
    if [[ -n \"\$pid\" ]]; then
        printf \"JBoss is running with pid: \e[00;32m\$pid\e[00m\\\\n\"
    else
        printf \"\e[00;31mJBoss is not running\e[00m\\\\n\"
    fi
}

# ---------------------------------------------------------------------------------
log() {
    log_file=\$JBOSS_BASE_DIR/log/server.log

    # Log.
    if [[ -f \"\$log_file\" ]]; then
        printf \"\e[00;31mTail log file :\e[00m \e[00;32m\$log_file\e[00m\\\\n\"
        tail -f \$log_file
    else
        printf \"\e[00;31mTail log file:\e[00m \e[00;32m\$JBOSS_BASE_DIR/log/server.out\e[00m\\\\n\"
        tail -f \$JBOSS_BASE_DIR/log/server.out
    fi
}

# ---------------------------------------------------------------------------------
terminate() {
    printf \"\e[00;31mTerminating JBoss\"
    if [[ \"\$(basename \$JBOSS_BASE_DIR)\" != \"jboss\" ]]; then
        printf \"(\$(basename \$JBOSS_BASE_DIR))\"
    fi
    printf \"...\e[00m\\\\n\"

    kill -9 \$(server_pid)
}

# ---------------------------------------------------------------------------------
version() {
    echo $JBOSS_VERSION
    return 0
}

# ---------------------------------------------------------------------------------
heapdump() {
    pid=\$(server_pid)
    \$JAVA_HOME/bin/jmap -dump:format=b,file=\$JBOSS_BASE_DIR/tmp/dump-\$pid.hprof \$pid
    chmod 644 \$JBOSS_BASE_DIR/temp/\$pid.hprof
    echo
    return 0
}

# ---------------------------------------------------------------------------------
case \$1 in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        sleep 1
        start
    ;;
    version)
        version
    ;;
    status)
        status
    ;;
    kill)
        terminate
    ;;
    terminate)
        terminate
    ;;
    log)
        log
    ;;
    heapdump)
        heapdump
    ;;
    *)
    usage
    exit 1
esac

exit 0
" > ${JBOSS_BASE}/bin/jboss.sh


# ----------------------------------------------------------------------------------------------------------------------
# start.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#  _       ___ __    ________
# | |     / (_) /___/ / __/ /_  __
# | | /| / / / / __  / /_/ / / / /
# | |/ |/ / / / /_/ / __/ / /_/ /
# |__/|__/_/_/\\__,_/_/ /_/\\__, /
#                        /____/
# :: Version ::   (v${JBOSS_VERSION})
# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\`realpath \$0\`
PRGDIR=\`dirname \"\$PRG\"\`

source \$PRGDIR/appenv.sh

# WildFly Start...
if [ \"\$USER\" == \"root\" ]; then
    su - \$JBOSS_USER -c \"\$JBOSS_BASE_DIR/bin/jboss.sh start\"
else
    \$JBOSS_BASE_DIR/bin/jboss.sh start
fi
" > ${JBOSS_BASE}/bin/start.sh


# ----------------------------------------------------------------------------------------------------------------------
# stop.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#  _       ___ __    ________
# | |     / (_) /___/ / __/ /_  __
# | | /| / / / / __  / /_/ / / / /
# | |/ |/ / / / /_/ / __/ / /_/ /
# |__/|__/_/_/\\__,_/_/ /_/\\__, /
#                        /____/
# :: Version ::   (v${JBOSS_VERSION})
# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\`realpath \$0\`
PRGDIR=\`dirname \"\$PRG\"\`

source \$PRGDIR/appenv.sh

# WildFly Stop...
if [ \"\$USER\" == \"root\" ]; then
    su - \$JBOSS_USER -c \"\$JBOSS_BASE_DIR/bin/jboss.sh stop\"
else
    \$JBOSS_BASE_DIR/bin/jboss.sh stop
fi
" > ${JBOSS_BASE}/bin/stop.sh


# ----------------------------------------------------------------------------------------------------------------------
# restart.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#  _       ___ __    ________
# | |     / (_) /___/ / __/ /_  __
# | | /| / / / / __  / /_/ / / / /
# | |/ |/ / / / /_/ / __/ / /_/ /
# |__/|__/_/_/\\__,_/_/ /_/\\__, /
#                        /____/
# :: Version ::   (v${JBOSS_VERSION})
# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\`realpath \$0\`
PRGDIR=\`dirname \"\$PRG\"\`

source \$PRGDIR/appenv.sh

# WildFly Stop / Start...
if [ \"\$USER\" == \"root\" ]; then
    su - \$JBOSS_USER -c \"\$JBOSS_BASE_DIR/bin/jboss.sh restart\"
else
    \$JBOSS_BASE_DIR/bin/jboss.sh restart
fi
" > ${JBOSS_BASE}/bin/restart.sh


# ----------------------------------------------------------------------------------------------------------------------
# status.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#  _       ___ __    ________
# | |     / (_) /___/ / __/ /_  __
# | | /| / / / / __  / /_/ / / / /
# | |/ |/ / / / /_/ / __/ / /_/ /
# |__/|__/_/_/\\__,_/_/ /_/\\__, /
#                        /____/
# :: Version ::   (v${JBOSS_VERSION})
# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\`realpath \$0\`
PRGDIR=\`dirname \"\$PRG\"\`

source \$PRGDIR/appenv.sh

\$JBOSS_BASE_DIR/bin/jboss.sh status
" > ${JBOSS_BASE}/bin/status.sh


# ----------------------------------------------------------------------------------------------------------------------
# Linux boot start / stop
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#  _       ___ __    ________
# | |     / (_) /___/ / __/ /_  __
# | | /| / / / / __  / /_/ / / / /
# | |/ |/ / / / /_/ / __/ / /_/ /
# |__/|__/_/_/\\__,_/_/ /_/\\__, /
#                        /____/
# :: Version ::   (v${JBOSS_VERSION})
# ---------------------------------------------------------------------------------
# chkconfig: 2345 90 15
# description: WildFly(${SERVICE_NAME}) server.
#

# JBOSS_BASE is the location of the configuration files of this instance of WildFly
export JBOSS_BASE=\"${JBOSS_BASE}\"

# JBOSS_USER is the default user of WildFly
export JBOSS_USER=\""${USERNAME}"\"

su - \$JBOSS_USER -c \"\$JBOSS_BASE_DIR/bin/jboss.sh \$1\"
" > ${JBOSS_BASE}/bin/${TMP_JBOSS_BASE}


# ----------------------------------------------------------------------------------------------------------------------
# Config
if [[ "$(lowercase ${JBOSS_SERVICE_MODE})" == "domain" ]]; then
    echo "<?xml version='1.0' encoding='UTF-8'?>

<domain xmlns=\"urn:jboss:domain:10.0\">
    <extensions>
        <extension module=\"org.jboss.as.ee\"/>
        <extension module=\"org.jboss.as.jmx\"/>
        <extension module=\"org.jboss.as.logging\"/>
        <extension module=\"org.jboss.as.naming\"/>
        <extension module=\"org.jboss.as.security\"/>
        <extension module=\"org.wildfly.extension.core-management\"/>
        <extension module=\"org.wildfly.extension.elytron\"/>
        <extension module=\"org.wildfly.extension.io\"/>
        <extension module=\"org.wildfly.extension.request-controller\"/>
        <extension module=\"org.wildfly.extension.security.manager\"/>
        <extension module=\"org.wildfly.extension.undertow\"/>
    </extensions>
    <system-properties>
        <property name=\"java.net.preferIPv4Stack\" value=\"true\"/>
    </system-properties>
    <management>
        <access-control provider=\"simple\">
            <role-mapping>
                <role name=\"SuperUser\">
                    <include>
                        <user name=\"\$local\"/>
                    </include>
                </role>
            </role-mapping>
        </access-control>
    </management>
    <profiles>
        <profile name=\"default\">
            <subsystem xmlns=\"urn:jboss:domain:logging:7.0\">
                <periodic-rotating-file-handler name=\"FILE\" autoflush=\"true\">
                    <formatter>
                        <named-formatter name=\"PATTERN\"/>
                    </formatter>
                    <file relative-to=\"jboss.server.log.dir\" path=\"server.log\"/>
                    <suffix value=\".yyyy-MM-dd\"/>
                    <append value=\"true\"/>
                </periodic-rotating-file-handler>
                <logger category=\"com.arjuna\">
                    <level name=\"WARN\"/>
                </logger>
                <logger category=\"io.jaegertracing.Configuration\">
                    <level name=\"WARN\"/>
                </logger>
                <logger category=\"org.jboss.as.config\">
                    <level name=\"DEBUG\"/>
                </logger>
                <logger category=\"sun.rmi\">
                    <level name=\"WARN\"/>
                </logger>
                <root-logger>
                    <level name=\"INFO\"/>
                    <handlers>
                        <handler name=\"FILE\"/>
                    </handlers>
                </root-logger>
                <formatter name=\"PATTERN\">
                    <pattern-formatter pattern=\"%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n\"/>
                </formatter>
                <formatter name=\"COLOR-PATTERN\">
                    <pattern-formatter pattern=\"%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n\"/>
                </formatter>
            </subsystem>
            <subsystem xmlns=\"urn:jboss:domain:core-management:1.0\"/>
            <subsystem xmlns=\"urn:jboss:domain:ee:4.0\">
                <spec-descriptor-property-replacement>false</spec-descriptor-property-replacement>
                <concurrent>
                    <context-services>
                        <context-service name=\"default\" jndi-name=\"java:jboss/ee/concurrency/context/default\" use-transaction-setup-provider=\"false\"/>
                    </context-services>
                    <managed-thread-factories>
                        <managed-thread-factory name=\"default\" jndi-name=\"java:jboss/ee/concurrency/factory/default\" context-service=\"default\"/>
                    </managed-thread-factories>
                    <managed-executor-services>
                        <managed-executor-service name=\"default\" jndi-name=\"java:jboss/ee/concurrency/executor/default\" context-service=\"default\" hung-task-threshold=\"60000\" keepalive-time=\"5000\"/>
                    </managed-executor-services>
                    <managed-scheduled-executor-services>
                        <managed-scheduled-executor-service name=\"default\" jndi-name=\"java:jboss/ee/concurrency/scheduler/default\" context-service=\"default\" hung-task-threshold=\"60000\" keepalive-time=\"3000\"/>
                    </managed-scheduled-executor-services>
                </concurrent>
                <default-bindings context-service=\"java:jboss/ee/concurrency/context/default\" managed-executor-service=\"java:jboss/ee/concurrency/executor/default\" managed-scheduled-executor-service=\"java:jboss/ee/concurrency/scheduler/default\" managed-thread-factory=\"java:jboss/ee/concurrency/factory/default\"/>
            </subsystem>
            <subsystem xmlns=\"urn:wildfly:elytron:7.0\" final-providers=\"combined-providers\" disallowed-providers=\"OracleUcrypto\">
                <providers>
                    <aggregate-providers name=\"combined-providers\">
                        <providers name=\"elytron\"/>
                        <providers name=\"openssl\"/>
                    </aggregate-providers>
                    <provider-loader name=\"elytron\" module=\"org.wildfly.security.elytron\"/>
                    <provider-loader name=\"openssl\" module=\"org.wildfly.openssl\"/>
                </providers>
                <audit-logging>
                    <file-audit-log name=\"local-audit\" path=\"audit.log\" relative-to=\"jboss.server.log.dir\" format=\"JSON\"/>
                </audit-logging>
                <security-domains>
                    <security-domain name=\"ApplicationDomain\" default-realm=\"ApplicationRealm\" permission-mapper=\"default-permission-mapper\">
                        <realm name=\"ApplicationRealm\" role-decoder=\"groups-to-roles\"/>
                    </security-domain>
                </security-domains>
                <security-realms>
                    <identity-realm name=\"local\" identity=\"\$local\"/>
                    <properties-realm name=\"ApplicationRealm\">
                        <users-properties path=\"application-users.properties\" relative-to=\"jboss.domain.config.dir\" digest-realm-name=\"ApplicationRealm\"/>
                        <groups-properties path=\"application-roles.properties\" relative-to=\"jboss.domain.config.dir\"/>
                    </properties-realm>
                </security-realms>
                <mappers>
                    <simple-permission-mapper name=\"default-permission-mapper\" mapping-mode=\"first\">
                        <permission-mapping>
                            <principal name=\"anonymous\"/>
                            <permission-set name=\"default-permissions\"/>
                        </permission-mapping>
                        <permission-mapping match-all=\"true\">
                            <permission-set name=\"login-permission\"/>
                            <permission-set name=\"default-permissions\"/>
                        </permission-mapping>
                    </simple-permission-mapper>
                    <constant-realm-mapper name=\"local\" realm-name=\"local\"/>
                    <simple-role-decoder name=\"groups-to-roles\" attribute=\"groups\"/>
                    <constant-role-mapper name=\"super-user-mapper\">
                        <role name=\"SuperUser\"/>
                    </constant-role-mapper>
                </mappers>
                <permission-sets>
                    <permission-set name=\"login-permission\">
                        <permission class-name=\"org.wildfly.security.auth.permission.LoginPermission\"/>
                    </permission-set>
                    <permission-set name=\"default-permissions\"/>
                </permission-sets>
                <http>
                    <provider-http-server-mechanism-factory name=\"global\"/>
                </http>
                <sasl>
                    <sasl-authentication-factory name=\"application-sasl-authentication\" sasl-server-factory=\"configured\" security-domain=\"ApplicationDomain\">
                        <mechanism-configuration>
                            <mechanism mechanism-name=\"JBOSS-LOCAL-USER\" realm-mapper=\"local\"/>
                            <mechanism mechanism-name=\"DIGEST-MD5\">
                                <mechanism-realm realm-name=\"ApplicationRealm\"/>
                            </mechanism>
                        </mechanism-configuration>
                    </sasl-authentication-factory>
                    <configurable-sasl-server-factory name=\"configured\" sasl-server-factory=\"elytron\">
                        <properties>
                            <property name=\"wildfly.sasl.local-user.default-user\" value=\"\$local\"/>
                        </properties>
                    </configurable-sasl-server-factory>
                    <mechanism-provider-filtering-sasl-server-factory name=\"elytron\" sasl-server-factory=\"global\">
                        <filters>
                            <filter provider-name=\"WildFlyElytron\"/>
                        </filters>
                    </mechanism-provider-filtering-sasl-server-factory>
                    <provider-sasl-server-factory name=\"global\"/>
                </sasl>
            </subsystem>
            <subsystem xmlns=\"urn:jboss:domain:io:3.0\">
                <worker name=\"default\"/>
                <buffer-pool name=\"default\"/>
            </subsystem>
            <subsystem xmlns=\"urn:jboss:domain:jmx:1.3\">
                <expose-resolved-model/>
                <expose-expression-model/>
            </subsystem>
            <subsystem xmlns=\"urn:jboss:domain:naming:2.0\"/>
            <subsystem xmlns=\"urn:jboss:domain:request-controller:1.0\"/>
            <subsystem xmlns=\"urn:jboss:domain:security:2.0\">
                <security-domains>
                    <security-domain name=\"other\" cache-type=\"default\">
                        <authentication>
                            <login-module code=\"Remoting\" flag=\"optional\">
                                <module-option name=\"password-stacking\" value=\"useFirstPass\"/>
                            </login-module>
                            <login-module code=\"RealmDirect\" flag=\"required\">
                                <module-option name=\"password-stacking\" value=\"useFirstPass\"/>
                            </login-module>
                        </authentication>
                    </security-domain>
                    <security-domain name=\"jboss-web-policy\" cache-type=\"default\">
                        <authorization>
                            <policy-module code=\"Delegating\" flag=\"required\"/>
                        </authorization>
                    </security-domain>
                    <security-domain name=\"jaspitest\" cache-type=\"default\">
                        <authentication-jaspi>
                            <login-module-stack name=\"dummy\">
                                <login-module code=\"Dummy\" flag=\"optional\"/>
                            </login-module-stack>
                            <auth-module code=\"Dummy\"/>
                        </authentication-jaspi>
                    </security-domain>
                </security-domains>
            </subsystem>
            <subsystem xmlns=\"urn:jboss:domain:security-manager:1.0\">
                <deployment-permissions>
                    <maximum-set>
                        <permission class=\"java.security.AllPermission\"/>
                    </maximum-set>
                </deployment-permissions>
            </subsystem>
            <subsystem xmlns=\"urn:jboss:domain:undertow:9.0\" default-server=\"default-server\" default-virtual-host=\"default-host\" default-servlet-container=\"default\" default-security-domain=\"other\" statistics-enabled=\"\${wildfly.undertow.statistics-enabled:\${wildfly.statistics-enabled:false}}\">
                <buffer-cache name=\"default\"/>
                <server name=\"default-server\">
                    <http-listener name=\"default\" socket-binding=\"http\" redirect-socket=\"https\" enable-http2=\"true\"/>
                    <https-listener name=\"https\" socket-binding=\"https\" security-realm=\"ApplicationRealm\" enable-http2=\"true\"/>
                    <host name=\"default-host\" alias=\"localhost\">
                        <location name=\"/\" handler=\"welcome-content\"/>
                        <http-invoker security-realm=\"ApplicationRealm\"/>
                        <access-log pattern=\"%h %{i,NS-CLIENT-IP} %l %U [%t] &quot;%{i,Host}&quot; &quot;%r&quot; %s %b &quot;%{i,Referer}&quot; &quot;%{i,User-Agent}&quot; TIME:%T\" worker=\"default\" prefix=\"access.\" rotate=\"true\"/>
                    </host>
                </server>
                <servlet-container name=\"default\">
                    <jsp-config/>
                    <websockets/>
                </servlet-container>
                <handlers>
                    <file name=\"welcome-content\" path=\"\${jboss.home.dir}/welcome-content\"/>
                </handlers>
            </subsystem>
        </profile>
    </profiles>
    <interfaces>
        <interface name=\"management\"/>
        <interface name=\"public\"/>
        <interface name=\"unsecure\"/>
        <interface name=\"private\"/>
    </interfaces>
    <socket-binding-groups>
        <socket-binding-group name=\"standard-sockets\" default-interface=\"public\">
            <socket-binding name=\"ajp\" port=\"\${jboss.ajp.port:${AJP_PORT}}\"/>
            <socket-binding name=\"http\" port=\"\${jboss.http.port:${HTTP_PORT}}\"/>
            <socket-binding name=\"https\" port=\"\${jboss.https.port:${HTTPS_PORT}}\"/>
        </socket-binding-group>
    </socket-binding-groups>
    <server-groups>
        <server-group name=\"main-server-group\" profile=\"default\">
            <jvm name=\"default\">
                <heap size=\"${MIN_MEMORY}m\" max-size=\"${MAX_MEMORY}m\"/>
            </jvm>
            <socket-binding-group ref=\"standard-sockets\"/>
        </server-group>
        <server-group name=\"other-server-group\" profile=\"default\">
            <socket-binding-group ref=\"standard-sockets\"/>
        </server-group>
    </server-groups>
    <host-excludes>
        <host-exclude name=\"WildFly10.0\">
            <host-release id=\"WildFly10.0\"/>
            <excluded-extensions>
                <extension module=\"org.wildfly.extension.core-management\"/>
                <extension module=\"org.wildfly.extension.discovery\"/>
                <extension module=\"org.wildfly.extension.elytron\"/>
            </excluded-extensions>
        </host-exclude>
        <host-exclude name=\"WildFly10.1\">
            <host-release id=\"WildFly10.1\"/>
            <excluded-extensions>
                <extension module=\"org.wildfly.extension.core-management\"/>
                <extension module=\"org.wildfly.extension.discovery\"/>
                <extension module=\"org.wildfly.extension.elytron\"/>
            </excluded-extensions>
        </host-exclude>
    </host-excludes>
</domain>
" > ${JBOSS_BASE}/configuration/domain.xml
else # standalone
    echo "<?xml version='1.0' encoding='UTF-8'?>

<server xmlns=\"urn:jboss:domain:10.0\">
    <extensions>
        <extension module=\"org.jboss.as.deployment-scanner\"/>
        <extension module=\"org.jboss.as.ee\"/>
        <extension module=\"org.jboss.as.jmx\"/>
        <extension module=\"org.jboss.as.logging\"/>
        <extension module=\"org.jboss.as.naming\"/>
        <extension module=\"org.jboss.as.security\"/>
        <extension module=\"org.wildfly.extension.core-management\"/>
        <extension module=\"org.wildfly.extension.elytron\"/>
        <extension module=\"org.wildfly.extension.io\"/>
        <extension module=\"org.wildfly.extension.request-controller\"/>
        <extension module=\"org.wildfly.extension.security.manager\"/>
        <extension module=\"org.wildfly.extension.undertow\"/>
    </extensions>
    <management>
        <security-realms>
            <security-realm name=\"ManagementRealm\">
                <authentication>
                    <local default-user=\"\$local\" skip-group-loading=\"true\"/>
                    <properties path=\"mgmt-users.properties\" relative-to=\"jboss.server.config.dir\"/>
                </authentication>
                <authorization map-groups-to-roles=\"false\">
                    <properties path=\"mgmt-groups.properties\" relative-to=\"jboss.server.config.dir\"/>
                </authorization>
            </security-realm>
            <security-realm name=\"ApplicationRealm\">
                <server-identities>
                    <!--
                    <ssl>
                        <keystore path=\"application.keystore\" relative-to=\"jboss.server.config.dir\" keystore-password=\"password\" alias=\"server\" key-password=\"password\" generate-self-signed-certificate-host=\"localhost\"/>
                    </ssl>
                     -->
                </server-identities>
                <authentication>
                    <local default-user=\"\$local\" allowed-users=\"*\" skip-group-loading=\"true\"/>
                    <properties path=\"application-users.properties\" relative-to=\"jboss.server.config.dir\"/>
                </authentication>
                <authorization>
                    <properties path=\"application-roles.properties\" relative-to=\"jboss.server.config.dir\"/>
                </authorization>
            </security-realm>
        </security-realms>
        <audit-log>
            <formatters>
                <json-formatter name=\"json-formatter\"/>
            </formatters>
            <handlers>
                <file-handler name=\"file\" formatter=\"json-formatter\" path=\"audit-log.log\" relative-to=\"jboss.server.data.dir\"/>
            </handlers>
            <logger log-boot=\"true\" log-read-only=\"false\" enabled=\"false\">
                <handlers>
                    <handler name=\"file\"/>
                </handlers>
            </logger>
        </audit-log>
        <management-interfaces>
            <http-interface security-realm=\"ManagementRealm\">
                <http-upgrade enabled=\"true\"/>
                <socket-binding http=\"management-http\"/>
            </http-interface>
        </management-interfaces>
        <access-control provider=\"simple\">
            <role-mapping>
                <role name=\"SuperUser\">
                    <include>
                        <user name=\"\$local\"/>
                    </include>
                </role>
            </role-mapping>
        </access-control>
    </management>
    <profile>
        <subsystem xmlns=\"urn:jboss:domain:logging:7.0\">
            <console-handler name=\"CONSOLE\">
                <level name=\"INFO\"/>
                <formatter>
                    <named-formatter name=\"COLOR-PATTERN\"/>
                </formatter>
            </console-handler>
            <periodic-rotating-file-handler name=\"FILE\" autoflush=\"true\">
                <formatter>
                    <named-formatter name=\"PATTERN\"/>
                </formatter>
                <file relative-to=\"jboss.server.log.dir\" path=\"server.log\"/>
                <suffix value=\".yyyy-MM-dd\"/>
                <append value=\"true\"/>
            </periodic-rotating-file-handler>
            <logger category=\"com.arjuna\">
                <level name=\"WARN\"/>
            </logger>
            <logger category=\"io.jaegertracing.Configuration\">
                <level name=\"WARN\"/>
            </logger>
            <logger category=\"org.jboss.as.config\">
                <level name=\"DEBUG\"/>
            </logger>
            <logger category=\"sun.rmi\">
                <level name=\"WARN\"/>
            </logger>
            <root-logger>
                <level name=\"INFO\"/>
                <handlers>
                    <handler name=\"CONSOLE\"/>
                    <handler name=\"FILE\"/>
                </handlers>
            </root-logger>
            <formatter name=\"PATTERN\">
                <pattern-formatter pattern=\"%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n\"/>
            </formatter>
            <formatter name=\"COLOR-PATTERN\">
                <pattern-formatter pattern=\"%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n\"/>
            </formatter>
        </subsystem>
        <subsystem xmlns=\"urn:jboss:domain:core-management:1.0\"/>
        <subsystem xmlns=\"urn:jboss:domain:deployment-scanner:2.0\">
            <deployment-scanner path=\"deployments\" relative-to=\"jboss.server.base.dir\" scan-interval=\"5000\" runtime-failure-causes-rollback=\"\${jboss.deployment.scanner.rollback.on.failure:false}\"/>
        </subsystem>
        <subsystem xmlns=\"urn:jboss:domain:ee:4.0\">
            <spec-descriptor-property-replacement>false</spec-descriptor-property-replacement>
            <concurrent>
                <context-services>
                    <context-service name=\"default\" jndi-name=\"java:jboss/ee/concurrency/context/default\" use-transaction-setup-provider=\"false\"/>
                </context-services>
                <managed-thread-factories>
                    <managed-thread-factory name=\"default\" jndi-name=\"java:jboss/ee/concurrency/factory/default\" context-service=\"default\"/>
                </managed-thread-factories>
                <managed-executor-services>
                    <managed-executor-service name=\"default\" jndi-name=\"java:jboss/ee/concurrency/executor/default\" context-service=\"default\" hung-task-threshold=\"60000\" keepalive-time=\"5000\"/>
                </managed-executor-services>
                <managed-scheduled-executor-services>
                    <managed-scheduled-executor-service name=\"default\" jndi-name=\"java:jboss/ee/concurrency/scheduler/default\" context-service=\"default\" hung-task-threshold=\"60000\" keepalive-time=\"3000\"/>
                </managed-scheduled-executor-services>
            </concurrent>
            <default-bindings context-service=\"java:jboss/ee/concurrency/context/default\" managed-executor-service=\"java:jboss/ee/concurrency/executor/default\" managed-scheduled-executor-service=\"java:jboss/ee/concurrency/scheduler/default\" managed-thread-factory=\"java:jboss/ee/concurrency/factory/default\"/>
        </subsystem>
        <subsystem xmlns=\"urn:wildfly:elytron:7.0\" final-providers=\"combined-providers\" disallowed-providers=\"OracleUcrypto\">
            <providers>
                <aggregate-providers name=\"combined-providers\">
                    <providers name=\"elytron\"/>
                    <providers name=\"openssl\"/>
                </aggregate-providers>
                <provider-loader name=\"elytron\" module=\"org.wildfly.security.elytron\"/>
                <provider-loader name=\"openssl\" module=\"org.wildfly.openssl\"/>
            </providers>
            <audit-logging>
                <file-audit-log name=\"local-audit\" path=\"audit.log\" relative-to=\"jboss.server.log.dir\" format=\"JSON\"/>
            </audit-logging>
            <security-domains>
                <security-domain name=\"ApplicationDomain\" default-realm=\"ApplicationRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"ApplicationRealm\" role-decoder=\"groups-to-roles\"/>
                    <realm name=\"local\"/>
                </security-domain>
                <security-domain name=\"ManagementDomain\" default-realm=\"ManagementRealm\" permission-mapper=\"default-permission-mapper\">
                    <realm name=\"ManagementRealm\" role-decoder=\"groups-to-roles\"/>
                    <realm name=\"local\" role-mapper=\"super-user-mapper\"/>
                </security-domain>
            </security-domains>
            <security-realms>
                <identity-realm name=\"local\" identity=\"\$local\"/>
                <properties-realm name=\"ApplicationRealm\">
                    <users-properties path=\"application-users.properties\" relative-to=\"jboss.server.config.dir\" digest-realm-name=\"ApplicationRealm\"/>
                    <groups-properties path=\"application-roles.properties\" relative-to=\"jboss.server.config.dir\"/>
                </properties-realm>
                <properties-realm name=\"ManagementRealm\">
                    <users-properties path=\"mgmt-users.properties\" relative-to=\"jboss.server.config.dir\" digest-realm-name=\"ManagementRealm\"/>
                    <groups-properties path=\"mgmt-groups.properties\" relative-to=\"jboss.server.config.dir\"/>
                </properties-realm>
            </security-realms>
            <mappers>
                <simple-permission-mapper name=\"default-permission-mapper\" mapping-mode=\"first\">
                    <permission-mapping>
                        <principal name=\"anonymous\"/>
                        <permission-set name=\"default-permissions\"/>
                    </permission-mapping>
                    <permission-mapping match-all=\"true\">
                        <permission-set name=\"login-permission\"/>
                        <permission-set name=\"default-permissions\"/>
                    </permission-mapping>
                </simple-permission-mapper>
                <constant-realm-mapper name=\"local\" realm-name=\"local\"/>
                <simple-role-decoder name=\"groups-to-roles\" attribute=\"groups\"/>
                <constant-role-mapper name=\"super-user-mapper\">
                    <role name=\"SuperUser\"/>
                </constant-role-mapper>
            </mappers>
            <permission-sets>
                <permission-set name=\"login-permission\">
                    <permission class-name=\"org.wildfly.security.auth.permission.LoginPermission\"/>
                </permission-set>
                <permission-set name=\"default-permissions\"/>
            </permission-sets>
            <http>
                <http-authentication-factory name=\"management-http-authentication\" security-domain=\"ManagementDomain\" http-server-mechanism-factory=\"global\">
                    <mechanism-configuration>
                        <mechanism mechanism-name=\"DIGEST\">
                            <mechanism-realm realm-name=\"ManagementRealm\"/>
                        </mechanism>
                    </mechanism-configuration>
                </http-authentication-factory>
                <provider-http-server-mechanism-factory name=\"global\"/>
            </http>
            <sasl>
                <sasl-authentication-factory name=\"application-sasl-authentication\" sasl-server-factory=\"configured\" security-domain=\"ApplicationDomain\">
                    <mechanism-configuration>
                        <mechanism mechanism-name=\"JBOSS-LOCAL-USER\" realm-mapper=\"local\"/>
                        <mechanism mechanism-name=\"DIGEST-MD5\">
                            <mechanism-realm realm-name=\"ApplicationRealm\"/>
                        </mechanism>
                    </mechanism-configuration>
                </sasl-authentication-factory>
                <sasl-authentication-factory name=\"management-sasl-authentication\" sasl-server-factory=\"configured\" security-domain=\"ManagementDomain\">
                    <mechanism-configuration>
                        <mechanism mechanism-name=\"JBOSS-LOCAL-USER\" realm-mapper=\"local\"/>
                        <mechanism mechanism-name=\"DIGEST-MD5\">
                            <mechanism-realm realm-name=\"ManagementRealm\"/>
                        </mechanism>
                    </mechanism-configuration>
                </sasl-authentication-factory>
                <configurable-sasl-server-factory name=\"configured\" sasl-server-factory=\"elytron\">
                    <properties>
                        <property name=\"wildfly.sasl.local-user.default-user\" value=\"\$local\"/>
                    </properties>
                </configurable-sasl-server-factory>
                <mechanism-provider-filtering-sasl-server-factory name=\"elytron\" sasl-server-factory=\"global\">
                    <filters>
                        <filter provider-name=\"WildFlyElytron\"/>
                    </filters>
                </mechanism-provider-filtering-sasl-server-factory>
                <provider-sasl-server-factory name=\"global\"/>
            </sasl>
        </subsystem>
        <subsystem xmlns=\"urn:jboss:domain:io:3.0\">
            <worker name=\"default\"/>
            <buffer-pool name=\"default\"/>
        </subsystem>
        <subsystem xmlns=\"urn:jboss:domain:jmx:1.3\">
            <expose-resolved-model/>
            <expose-expression-model/>
            <remoting-connector/>
        </subsystem>
        <subsystem xmlns=\"urn:jboss:domain:naming:2.0\"/>
        <subsystem xmlns=\"urn:jboss:domain:request-controller:1.0\"/>
        <subsystem xmlns=\"urn:jboss:domain:security:2.0\">
            <security-domains>
                <security-domain name=\"other\" cache-type=\"default\">
                    <authentication>
                        <login-module code=\"Remoting\" flag=\"optional\">
                            <module-option name=\"password-stacking\" value=\"useFirstPass\"/>
                        </login-module>
                        <login-module code=\"RealmDirect\" flag=\"required\">
                            <module-option name=\"password-stacking\" value=\"useFirstPass\"/>
                        </login-module>
                    </authentication>
                </security-domain>
                <security-domain name=\"jboss-web-policy\" cache-type=\"default\">
                    <authorization>
                        <policy-module code=\"Delegating\" flag=\"required\"/>
                    </authorization>
                </security-domain>
                <security-domain name=\"jaspitest\" cache-type=\"default\">
                    <authentication-jaspi>
                        <login-module-stack name=\"dummy\">
                            <login-module code=\"Dummy\" flag=\"optional\"/>
                        </login-module-stack>
                        <auth-module code=\"Dummy\"/>
                    </authentication-jaspi>
                </security-domain>
            </security-domains>
        </subsystem>
        <subsystem xmlns=\"urn:jboss:domain:security-manager:1.0\">
            <deployment-permissions>
                <maximum-set>
                    <permission class=\"java.security.AllPermission\"/>
                </maximum-set>
            </deployment-permissions>
        </subsystem>
        <subsystem xmlns=\"urn:jboss:domain:undertow:9.0\" default-server=\"default-server\" default-virtual-host=\"default-host\" default-servlet-container=\"default\" default-security-domain=\"other\" statistics-enabled=\"\${wildfly.undertow.statistics-enabled:\${wildfly.statistics-enabled:false}}\">
            <buffer-cache name=\"default\"/>
            <server name=\"default-server\">
                <!-- <http-listener name=\"default\" socket-binding=\"http\" redirect-socket=\"https\" enable-http2=\"true\"/> -->
                <!-- <https-listener name=\"https\" socket-binding=\"https\" security-realm=\"ApplicationRealm\" enable-http2=\"true\"/> -->
                <http-listener name=\"default\" socket-binding=\"http\"/>
                <host name=\"default-host\" alias=\"localhost\">
                    <location name=\"/\" handler=\"welcome-content\"/>
                    <http-invoker security-realm=\"ApplicationRealm\"/>
                    <access-log pattern=\"%h %{i,NS-CLIENT-IP} %l %U [%t] &quot;%{i,Host}&quot; &quot;%r&quot; %s %b &quot;%{i,Referer}&quot; &quot;%{i,User-Agent}&quot; TIME:%T\" worker=\"default\" prefix=\"access.\" rotate=\"true\"/>
                </host>
            </server>
            <servlet-container name=\"default\">
                <jsp-config/>
                <websockets/>
            </servlet-container>
            <handlers>
                <file name=\"welcome-content\" path=\"\${jboss.home.dir}/welcome-content\"/>
            </handlers>
        </subsystem>
    </profile>
    <interfaces>
        <interface name=\"public\">
            <inet-address value=\"\${jboss.bind.address:127.0.0.1}\"/>
        </interface>
        <interface name=\"management\">
            <inet-address value=\"\${jboss.bind.address.management:127.0.0.1}\"/>
        </interface>
    </interfaces>
    <socket-binding-group name=\"standard-sockets\" default-interface=\"public\" port-offset=\"\${jboss.socket.binding.port-offset:0}\">
        <socket-binding name=\"management-http\" interface=\"management\" port=\"\${jboss.management.http.port:${HTTP_MANAGER_PORT}}\"/>
        <!-- <socket-binding name=\"management-https\" interface=\"management\" port=\"\${jboss.management.https.port:${HTTPS_MANAGER_PORT}}\"/> -->
        <socket-binding name=\"ajp\" port=\"\${jboss.ajp.port:${AJP_PORT}}\"/>
        <socket-binding name=\"http\" port=\"\${jboss.http.port:${HTTP_PORT}}\"/>
        <!-- <socket-binding name=\"https\" port=\"\${jboss.https.port:${HTTPS_PORT}}\"/> -->
    </socket-binding-group>
</server>
" > ${JBOSS_BASE}/configuration/standalone.xml
fi


# ----------------------------------------------------------------------------------------------------------------------
# 실행 권한 설정
chmod +x ${JBOSS_BASE}/bin/*.sh
chmod +x ${JBOSS_BASE}/bin/${TMP_JBOSS_BASE}

# 실행 권한 삭제
chmod -x ${JBOSS_BASE}/bin/appenv.sh
chmod -x ${JBOSS_BASE}/bin/setenv.sh


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${TMP_JBOSS_HOME}\" / \"${TMP_JBOSS_BASE}\" install success...\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"

