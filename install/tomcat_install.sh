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
# 멀티 쉘 실행 : bash <(curl -fsSL https://raw.githubusercontent.com/sky01126/script-template/master/install/tomcat_install.sh)
#
# ----------------------- Alias 등록 ------------------------
# echo "# Tomcat start / stop script.
# alias tomcat-start=\"/tomcat/tomcat85/bin/start.sh\"
# alias tomcat-stop=\"/tomcat/tomcat85/bin/stop.sh\"
# alias tomcat-restart=\"/tomcat/tomcat85/bin/restart.sh\"
# " >> $HOME/.bash_aliases && source $HOME/.bashrc
#

# ----------------------------------------------------------------------------------------------------------------------
export SERVER_HOME="/home/server"
# export SRC_HOME="$SERVER_HOME/src"
# export CHECK_TOMCAT="Tomcat8"
# export CATALINA_NAME="tomcat8"
# export MIN_MEMORY="1024"
# export MAX_MEMORY="2048"
# export HTTP_PORT="8080"
# export LOG_HOME='${catalina.base}/logs'
export LOG_HOME='/tc_log'

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
    rm -rf /tmp/setting.sh

    curl -f -L -sS  https://raw.githubusercontent.com/sky01126/script-template/master/install/library/setting.sh -o /tmp/setting.sh
    source /tmp/setting.sh
    # bash   /tmp/setting.sh
else
    source ${PRGDIR}/library/setting.sh
    # bash   ${PRGDIR}/library/setting.sh
fi


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+------------------+--------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME         |\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME      |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| PROGRAME_HOME    |\e[00m ${SERVER_HOME}/${PROGRAME_HOME}\n"
printf "\e[00;32m+------------------+--------------------------------------------------------------\e[00m\n"


# ----------------------------------------------------------------------------------------------------------------------
# 선택된 Tomcat에 따라서 분리한다.
if [[ -z ${CHECK_TOMCAT} ]]; then
    printf "\e[00;32m| Tomcat 설치를 진행하려면 아래 옵션 중 하나를 선택하십시오.\e[00m\n"
    printf "\e[00;32m+------------------+--------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Tomcat8          |\e[00m Tomcat v8.5.X\n"
    printf "\e[00;32m| Tomcat9          |\e[00m Tomcat v9.0.X\n"
    printf "\e[00;32m| Tomcat10         |\e[00m Tomcat v10.1.X\n"
    printf "\e[00;32m+------------------+--------------------------------------------------------------\e[00m\n"

    # ARCHETYPE_ARTIFACT_ID을 받기위해서 대기한다.
    DEFAULT_TOMCAT="Tomcat8"
    printf "\e[00;32m| Enter tomcat name\e[00m"
    read -e -p " (default. ${DEFAULT_TOMCAT}) > " CHECK_TOMCAT
    if [[ -z ${CHECK_TOMCAT}  ]]; then
        CHECK_TOMCAT=${DEFAULT_TOMCAT}
    fi
    #while [[ -z ${CHECK_TOMCAT} ]]; do
    #    printf "\e[00;32m| Enter tomcat name\e[00m"
    #    read -e -p " > " CHECK_TOMCAT
    #done
fi


# ----------------------------------------------------------------------------------------------------------------------
# 앞 / 뒤 공백 제거
CHECK_TOMCAT=${CHECK_TOMCAT##*( )}
if [[ "${CHECK_TOMCAT}" == "Tomcat10" ]]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Tomcat 10.1.x
    TOMCAT_VERSION='10.0.27'
    TOMCAT_DOWNLOAD_URL="https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
    TOMCAT_NATIVE_HOME='tomcat-native-*-src'

    TOMCAT_JULI_DOWNLOAD_URL="https://repo1.maven.org/maven2/com/github/tomcat-slf4j-logback/tomcat10-slf4j-logback/10.1.2/tomcat10-slf4j-logback-10.1.2-tomcat-10.1.2-slf4j-2.0.5-logback-1.4.5.zip"
elif [[ "${CHECK_TOMCAT}" == "Tomcat9" ]]; then
    # ------------------------------------------------------------------------------------------------------------------
    # Tomcat 9.0.x
    TOMCAT_VERSION='9.0.70'
    TOMCAT_DOWNLOAD_URL="http://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
    TOMCAT_NATIVE_HOME='tomcat-native-*-src'

    TOMCAT_JULI_DOWNLOAD_URL="https://repo1.maven.org/maven2/com/github/tomcat-slf4j-logback/tomcat9-slf4j-logback/9.0.70/tomcat9-slf4j-logback-9.0.70-tomcat-9.0.70-slf4j-2.0.5-logback-1.3.5.zip"
else
    # ------------------------------------------------------------------------------------------------------------------
    # Tomcat 8,5.x
    TOMCAT_VERSION='8.5.84'
    TOMCAT_DOWNLOAD_URL="http://archive.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
    TOMCAT_NATIVE_HOME='tomcat-native-*-src'

    TOMCAT_JULI_DOWNLOAD_URL="https://repo1.maven.org/maven2/com/github/tomcat-slf4j-logback/tomcat85-slf4j-logback/8.5.84/tomcat85-slf4j-logback-8.5.84-tomcat-8.5.84-slf4j-2.0.5-logback-1.3.5.zip"
fi


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m|   ______                           __  \e[00m\n"
printf "\e[00;32m|  /_  __/___  ____ ___  _________ _/ /_ \e[00m\n"
printf "\e[00;32m|   / / / __ \/ __  __ \/ ___/ __  / __/ \e[00m\n"
printf "\e[00;32m|  / / / /_/ / / / / / / /__/ /_/ / /_   \e[00m\n"
printf "\e[00;32m| /_/  \____/_/ /_/ /_/\___/\__,_/\__/   \e[00m\n"
printf "\e[00;32m| :: Version ::              (v${TOMCAT_VERSION})  \e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"


# # ----------------------------------------------------------------------------------------------------------------------
# # Java 설치 여부 확인
# if [[ "${OS}" == "linux" ]] && [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${JAVA_HOME}" ]]; then
#     if [[ ! -f "${PRGDIR}/library/java.sh" ]]; then
#         curl -f -L -sS  https://raw.githubusercontent.com/sky01126/script-template/master/install/library/java.sh -o /tmp/java.sh
#         bash   /tmp/java.sh
#     else
#         bash  ${PRGDIR}/library/java.sh
#     fi
# fi


# ----------------------------------------------------------------------------------------------------------------------
# Open Java 설치 여부 확인
if [[ "${OS}" == "linux" ]] && [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${OPENJAVA_HOME}" ]]; then
   if [[ ! -f "${PRGDIR}/library/openjava.sh" ]]; then
       curl -f -L -sS  https://raw.githubusercontent.com/sky01126/script-template/master/install/library/openjava.sh -o /tmp/openjava.sh
       bash /tmp/openjava.sh
   else
       bash ${PRGDIR}/library/openjava.sh
   fi
fi


# ----------------------------------------------------------------------------------------------------------------------
# OpenSSL 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${OPENSSL_HOME}" ]]; then
    if [[ ! -f "${PRGDIR}/library/openssl.sh" ]]; then
        curl -f -L -sS  https://raw.githubusercontent.com/sky01126/script-template/master/install/library/openssl.sh -o /tmp/openssl.sh
        bash   /tmp/openssl.sh
    else
        bash  ${PRGDIR}/library/openssl.sh
    fi
elif [[ ! -d "${SERVER_HOME}/${OPENSSL_ALIAS}" || ! -L "${SERVER_HOME}/${OPENSSL_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${OPENSSL_HOME} ${OPENSSL_ALIAS}
fi


# ----------------------------------------------------------------------------------------------------------------------
# APR / APR Util 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${APR_HOME}" ]]; then
    if [[ ! -f "${PRGDIR}/library/apr.sh" ]]; then
        curl -f -L -sS  https://raw.githubusercontent.com/sky01126/script-template/master/install/library/apr.sh -o /tmp/apr.sh
        bash   /tmp/apr.sh
    else
        bash  ${PRGDIR}/library/apr.sh
    fi
elif [[ ! -d "${SERVER_HOME}/${APR_ALIAS}" || ! -L "${SERVER_HOME}/${APR_ALIAS}" ]]; then
    cd ${SERVER_HOME}
    ln -s ./${PROGRAME_HOME}/${APR_HOME} ${APR_ALIAS}
fi


# ----------------------------------------------------------------------------------------------------------------------
# Java Home Setting
if [[ "${OS}" == "linux" ]]; then
    JAVA_HOME=${SERVER_HOME}/${JAVA_ALIAS}
    PATH=${JAVA_HOME}/bin:${PATH}
fi


# ----------------------------------------------------------------------------------------------------------------------
# Java Version 확인
TMP_JAVA_VERSION=`java -version 2>&1 | awk 'NR==1{ gsub(/"/,""); print $3 }'`
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
# Tomcat 설치 여부 확인
TOMCAT_NAME=${TOMCAT_DOWNLOAD_URL##+(*/)}
TOMCAT_HOME=${TOMCAT_NAME%$EXTENSION}

# Tomcat Home 설치 여부 확인
if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}" ]]; then
    printf "\e[00;32m| ${TOMCAT_HOME} install start...\e[00m\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [ ! -f "${SRC_HOME}/${TOMCAT_NAME}" ]; then
        printf "\e[00;32m| ${TOMCAT_NAME} download (URL : ${TOMCAT_DOWNLOAD_URL})\e[00m\n"
        curl -L -O ${TOMCAT_DOWNLOAD_URL}
    fi

    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}
    tar xvzf ${TOMCAT_NAME} -C ${SERVER_HOME}/${PROGRAME_HOME}/

    cd ${SERVER_HOME}

    # Tomcat Native Install
    cd ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/bin
    tar xvzf tomcat-native.tar.gz
    sleep 0.5

    ## Tomcat Native Install
    cd ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/bin/${TOMCAT_NATIVE_HOME}/native

    ./configure --prefix=${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}         \
                --with-apr=${SERVER_HOME}/${APR_ALIAS}/bin/apr-1-config         \
                --with-java-home=${JAVA_HOME}                                   \
                --with-ssl=${SERVER_HOME}/${OPENSSL_ALIAS}
                #--disable-openssl
    make
    make install

    ls -al ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/lib/libtcnative*

    # 불필요한 파일 삭제
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/bin/*.bat
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/bin/shutdown.sh
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/bin/startup.sh
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/bin/${TOMCAT_NATIVE_HOME}
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/logs
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/NOTICE
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/RELEASE-NOTES
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/RUNNING.txt
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/temp
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/webapps
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/work
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/BUILDING.txt
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/CONTRIBUTING.md
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/README.md

    cd ${SRC_HOME}


    # ----------------------------------------------------------------------------------------------------------------------
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Copy JMS : ${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}/lib/${TOMCAT_JMX_NAME}\e[00m\n"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
fi


# ----------------------------------------------------------------------------------------------------------------------
CATALINA_HOME="${SERVER_HOME}/${PROGRAME_HOME}/${TOMCAT_HOME}"
# CATALINA_BASE="${SERVER_HOME%/}/tomcat"
CATALINA_BASE="${SERVER_HOME%/}"

# Logback Level - DEBUG, INFO, WARN, ERROR
LOG_LEVEL="INFO"


# ----------------------------------------------------------------------------------------------------------------------
## Tomcat Base 경로 설정.
if [[ -z ${CATALINA_NAME} ]]; then
    printf "\e[00;32m| Enter the tomcat base name\e[00m"
    read -e -p " (ex. tomcat) > " CATALINA_NAME
    if [[ -z ${CATALINA_NAME} ]]; then
        CATALINA_NAME="tomcat"
        CATALINA_BASE=${SERVER_HOME}/${CATALINA_NAME}
    else
        CATALINA_BASE=${SERVER_HOME}/${CATALINA_NAME}
    fi
fi
CATALINA_BASE=${CATALINA_BASE%/}

# TODO 로그 강제 설정.
LOG_HOME="${CATALINA_BASE}/logs"

# ----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${CATALINA_BASE}" ]]; then
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m|\e[00m \e[00;31m기존에 생성된 디렉토리가 있습니다. 삭제하고 다시 생성하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${CATALINA_NAME}\" service\e[00m"
    read -e -p ' [Y / n](enter)] (default. n) > ' CHECK
    if [[ -z "${CHECK}" ]]; then
        CHECK="n"
    fi

    if [[ "$(uppercase ${CHECK})" != "Y" ]]; then
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        printf "\e[00;32m|\e[00m \e[00;31m\"${CATALINA_NAME}\" 서비스 생성 취소...\e[00m\n"
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
            printf "\e[00;32m|\e[00m \e[00;31mMemory의 최소값은\e[00m \e[00;31m\"512m\"\e[00m \e[00;32m이상 입력 가능...\e[00m\n"
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
            printf "\e[00;32m|\e[00m \e[00;31mMemory의 최대값은\e[00m \e[00;31m\"1024m\"\e[00m \e[00;32m이상 입력 가능...\e[00m\n"
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
#AJP_PORT="$((HTTP_PORT - 70))"


# ----------------------------------------------------------------------------------------------------------------------
## SHUTDOWN 포트 설정.
SHUTDOWN_PORT="$((HTTP_PORT - 75))"


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+-------------------+--------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SERVER_HOME       |\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| CATALINA_HOME     |\e[00m ${CATALINA_HOME}\n"
printf "\e[00;32m| CATALINA_BASE     |\e[00m ${CATALINA_BASE}\n"
printf "\e[00;32m| AUTO_RUN_SCRIPT   |\e[00m ${CATALINA_BASE}/bin/${CATALINA_NAME}\n"
printf "\e[00;32m| MIN_MEMORY        |\e[00m ${MIN_MEMORY}\n"
printf "\e[00;32m| MAX_MEMORY        |\e[00m ${MAX_MEMORY}\n"

# 아아피 주소가 공백이 아닌 경우에만 설정한다.
if [[ ! -z ${SERVER_IP} ]]; then
    printf "\e[00;32m| SERVER_IP         |\e[00m ${SERVER_IP}\n"
fi

printf "\e[00;32m| HTTP_PORT         |\e[00m ${HTTP_PORT}\n"
printf "\e[00;32m| AJP_PORT          |\e[00m ${AJP_PORT}\n"
printf "\e[00;32m| SHUTDOWN_PORT     |\e[00m ${SHUTDOWN_PORT}\n"


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| 위의 정보와 같이 서비스를 생성하려면 \"Y\"를 입력하세요.\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| Enter whether to install \"${CATALINA_NAME}\" service\e[00m"
read -e -p ' [Y(enter) / n] (default. Y) > ' CHECK
if [[ -z "${CHECK}" ]]; then
    CHECK="Y"
fi

if [[ "$(uppercase ${CHECK})" != "Y" ]]; then
    printf "\e[00;31m+---------------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m|\e[00m \e[00;31m\"${CATALINA_NAME}\" 서비스 생성 취소...\e[00m\n"
    printf "\e[00;31m+---------------------------------------------------------------------------------\e[00m\n"
    exit 1
fi


# ----------------------------------------------------------------------------------------------------------------------
# 이전 디렉토리 삭제.
if [[ -d "${CATALINA_BASE}" ]]; then
    printf "\e[00;32m| \"${CATALINA_BASE}\" delete...\e[00m\n"
    rm -rf ${CATALINA_BASE}
fi


# ----------------------------------------------------------------------------------------------------------------------
# 기존 디렉토리를 삭제한다.
rm -rf ${CATALINA_BASE}

# 기본 디렉토리를 만든다.
mkdir -p ${CATALINA_BASE}/bin
mkdir -p ${CATALINA_BASE}/conf
mkdir -p ${CATALINA_BASE}/lib
mkdir -p ${CATALINA_BASE}/logs
mkdir -p ${CATALINA_BASE}/temp
mkdir -p ${CATALINA_BASE}/webapps/ROOT
mkdir -p ${CATALINA_BASE}/work


# ----------------------------------------------------------------------------------------------------------------------
# config.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#   ______                           __
#  /_  __/___  ____ ___  _________ _/ /_
#   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
#  / / / /_/ / / / / / / /__/ /_/ / /_
# /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# :: Version ::              (v${TOMCAT_VERSION})
# ---------------------------------------------------------------------------------
# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [[ -h \"\${PRG}\" ]]; do
    ls=\`ls -ld \"\${PRG}\"\`
    link=\$(expr \"\$ls\" : '.*-> \(.*\)\$')
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\$(dirname \"\${PRG}\")/\"\$link\"
    fi
done
PRGDIR=\$(dirname \"\${PRG}\")

# ---------------------------------------------------------------------------------
# Custom Configuration Here

# SERVER_HOME is the location
export SERVER_HOME=\""${SERVER_HOME%/}"\"

# JAVA_HOME is the location of the bin files of Java
if [[ -z \"\${JAVA_HOME}\" ]]; then
    export JAVA_HOME=\""${SERVER_HOME%/}/java"\"
else
    export JAVA_HOME=\${JAVA_HOME}
fi

# CATALINA_HOME is the location of the bin files of Tomcat
export CATALINA_HOME=\""${CATALINA_HOME}"\"

# CATALINA_BASE is the location of the configuration files of this instance of Tomcat
export CATALINA_BASE=\`cd \"\${PRGDIR}/..\" >/dev/null; pwd\`

# Full path to a file where stdout and stderr will be redirected.
export CATALINA_OUT=\""${LOG_HOME}/catalina.out"\"

# CATALINA_USER is the default user of tomcat
export CATALINA_USER=\""${USERNAME}"\"
export CATALINA_GROUP=\""${GROUPNAME}"\"
" > ${CATALINA_BASE}/bin/config.sh


# ----------------------------------------------------------------------------------------------------------------------
# setenv.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#   ______                           __
#  /_  __/___  ____ ___  _________ _/ /_
#   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
#  / / / /_/ / / / / / / /__/ /_/ / /_
# /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# :: Version ::              (v${TOMCAT_VERSION})
# ---------------------------------------------------------------------------------
export JAVA_HOME=\"${SERVER_HOME%/}/java\"
export APR_HOME=\"${SERVER_HOME%/}/apr\"
export OPENSSL_HOME=\"${SERVER_HOME%/}/openssl\"
#export CLASSPATH=\${CLASSPATH}
" > ${CATALINA_BASE}/bin/setenv.sh

# Mac OS는 java.library.path를 설정하고 Linux는 LD_LIBRARY_PATH를 설정한다.
if [[ "$OS" == "darwin" ]]; then
    echo "# Library path setting
# Library path setting
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH:+\$LD_LIBRARY_PATH:}\${APR_HOME}/lib:\${OPENSSL_HOME}/lib:\${CATALINA_HOME}/lib:\${LD_LIBRARY_PATH}
" >> ${CATALINA_BASE}/bin/setenv.sh

else
    echo "# Library path setting
# Library path setting
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH:+\$LD_LIBRARY_PATH:}\${APR_HOME}/lib:\${OPENSSL_HOME}/lib:\${CATALINA_HOME}/lib:\${LD_LIBRARY_PATH}
" >> ${CATALINA_BASE}/bin/setenv.sh
fi

echo "# ---------------------------------------------------------------------------------
# discourage address map swapping by setting Xms and Xmx to the same value
# http://confluence.atlassian.com/display/DOC/Garbage+Collector+Performance+Issues
export CATALINA_OPTS=\"\${CATALINA_OPTS} -Xms${MIN_MEMORY}m\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -Xmx${MAX_MEMORY}m\"
# export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:NewSize=256mm\"
# export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:MaxNewSize=512m\"
" >> ${CATALINA_BASE}/bin/setenv.sh


if [[ ${JAVA_VERSION} -ge 8 ]]; then
    echo "# Java >= 8 : -XX:MetaspaceSize=<metaspace size>[g|m|k] -XX:MaxMetaspaceSize=<metaspace size>[g|m|k]
# export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:MetaspaceSize=512m\"
# export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:MaxMetaspaceSize=1024m\"
" >> ${CATALINA_BASE}/bin/setenv.sh
else
    echo "# Java < 8 : -XX:PermSize=<perm gen size>[g|m|k] -XX:MaxPermSize=<perm gen size>[g|m|k]
# export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:PermSize=512m\"
# export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:MaxPermSize=1024m\"
" >> ${CATALINA_BASE}/bin/setenv.sh
fi

echo "# Reserved code cache size
#export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:ReservedCodeCacheSize=256m\"

# Setting GC option
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+UseG1GC\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:MaxGCPauseMillis=20\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:InitiatingHeapOccupancyPercent=35\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+ExplicitGCInvokesConcurrent\"

# Disable remote (distributed) garbage collection by Java clients
# and remove ability for applications to call explicit GC collection
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+DisableExplicitGC\"
" >> ${CATALINA_BASE}/bin/setenv.sh

if [[ ${JAVA_VERSION} -ge 9 ]]; then
    echo "# Java 9 이상에서 GC 로그 기록, 서버에 많은 부하를 주지는 않음, 별도의 GC 모니터링이 필요 하다면 추가
export CATALINA_OPTS=\"\${CATALINA_OPTS} -Xlog:gc*:file=${LOG_HOME}/gc.log::filecount=10,filesize=10M\"
" >> ${CATALINA_BASE}/bin/setenv.sh
else
    echo "# GC 로그 기록, 서버에 많은 부하를 주지는 않음, 별도의 GC 모니터링이 필요 하다면 추가
export CATALINA_OPTS=\"\${CATALINA_OPTS} -Xloggc:${LOG_HOME}/gc.log\"

export CATALINA_OPTS=\"\${CATALINA_OPTS} -verbose:gc\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+PrintGCDetails\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+PrintGCDateStamps\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+PrintGCTimeStamps\"

# Rolling Java GC Logging
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+UseGCLogFileRotation\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:NumberOfGCLogFiles=10\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:GCLogFileSize=10M\"
" >> ${CATALINA_BASE}/bin/setenv.sh
fi

echo "# Save OutOfMemoryError to dump file
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:+HeapDumpOnOutOfMemoryError\"
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:HeapDumpPath=\${CATALINA_BASE}/temp\"

# Error Log
export CATALINA_OPTS=\"\${CATALINA_OPTS} -XX:ErrorFile=${LOG_HOME}/hs_err_%p.log\"
" >> ${CATALINA_BASE}/bin/setenv.sh

# 아아피 주소가 공백이 아닌 경우에만 설정한다.
if [[ ! -z ${SERVER_IP} ]]; then
    echo "## 아이피는 서버 설정에 맞게 수정한다.
export CATALINA_OPTS=\"\${CATALINA_OPTS} -Djava.rmi.server.hostname=${SERVER_IP}\"
" >> ${CATALINA_BASE}/bin/setenv.sh
fi

echo "# ----------------------------------------------------------------------------------------------------
# The hotspot server JVM has specific code-path optimizations
# which yield an approximate 10% gain over the client version.
export JAVA_OPTS=\"-server \${JAVA_OPTS}\"

# Option to change random number generator to / dev / urandom instead of / dev / random
export JAVA_OPTS=\"\${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom\"

# Globalization and Headless Environment
export JAVA_OPTS=\"\${JAVA_OPTS} -Dfile.encoding=UTF8\"
export JAVA_OPTS=\"\${JAVA_OPTS} -Dclient.encoding.override=UTF-8\"
export JAVA_OPTS=\"\${JAVA_OPTS} -Duser.timezone=GMT+09:00\"
export JAVA_OPTS=\"\${JAVA_OPTS} -Dsun.java2d.opengl=false\"
export JAVA_OPTS=\"\${JAVA_OPTS} -Djava.awt.headless=true\"
export JAVA_OPTS=\"\${JAVA_OPTS} -Djava.net.preferIPv4Stack=true\"

# Setting Logback Info
export JAVA_OPTS=\"\${JAVA_OPTS} -Djuli-logback.logLevel='${LOG_LEVEL}'\"
export JAVA_OPTS=\"\${JAVA_OPTS} -Djuli-logback.configurationFile=\${CATALINA_BASE}/conf/logback.xml\"

# Setting spring boot profiles
# export JAVA_OPTS=\"\${JAVA_OPTS} -Dspring.profiles.active=dev\"

# Setting spring boot external properties file
# export JAVA_OPTS=\"\${JAVA_OPTS} -Dspring.config.location=\${CATALINA_BASE}/conf\"
# export JAVA_OPTS=\"\${JAVA_OPTS} -Dspring.config.name=application\"

# Setting Docker Host Server Info
# export JAVA_OPTS=\"\${JAVA_OPTS} -Ddocker.host.server.address=127.0.0.1\"
# export JAVA_OPTS=\"\${JAVA_OPTS} -Ddocker.host.server.port=${HTTP_PORT}\"
" >> ${CATALINA_BASE}/bin/setenv.sh


# ----------------------------------------------------------------------------------------------------------------------
# tomcat.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#   ______                           __
#  /_  __/___  ____ ___  _________ _/ /_
#   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
#  / / / /_/ / / / / / / /__/ /_/ / /_
# /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# :: Version ::              (v${TOMCAT_VERSION})
# ---------------------------------------------------------------------------------
# Multi-instance Apache Tomcat installation with a focus
# on best-practices as defined by Apache, SpringSource, and MuleSoft
# and enterprise use with large-scale deployments.

# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\$(realpath \$0)
PRGDIR=\$(dirname \"\${PRG}\")

source \${PRGDIR}/config.sh

# ---------------------------------------------------------------------------------
export HOSTNAME=h\$(ostname)
# export SERVER_PUBLIC_IP=\$(ifconfig -a | grep \"inet \" | grep \"Bcast:\" | awk '{print \$2}' | awk -F: '{print \$2}' | grep '^211')
# export SERVER_PRIVATE_IP=\$(ifconfig -a | grep \"inet \" | grep \"Bcast:\" | awk '{print \$2}' | awk -F: '{print \$2}' | grep '^10')

# CATALIAN PID
#export CATALINA_PID=\"\${CATALINA_BASE}/work/catalina.pid\"

# 기본 디렉토리가 없는 경우 생성
if [[ ! -d \"\${CATALINA_BASE}/lib\" ]]; then
    mkdir -p \${CATALINA_BASE}/lib
fi
if [[ ! -d \"\${CATALINA_BASE}/logs\" ]]; then
    mkdir -p \${CATALINA_BASE}/logs
fi
if [[ ! -d \"\${CATALINA_BASE}/temp\" ]]; then
    mkdir -p \${CATALINA_BASE}/temp
fi
if [[ ! -d \"\${CATALINA_BASE}/work\" ]]; then
    mkdir -p \${CATALINA_BASE}/work
fi
if [[ ! -d \"\${CATALINA_BASE}/webapps\" ]]; then
    mkdir -p \${CATALINA_BASE}/webapps
fi

# Java Home이 환경 설정에 없는 경우 종료.
if [[ -z \"\${JAVA_HOME}\" ]]; then
    printf \"\e[00;31mError: JAVA_HOME이 설정되지 않았습니다.\e[00m\\\\n\"
    exit 1
elif [[ ! -d \"\${JAVA_HOME}\" ]]; then
    printf \"\e[00;31mError: JAVA_HOME \"\${JAVA_HOME}\"은(는) 디렉토리가 아닙니다.\e[00\\\\n\"
    exit 1
fi

# CATALINA_HOME 설정 여부 확인.
if [[ -z \"\${CATALINA_HOME}\" ]]; then
    printf \"\e[00;31mError: CATALINA_HOME이 설정되지 않았습니다.\e[00m\\\\n\"
    echo \"error: CATALINA_HOME is not set\"
    exit 1
elif [[ ! -d \"\${CATALINA_HOME}\" ]]; then
    printf \"\e[00;31mError: CATALINA_HOME \"\${CATALINA_HOME}\"은(는) 디렉토리가 아닙니다.\e[00m\\\\n\"
    exit 1
fi

# CATALINA_USER 설정 여부 확인.
if [[ -z \"\$CATALINA_USER\" ]]; then
    printf \"\e[00;31mError: CATALINA_USER가 설정되지 않았습니다.\e[00m\\\\n\"
    echo \"error: CATALINA_USER is not set\"
    exit 1
fi

# ---------------------------------------------------------------------------------
# Friendly Logo
logo() {
    printf \"\e[00;32m   ______                           __  \e[00m\\\\n\"
    printf \"\e[00;32m  /_  __/___  ____ ___  _________ _/ /_ \e[00m\\\\n\"
    printf \"\e[00;32m   / / / __ \/ __  __ \/ ___/ __  / __/ \e[00m\\\\n\"
    printf \"\e[00;32m  / / / /_/ / / / / / / /__/ /_/ / /_   \e[00m\\\\n\"
    printf \"\e[00;32m /_/  \____/_/ /_/ /_/\___/\__,_/\__/   \e[00m\\\\n\"
    printf \"\e[00;32m :: Version ::              (v${TOMCAT_VERSION})   \e[00m\\\\n\"
    echo
    printf \"Using CATALINA_BASE:   \${CATALINA_BASE}\\\\n\"
    printf \"Using CATALINA_HOME:   \${CATALINA_HOME}\\\\n\"
    if [ ! -z \"\$CATALINA_PID\" ]; then
        printf \"Using CATALINA_PID:    \$CATALINA_PID\\\\n\"
    fi
    printf \"Using CATALINA_TMP:    \${CATALINA_BASE}/temp\\\\n\"
    printf \"Using JAVA_HOME:       \${JAVA_HOME}\\\\n\"
    echo
}

# ---------------------------------------------------------------------------------
# Help
usage() {
    printf \"Script start and stop a Tomcat web instance by invoking the standard \${CATALINA_HOME}/bin/catalina.sh file.\"
    echo
    printf \"Usage: \$0 {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;31mkill\e[00m|\e[00;31mterminate\e[00m|\e[00;32mstatus\e[00m|\e[00;31mrestart\e[00m|\e[00;32mconfigtest\e[00m|\e[00;32mversion\e[00m|\e[00;32mlog\e[00m}\"
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
# shutdown wait is wait time in seconds for java proccess to stop (60 sec)
SHUTDOWN_WAIT=60

# ---------------------------------------------------------------------------------
## [중요] OS 계정이 8자가 넘어가면 프로세스 정보에서 계정명으로 보이지 않고 PID 번호로 보여주는 문제가 있음.
server_pid() {
    bootstrap=\"org.apache.catalina.startup.Bootstrap\"
    catalina=\"/\$(basename \`cd \"\${CATALINA_BASE}/..\" >/dev/null; pwd\`)/\$(basename \${CATALINA_BASE})/\"
    echo \`ps aux | grep -v grep | grep \$bootstrap | grep \$catalina | grep \$CATALINA_USER | awk '{ print \$2 }'\`
}

# ---------------------------------------------------------------------------------
start() {
    # conf 디렉토리에서 start 스크립트를 실행하면 logback에서 에러 발생해서 디렉토리를 이동한 후 실행하는 스크립트 추가.
    cd \${HOME}

    pid=\$(server_pid)
    if [[ -n \"\$pid\" ]]; then
        printf \"Tomcat\"
        if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
            printf \" (\$(basename \${CATALINA_BASE}))\"
        fi
        printf \" is already running. (PID: \e[00;32m\$pid\e[00m)\\\\n\"
        exit 1
    elif [[ \"\$USER\" != \"\$CATALINA_USER\" ]]; then
        printf \"You can not start this tomcat\"
        if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
            printf \"(\$(basename \${CATALINA_BASE}))\"
        fi
        printf \" with. \e[00;31m'\$CATALINA_USER'\e[00m\\\\n\"
        exit 1
    fi

    nohup sh \${CATALINA_HOME}/bin/catalina.sh start >> /dev/null 2>&1 &

    printf \"Tomcat\"
    if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
        printf \"(\$(basename \${CATALINA_BASE}))\"
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
        #if [[ \"\$USER\" != \"root\" ]] && [[ \"\$USER\" != \"\$CATALINA_USER\" ]]; then
        if [[ \"\$USER\" != \"\$CATALINA_USER\" ]]; then
            printf \"\e[00;31mYou can not stop this tomcat\"
            if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
                printf \"(\$(basename \${CATALINA_BASE}))\"
            fi
            printf \" with. '\$CATALINA_USER'\e[00m\\\\n\"
            exit 1
        fi

        printf \"Tomcat\"
        if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
            printf \"(\$(basename \${CATALINA_BASE}))\"
        fi
        printf \" Stopping:\"

        sh \${CATALINA_HOME}/bin/catalina.sh stop &> /dev/null
        sleep 1

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
            printf \"Tomcat\"
            if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
                printf \"(\$(basename \${CATALINA_BASE}))\"
            fi
            printf \" Stop:    \"
        fi

        retval=\$?
        if [[ \$retval = 0 ]]; then
            printf \"                                           [  \e[00;32mOK\e[00m  ]\\\\n\"
        else
            printf \"                                           [\e[00;32mFAILED\e[00m]\\\\n\"
        fi

        # Tomcat 8의 경우에는 conf/Catalina를 삭제해야한다.
        rm -rf \${CATALINA_BASE}/conf/Catalina
    else
        printf \"\e[00;31mTomcat\"
        if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
            printf \"(\$(basename \${CATALINA_BASE}))\"
        fi
        printf \" is not running.\e[00m\\\\n\"
    fi

    return \$retval
}

# ---------------------------------------------------------------------------------
status() {
    pid=\$(server_pid)
    if [[ -n \"\$pid\" ]]; then
        printf \"Tomcat is running with pid: \e[00;32m\$pid\e[00m\\\\n\"
    else
        printf \"\e[00;31mTomcat is not running\e[00m\\\\n\"
    fi
    echo
}

# ---------------------------------------------------------------------------------
log() {
    tail -f ${LOG_HOME}/catalina.out
}

# ---------------------------------------------------------------------------------
terminate() {
    pid=\$(server_pid)
    if [[ -z \"\$pid\" ]]; then
        printf \"\e[00;31mTomcat\"
        if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
            printf \"(\$(basename \${CATALINA_BASE}))\"
        fi
        printf \" is not running.\e[00m\\\\n\"
    fi

    printf \"\e[00;31mTerminating Tomcat\"
    if [[ \"\$(basename \${CATALINA_BASE})\" != \"tomcat\" ]]; then
        printf \"(\$(basename \${CATALINA_BASE}))\"
    fi
    printf \"...\e[00m\\\\n\"
    echo

    kill -9 \$pid

    if [ ! -z \"\$CATALINA_PID\" ]; then
        rm \$CATALINA_PID
    fi
}

# ---------------------------------------------------------------------------------
configtest() {
    sh \${CATALINA_HOME}/bin/catalina.sh configtest
    echo
    return 0
}

# ---------------------------------------------------------------------------------
version() {
    sh \${CATALINA_HOME}/bin/catalina.sh version
    echo
    return 0
}

# ---------------------------------------------------------------------------------
heapdump() {
    pid=\$(server_pid)
    \${JAVA_HOME}/bin/jmap -dump:format=b,file=\${CATALINA_BASE}/temp/dump-\$pid.hprof \$pid
    chmod 644 \${CATALINA_BASE}/temp/dump-\$pid.hprof
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
    configtest)
        configtest
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
" > ${CATALINA_BASE}/bin/tomcat.sh


# ----------------------------------------------------------------------------------------------------------------------
# start.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#   ______                           __
#  /_  __/___  ____ ___  _________ _/ /_
#   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
#  / / / /_/ / / / / / / /__/ /_/ / /_
# /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# :: Version ::              (v${TOMCAT_VERSION})
# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\$(realpath \$0)
PRGDIR=\$(dirname \"\${PRG}\")

source \${PRGDIR}/config.sh

# Tomcat Start...
if [[ \"\$USER\" == \"root\" ]]; then
    su - \$CATALINA_USER -c \"\${CATALINA_BASE}/bin/tomcat.sh start\"
else
    \${CATALINA_BASE}/bin/tomcat.sh start
fi
" > ${CATALINA_BASE}/bin/start.sh


# ----------------------------------------------------------------------------------------------------------------------
# stop.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#   ______                           __
#  /_  __/___  ____ ___  _________ _/ /_
#   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
#  / / / /_/ / / / / / / /__/ /_/ / /_
# /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# :: Version ::              (v${TOMCAT_VERSION})
# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\$(realpath \$0)
PRGDIR=\$(dirname \"\${PRG}\")

source \${PRGDIR}/config.sh

# ---------------------------------------------------------------------------------
# Tomcat Stop...
if [[ \"\$USER\" == \"root\" ]]; then
    su - \$CATALINA_USER -c \"\${CATALINA_BASE}/bin/tomcat.sh stop\"
else
    \${CATALINA_BASE}/bin/tomcat.sh stop
fi
" > ${CATALINA_BASE}/bin/stop.sh


# ----------------------------------------------------------------------------------------------------------------------
# restart.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#   ______                           __
#  /_  __/___  ____ ___  _________ _/ /_
#   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
#  / / / /_/ / / / / / / /__/ /_/ / /_
# /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# :: Version ::              (v${TOMCAT_VERSION})
# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\$(realpath \$0)
PRGDIR=\$(dirname \"\${PRG}\")

source \${PRGDIR}/config.sh

# ---------------------------------------------------------------------------------
# Tomcat Stop / Start...
if [[ \"\$USER\" == \"root\" ]]; then
    su - \$CATALINA_USER -c \"\${CATALINA_BASE}/bin/tomcat.sh restart\"
else
    \${CATALINA_BASE}/bin/tomcat.sh restart
fi
" > ${CATALINA_BASE}/bin/restart.sh


# ----------------------------------------------------------------------------------------------------------------------
# status.sh
echo "#!/bin/sh
# ---------------------------------------------------------------------------------
#   ______                           __
#  /_  __/___  ____ ___  _________ _/ /_
#   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
#  / / / /_/ / / / / / / /__/ /_/ / /_
# /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# :: Version ::              (v${TOMCAT_VERSION})
# ---------------------------------------------------------------------------------
# 기본 정보 설정.
PRG=\$(realpath \$0)
PRGDIR=\$(dirname \"\${PRG}\")

source \${PRGDIR}/config.sh

# ---------------------------------------------------------------------------------
\${CATALINA_BASE}/bin/tomcat.sh status
" > ${CATALINA_BASE}/bin/status.sh


# # ----------------------------------------------------------------------------------------------------------------------
# # Linux boot start / stop
# echo "#!/bin/sh
# # ---------------------------------------------------------------------------------
# #   ______                           __
# #  /_  __/___  ____ ___  _________ _/ /_
# #   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
# #  / / / /_/ / / / / / / /__/ /_/ / /_
# # /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# # :: Version ::              (v${TOMCAT_VERSION})
# # ---------------------------------------------------------------------------------
# # chkconfig: 2345 90 15
# # description: Tomcat(${SERVICE_NAME}) server.
# #

# # CATALINA_BASE is the location of the configuration files of this instance of Tomcat
# export CATALINA_BASE=\"${CATALINA_BASE}\"

# # CATALINA_USER is the default user of tomcat
# export CATALINA_USER=\""${USERNAME}"\"

# su - \$CATALINA_USER -c \"\${CATALINA_BASE}/bin/tomcat.sh \$1\"
# " > ${CATALINA_BASE}/bin/${CATALINA_NAME}


# # ----------------------------------------------------------------------------------------------------------------------
# # rotatelog.sh
# echo "#!/bin/bash
# # ---------------------------------------------------------------------------------
# #   ______                           __
# #  /_  __/___  ____ ___  _________ _/ /_
# #   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
# #  / / / /_/ / / / / / / /__/ /_/ / /_
# # /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# # :: Version ::              (v${TOMCAT_VERSION})
# # ---------------------------------------------------------------------------------
# # 기본 정보 설정.
# # resolve links - \$0 may be a softlink
# PRG=\"\$0\"
# while [[ -h \"\${PRG}\" ]]; do
#     ls=\$(ls -ld \"\${PRG}\")
#     link=\$(expr \"\$ls\" : '.*-> \(.*\)\$')
#     if expr \"\$link\" : '/.*' > /dev/null; then
#         PRG=\"\$link\"
#     else
#         PRG=\$(dirname \"\${PRG}\")/\"\$link\"
#     fi
# done
# PRGDIR=\$(dirname \"\${PRG}\")

# source \${PRGDIR}/config.sh

# # crontab 에 등록
# # 0 0 * * * ${CATALINA_BASE}/bin/rotatelog.sh

# # 스크립트에 에러가 있는 경우 즉시 종료.
# set -e

# # 파일 경로와 파일명 분리.
# FILE_PATH='${CATALINA_BASE}/logs'
# FILE_EXTENSION='.out'

# # File Extension
# EXTENSION='${EXTENSION}'

# # 파일 백업 경로에서 끝에 \"/\"가 있으면 제거.
# BACKUP_PATH='${CATALINA_BASE}/logs/archive'
# BACKUP_LOG_NAME=\"backup-\$(date -d \"1 day ago\" +\"%Y-%m\").log\"

# # 예외 디렉토리
# EXCEPTION_PATH=\`basename \"\${BACKUP_PATH}\"\`

# # 백업 디렉토리 생성 및 사용자, 그룹을 변경.
# if [[ ! -d \"\${BACKUP_PATH}\" ]]; then
#     mkdir -p \${BACKUP_PATH}
#     chown -R \${CATALINA_USER}:\${CATALINA_GROUP} \${BACKUP_PATH}
# fi

# echo \"-----------------------------------------------------------------------------------------------------------------\" | tee -a \${BACKUP_PATH}/\${BACKUP_LOG_NAME}
# echo \"- 파일 백업 : \$(date +\"%Y:%m:%d %H-%M-%S\")\" | tee -a \${BACKUP_PATH}/\${BACKUP_LOG_NAME}

# # 파일의 디렉토리로 이동.
# pushd \${FILE_PATH} > /dev/null

# # 파일을 백업한다.
# find . ! \\( -path \"./\${EXCEPTION_PATH}\" -prune \\) -name \"*\${FILE_EXTENSION}*\" -type f | while IFS= read -r FILE; do
#     pushd \${FILE_PATH} > /dev/null

#     BACKUP_FILE=\$(basename \"\${FILE}\")
#     BACKUP_NAME=\"\${BACKUP_FILE}.\$(date -d \"1 day ago\" +\"%Y-%m-%d\")\"

#     COUNT=100001;
#     while [[ -f \"\${BACKUP_PATH}/\${BACKUP_NAME}-\${COUNT}.\${EXTENSION}\" ]]; do
#         let COUNT=\${COUNT}+1;
#     done

#     BACKUP_NAME=\"\${BACKUP_NAME}-\${COUNT}\${EXTENSION}\"

#     echo \"FILE - \${FILE}\"
#     echo \"BACKUP_FILE - \${BACKUP_FILE}\"
#     echo \"BACKUP_NAME - \${BACKUP_NAME}\"

#     FILE_SIZE=\$(stat -c %s \${BACKUP_FILE}\)
#     echo \"FILE_SIZE - \${FILE_SIZE}\"

#     if [[ \${FILE_SIZE} = 0 ]]; then
#         echo \"  . Backup file name : '\${BACKUP_FILE}' is empty.\" | tee -a \${BACKUP_PATH}/\${BACKUP_LOG_NAME}
#     else
#         # 백업 파일을 백업 디렉토리에 옮긴다.
#         cp \${BACKUP_FILE} \${BACKUP_PATH}

#         ## OUT 파일을 초기화한다.
#         cat /dev/null > \${BACKUP_FILE}

#         # 백업 디렉토리로 이동한다.
#         pushd \${BACKUP_PATH} > /dev/null

#         # 파일을 압축한다.
#         tar cvzf \${BACKUP_NAME} \${BACKUP_FILE}

#         # 원본파일을 삭제한다.
#         rm -rf \${BACKUP_FILE}

#         echo \"  . Backup file name : '\${BACKUP_FILE}' is initialization complete...\" | tee -a \${BACKUP_PATH}/\${BACKUP_LOG_NAME}

#         chown -R \${CATALINA_USER}:\${CATALINA_GROUP} \${BACKUP_PATH}/\${BACKUP_NAME}
#     fi
# done
# " > ${CATALINA_BASE}/bin/rotatelog.sh


# # ----------------------------------------------------------------------------------------------------------------------
# # log_delete.sh
# echo "#!/bin/bash
# # ---------------------------------------------------------------------------------
# #   ______                           __
# #  /_  __/___  ____ ___  _________ _/ /_
# #   / / / __ \/ __ \`__ \/ ___/ __ \`/ __/
# #  / / / /_/ / / / / / / /__/ /_/ / /_
# # /_/  \____/_/ /_/ /_/\___/\__,_/\__/
# # :: Version ::              (v${TOMCAT_VERSION})
# # ---------------------------------------------------------------------------------
# # 기본 정보 설정.
# # resolve links - \$0 may be a softlink
# PRG=\"\$0\"
# while [[ -h \"\${PRG}\" ]]; do
#     ls=\$(ls -ld \"\${PRG}\")
#     link=\$(expr \"\$ls\" : '.*-> \(.*\)\$')
#     if expr \"\$link\" : '/.*' > /dev/null; then
#         PRG=\"\$link\"
#     else
#         PRG=\$(dirname \"\${PRG}\")/\"\$link\"
#     fi
# done
# PRGDIR=\$(dirname \"\${PRG}\")

# source \${PRGDIR}/config.sh

# # crontab 에 등록
# # 10 0 * * * ${CATALINA_BASE}/bin/log_delete.sh

# # 파일 경로와 파일명 분리.
# MAX_HISTORYS='30'
# FILE_PATH='${CATALINA_BASE}/archive'
# FILE_NAME=\`basename \"\${FILE_PATH}\"\`
# EXTENSION='${EXTENSION}'

# DELETE_LOG_NAME=\"delete-\$(date -d \"1 day ago\" +\"%Y-%m\").log\"

# # 백업 디렉토리 생성 및 사용자, 그룹을 변경.
# if [[ ! -d \"\${FILE_PATH}\" ]]; then
#     mkdir -p \${FILE_PATH}
#     chown -R \${CATALINA_USER}:\${CATALINA_GROUP} \${FILE_PATH}
# fi

# echo \"-----------------------------------------------------------------------------------------------------------------\" | tee -a \${FILE_PATH}/\${DELETE_LOG_NAME}
# echo \"- 파일 삭제 : \$(date +\"%Y:%m:%d %H-%M-%S\")\" | tee -a \${FILE_PATH}/\${DELETE_LOG_NAME}

# # 파일의 디렉토리로 이동.
# pushd \${FILE_PATH} > /dev/null

# # 보관주기가 지난 백업 파일은 삭제한다.
# OLD_BACKUP_FILES=\`find . -mtime +\$((MAX_HISTORYS - 1)) -name \"*\${EXTENSION}\" -type f\`
# if [[ -n \${OLD_BACKUP_FILES} ]]; then
#     rm -rf \${OLD_BACKUP_FILES}
#     echo \"  . 로그 파일 삭제 : \${OLD_BACKUP_FILES}\" | tee -a \${FILE_PATH}/\${DELETE_LOG_NAME}
# else
#     echo \"  . 삭제 대상 로그 파일이 없습니다.\" | tee -a \${FILE_PATH}/\${DELETE_LOG_NAME}
# fi

# chown \${CATALINA_USER}:\${CATALINA_GROUP} \${FILE_PATH}/\${DELETE_LOG_NAME}
# " > ${CATALINA_BASE}/bin/log_delete.sh


# ----------------------------------------------------------------------------------------------------------------------
# ROOT 생성
# TMP_ROOT_URL="http://shell.pe.kr/document/ROOT/ROOT.war"
# TMP_ROOT_NAME=${TMP_ROOT_URL##+(*/)}

# cd ${SRC_HOME}

# # verify that the source exists download
# if [ ! -f "${SRC_HOME}/${TMP_ROOT_NAME}" ]; then
#     printf "\e[00;32m| ${TMP_ROOT_NAME} download...\e[00m\n"
#     curl -O ${TMP_ROOT_URL}
# fi

# cp -rf ${SRC_HOME}/${TMP_ROOT_NAME} ${CATALINA_BASE}/webapps/ROOT
# cd ${CATALINA_BASE}/webapps/ROOT
# jar xvf ${TMP_ROOT_NAME}
# rm -rf ${CATALINA_BASE}/webapps/ROOT/META-INF
# rm -rf ${CATALINA_BASE}/webapps/ROOT/${TMP_ROOT_NAME}


# ----------------------------------------------------------------------------------------------------------------------
# 실행 권한 설정
chmod +x ${CATALINA_BASE}/bin/*.sh
#chmod +x ${CATALINA_BASE}/bin/${CATALINA_NAME}

# 실행 권한 삭제
chmod -x ${CATALINA_BASE}/bin/config.sh
chmod -x ${CATALINA_BASE}/bin/setenv.sh

# 환경 설정 파일 복사
cp -r ${CATALINA_HOME}/conf/* ${CATALINA_BASE}/conf/

# logback을 사용하기위해서 logging.properties 삭제
rm -rf ${CATALINA_BASE}/conf/logging.properties


# -------------------------------------------------------------------------------------------------------
# |                       | BIO            | NIO               | NIO2               | APR               |
# -------------------------------------------------------------------------------------------------------
# | Classname             | Http11Protocol | Http11NioProtocol | Http11Nio2Protocol | Http11AprProtocol |
# | Tomcat Version        | 3.x onwards    | 6.x onwards       | 8.x onwards        | 5.5.x onwards     |
# | Support Polling       | NO             | YES               | YES                | YES               |
# | Polling Size          | N/A            | maxConnections    | maxConnections     | maxConnections    |
# | Read HTTP Request     | Blocking       | Non Blocking      | Non Blocking       | Blocking          |
# | Read HTTP Body        | Blocking       | Sim Blocking      | Blocking           | Blocking          |
# | Write HTTP Response   | Blocking       | Sim Blocking      | Blocking           | Blocking          |
# | Wait for next Request | Blocking       | Non Blocking      | Non Blocking       | Non Blocking      |
# | SSL Support           | Java SSL       | Java SSL          | Java SSL           | OpenSSL           |
# | SSL Handshake         | Blocking       | Non blocking      | Non blocking       | Blocking          |
# | Max Connections       | maxConnections | maxConnections    | maxConnections     | maxConnections    |
# -------------------------------------------------------------------------------------------------------
# - Connector Doc : http://tomcat.apache.org/tomcat-8.5-doc/config/http.html
#   keepAliveTimeout : milliseconds (10000 -> 5000)
#   maxKeepAliveRequests : 서버가 연결을 닫을 때까지 파이프 라인 될 수있는 최대 HTTP 요청 수 (1 : HTTP 1.0과 동일, -1 : 무한대, 100 : Default)

# ----------------------------------------------------------------------------------------------------------------------
# server.xml
mv ${CATALINA_BASE}/conf/server.xml ${CATALINA_BASE}/conf/server.xml.org
echo "<?xml version='1.0' encoding='utf-8'?>
<Server port=\"${SHUTDOWN_PORT}\" shutdown=\"SHUTDOWN\">
  <Listener className=\"org.apache.catalina.startup.VersionLoggerListener\" />
  <!-- Security listener. Documentation at /docs/config/listeners.html
  <Listener className=\"org.apache.catalina.security.SecurityListener\" />
  -->
  <!--APR library loader. Documentation at /docs/apr.html -->
  <Listener className=\"org.apache.catalina.core.AprLifecycleListener\" SSLEngine=\"on\" />
  <!-- Prevent memory leaks due to use of particular java/javax APIs-->
  <Listener className=\"org.apache.catalina.core.JreMemoryLeakPreventionListener\" />
  <Listener className=\"org.apache.catalina.mbeans.GlobalResourcesLifecycleListener\" />
  <Listener className=\"org.apache.catalina.core.ThreadLocalLeakPreventionListener\" />

  <GlobalNamingResources>
    <Resource name=\"UserDatabase\" auth=\"Container\"
              type=\"org.apache.catalina.UserDatabase\"
              description=\"User database that can be updated and saved\"
              factory=\"org.apache.catalina.users.MemoryUserDatabaseFactory\"
              pathname=\"conf/tomcat-users.xml\" />
  </GlobalNamingResources>

  <Service name=\"Catalina\">
    <Connector port=\"${HTTP_PORT}\" protocol=\"org.apache.coyote.http11.Http11AprProtocol\"
               acceptCount=\"100\"
               address=\"0.0.0.0\"
               compression=\"off\"
               connectionTimeout=\"5000\"
               disableUploadTimeout=\"true\"
               enableLookups=\"false\"
               keepAliveTimeout=\"5000\"
               maxHttpHeaderSize=\"8192\"
               maxKeepAliveRequests=\"10\"
               maxThreads=\"2048\"
               minSpareThreads=\"512\"
               processorCache=\"1024\"
               scheme=\"http\"
               secure=\"false\"
               Server= \" \"
               tcpNoDelay=\"true\"
               URIEncoding=\"UTF-8\"
               useBodyEncodingForURI=\"true\" />

    <!-- Define a SSL/TLS HTTP/1.1 Connector on port 8443
         Apache APR Protocol HTTPS Connector - Use Apache Certificates -->
    <!--
    <Connector address=\"127.0.0.1\" port=\"443\" protocol=\"org.apache.coyote.http11.Http11AprProtocol\"
               acceptCount=\"100\"
               address=\"0.0.0.0\"
               compression=\"off\"
               connectionTimeout=\"5000\"
               disableUploadTimeout=\"true\"
               enableLookups=\"false\"
               keepAliveTimeout=\"5000\"
               maxHttpHeaderSize=\"8192\"
               maxKeepAliveRequests=\"10\"
               maxThreads=\"2048\"
               minSpareThreads=\"512\"
               processorCache=\"1024\"
               scheme=\"https\"
               secure=\"false\"
               Server= \" \"
               SSLEnabled=\"true\"
               SSLCertificateFile=\"${CATALINA_BASE}/conf/ssl/httpd/cert.pem\"
               SSLCertificateKeyFile=\"${CATALINA_BASE}/conf/ssl/httpd/newkey.pem\"
               SSLCACertificateFile=\"${CATALINA_BASE}/conf/ssl/httpd/TrueBusiness-Chain_sha2.pem\"
               SSLPassword=\"비밀번호\"
               SSLVerifyClient=\"optional\"
               SSLProtocol=\"TLSv1+TLSv1.1+TLSv1.2\"
               tcpNoDelay=\"true\"
               URIEncoding=\"UTF-8\"
               useBodyEncodingForURI=\"true\" />
    -->

    <!-- Define an AJP 1.3 Connector on port ${AJP_PORT} -->
    <Connector acceptCount=\"100\"
               address=\"0.0.0.0\"
               connectionTimeout=\"5000\"
               enableLookups=\"false\"
               maxThreads=\"2048\"
               minSpareThreads=\"512\"
               port=\"${AJP_PORT}\"
               protocol=\"AJP/1.3\"
               redirectPort=\"8443\"
               secretRequired=\"false\"
               URIEncoding=\"UTF-8\" />

    <!-- Define an AJP 1.3 Connector on port ${AJP_PORT} -->
    <!--
    <Connector acceptCount=\"100\"
               address=\"0.0.0.0\"
               connectionTimeout=\"5000\"
               enableLookups=\"false\"
               maxThreads=\"2048\"
               minSpareThreads=\"512\"
               port=\"${AJP_PORT}\"
               protocol=\"AJP/1.3\"
               redirectPort=\"8443\"
               secret=\"${CATALINA_NAME}\"
               URIEncoding=\"UTF-8\" />
    -->

    <!-- You should set jvmRoute to support load-balancing via AJP ie : -->
    <!-- <Engine name=\"Catalina\" defaultHost=\"localhost\" jvmRoute=\"${CATALINA_NAME}01\"> -->
    <Engine name=\"Catalina\" defaultHost=\"localhost\">

      <!--For clustering, please take a look at documentation at:
          /docs/cluster-howto.html  (simple how to)
          /docs/config/cluster.html (reference documentation) -->
      <!--
      <Cluster className=\"org.apache.catalina.ha.tcp.SimpleTcpCluster\"/>
      -->

      <!-- Use the LockOutRealm to prevent attempts to guess user passwords
           via a brute-force attack -->
      <Realm className=\"org.apache.catalina.realm.LockOutRealm\">
        <Realm className=\"org.apache.catalina.realm.UserDatabaseRealm\"
               resourceName=\"UserDatabase\"/>
      </Realm>

      <Host name=\"localhost\"  appBase=\"webapps\"
            unpackWARs=\"true\" autoDeploy=\"false\">

        <!-- Access log processes all example.
             Documentation at: /docs/config/valve.html
             Note: The pattern used is equivalent to using pattern="common" -->
        <Valve className=\"ch.qos.logback.access.tomcat.LogbackValve\" quiet=\"true\" />

        <!-- Error Report Valve (Tomcat 7.0.55 and later versions) -->
        <Valve className=\"org.apache.catalina.valves.ErrorReportValve\" showReport=\"false\" showServerInfo=\"false\" />
      </Host>
    </Engine>
  </Service>
</Server>
" > ${CATALINA_BASE}/conf/server.xml


# ----------------------------------------------------------------------------------------------------------------------
# logback.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<configuration>
    <property name=\"max.historys\" value=\"30\" />
    <property name=\"catalina_logs\" value=\"${LOG_HOME}\" />

    <appender name=\"CONSOLE\" class=\"org.apache.juli.logging.ch.qos.logback.core.ConsoleAppender\">
        <encoder>
            <pattern>[%date{ISO8601}] [%thread] %-5level: %logger\(%M:%line\) - %msg%n</pattern>
        </encoder>
    </appender>
    <appender name=\"CATALINA-FILE\" class=\"org.apache.juli.logging.ch.qos.logback.core.rolling.RollingFileAppender\">
        <file>\${catalina_logs}/catalina.log</file>
        <append>true</append>
        <encoder>
            <charset>UTF-8</charset>
            <pattern>[%date{ISO8601}] [%thread] %-5level: %logger\(%M:%line\) - %msg%n</pattern>
        </encoder>
        <rollingPolicy class=\"org.apache.juli.logging.ch.qos.logback.core.rolling.TimeBasedRollingPolicy\">
            <fileNamePattern>\${catalina_logs}/archive/catalina.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>\${max.historys}</maxHistory>
        </rollingPolicy>
    </appender>
    <appender name=\"LOCALHOST-FILE\" class=\"org.apache.juli.logging.ch.qos.logback.core.rolling.RollingFileAppender\">
        <file>\${catalina_logs}/localhost.log</file>
        <append>true</append>
        <encoder>
            <charset>UTF-8</charset>
            <pattern>[%date{ISO8601}] [%thread] %-5level: %logger\(%M:%line\) - %msg%n</pattern>
        </encoder>
        <rollingPolicy class=\"org.apache.juli.logging.ch.qos.logback.core.rolling.TimeBasedRollingPolicy\">
            <fileNamePattern>\${catalina_logs}/archive/localhost.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>\${max.historys}</maxHistory>
        </rollingPolicy>
    </appender>
    <!--
    <appender name=\"MANAGER-FILE\" class=\"org.apache.juli.logging.ch.qos.logback.core.rolling.RollingFileAppender\">
        <file>\${catalina_logs}/manager.log</file>
        <append>true</append>
        <encoder>
            <charset>UTF-8</charset>
            <pattern>[%date{ISO8601}] [%thread] %-5level: %logger\(%M:%line\) - %msg%n</pattern>
        </encoder>
        <rollingPolicy class=\"org.apache.juli.logging.ch.qos.logback.core.rolling.TimeBasedRollingPolicy\">
            <fileNamePattern>\${catalina_logs}/archive/manager.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>\${max.historys}</maxHistory>
        </rollingPolicy>
    </appender>
    <appender name=\"HOST-MANAGER-FILE\" class=\"org.apache.juli.logging.ch.qos.logback.core.rolling.RollingFileAppender\">
        <file>\${catalina_logs}/host-manager.log</file>
        <append>true</append>
        <encoder>
            <charset>UTF-8</charset>
            <pattern>[%date{ISO8601}] [%thread] %-5level: %logger\(%M:%line\) - %msg%n</pattern>
        </encoder>
        <rollingPolicy class=\"org.apache.juli.logging.ch.qos.logback.core.rolling.TimeBasedRollingPolicy\">
            <fileNamePattern>\${catalina_logs}/archive/host-manager.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>\${max.historys}</maxHistory>
        </rollingPolicy>
    </appender>
    -->

    <logger name=\"org.apache.catalina\" level=\"\${juli-logback.logLevel}\" additivity=\"false\">
        <appender-ref ref=\"CATALINA-FILE\" />
    </logger>
    <logger name=\"org.apache.catalina.core.ContainerBase.[Catalina]\" level=\"\${juli-logback.logLevel}\" additivity=\"false\">
        <appender-ref ref=\"LOCALHOST-FILE\" />
    </logger>
    <logger name=\"org.apache.catalina.core.ContainerBase.[Catalina].[/manager]\" level=\"\${juli-logback.logLevel}\"
        additivity=\"false\">
        <appender-ref ref=\"MANAGER-FILE\" />
    </logger>
    <logger name=\"org.apache.catalina.core.ContainerBase.[Catalina].[/host-manager]\" level=\"\${juli-logback.logLevel}\"
        additivity=\"false\">
        <appender-ref ref=\"HOST-MANAGER-FILE\" />
    </logger>
    <root level=\"\${juli-logback.logLevel}\">
        <appender-ref ref=\"CONSOLE\" />
    </root>
</configuration>
" > ${CATALINA_BASE}/conf/logback.xml


# ----------------------------------------------------------------------------------------------------------------------
# logback-access.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<configuration>
    <property name=\"max.historys\" value=\"30\" />
    <property name=\"catalina_logs\" value=\"${LOG_HOME}\" />

    <!-- always a good activate OnConsoleStatusListener -->
    <statusListener class=\"ch.qos.logback.core.status.OnConsoleStatusListener\" />

    <appender name=\"ACCESS-LOG-FILE\" class=\"ch.qos.logback.core.rolling.RollingFileAppender\">
        <file>\${catalina_logs}/access.log</file>
        <append>true</append>
        <encoder>
            <charset>UTF-8</charset>
            <!-- %D - Time taken to process the request, in millis -->
            <!-- %T - Time taken to process the request, in seconds -->
            <!-- <pattern>%h %i{NS-CLIENT-IP} %l %u [%t] \"%i{Host}\" \"%r\" %s %b \"%i{Referer}\" \"%i{User-Agent}\" TIME:%T</pattern> -->
            <!-- <pattern>%h %i{X-Forwarded-For} [%i{X-B3-TraceId},%i{X-B3-SpanId},%i{X-B3-ParentSpanId}] %l %u [%t{yyyy-MM-dd HH:mm:ss}] \"%i{Host}\" \"%r\" %s %b \"%i{Referer}\" \"%i{User-Agent}\" TIME:%D</pattern> -->
            <pattern>%h %i{X-Forwarded-For} %l [%t{yyyy-MM-dd HH:mm:ss}] \"%i{Host}\" \"%r\" %s %b \"%i{Referer}\" \"%i{User-Agent}\" TIME:%D</pattern>
        </encoder>
        <rollingPolicy class=\"ch.qos.logback.core.rolling.TimeBasedRollingPolicy\">
            <fileNamePattern>\${catalina_logs}/archive/access.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>\${max.historys}</maxHistory>
        </rollingPolicy>
    </appender>
    <appender-ref ref=\"ACCESS-LOG-FILE\" />
</configuration>
" > ${CATALINA_BASE}/conf/logback-access.xml


# ----------------------------------------------------------------------------------------------------------------------
#if [[ -f ${BASH_FILE} ]]; then
#    if [[ "$CATALINA_NAME" != "tomcat" ]]; then
#        SET_CATALINA_NAME=`awk "/# Tomcat(${CATALINA_NAME}) Start \/ Restart \/ Stop script/" ${BASH_FILE}`
#        if [[ ! -n ${SET_CATALINA_NAME} ]]; then
#            echo "# Tomcat(${CATALINA_NAME}) Start / Restart / Stop script
#alias $(lowercase ${CATALINA_NAME})-start='${CATALINA_BASE}/bin/start.sh     && tail -f ${CATALINA_BASE}/logs/catalina.log'
#alias $(lowercase ${CATALINA_NAME})-stop='${CATALINA_BASE}/bin/stop.sh'
#alias $(lowercase ${CATALINA_NAME})-restart='${CATALINA_BASE}/bin/restart.sh && tail -f ${CATALINA_BASE}/logs/catalina.log'
#" >> ${BASH_FILE}
#        fi
#    else
#        SET_CATALINA_NAME=`awk "/# Tomcat Start \/ Restart \/ Stop script/" ${BASH_FILE}`
#        if [[ ! -n ${SET_CATALINA_NAME} ]]; then
#            echo "# Tomcat Start / Restart / Stop script
#alias tomcat-start='${CATALINA_BASE}/bin/start.sh     && tail -f ${CATALINA_BASE}/logs/catalina.log'
#alias tomcat-stop='${CATALINA_BASE}/bin/stop.sh'
#alias tomcat-restart='${CATALINA_BASE}/bin/restart.sh && tail -f ${CATALINA_BASE}/logs/catalina.log'
#" >> ${BASH_FILE}
#        fi
#    fi
#fi


# ----------------------------------------------------------------------------------------------------------------------
cd ${CATALINA_BASE}/lib


# ----------------------------------------------------------------------------------------------------------------------
cd ${SRC_HOME}

# tomcat-juli
TOMCAT_JULI_NAME=${TOMCAT_JULI_DOWNLOAD_URL##+(*/)}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${TOMCAT_JULI_NAME}" ]; then
    printf "\e[00;32m| ${TOMCAT_JULI_NAME} download...\e[00m\n"
    curl -L -O ${TOMCAT_JULI_DOWNLOAD_URL}
fi

#  확장자 제거
TOMCAT_JULI_DIR=${TOMCAT_JULI_NAME%.*}
if [[ ! -d "${TOMCAT_JULI_DIR}" ]]; then
    unzip ${TOMCAT_JULI_NAME} -d ${TOMCAT_JULI_DIR}
fi

printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| Copy tomcat juli : ${CATALINA_BASE}/bin/tomcat-juli.jar\e[00m\n"
cp ${SRC_HOME}/${TOMCAT_JULI_DIR}/bin/tomcat-juli.jar ${CATALINA_BASE}/bin/

printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| Copy logback : ${CATALINA_BASE}/lib/logback*\e[00m\n"
cp ${SRC_HOME}/${TOMCAT_JULI_DIR}/lib/* ${CATALINA_BASE}/lib/

# 소스 디렉토리 삭제.
rm -rf ${SRC_HOME}/${TOMCAT_JULI_DIR}


# ----------------------------------------------------------------------------------------------------------------------
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${TOMCAT_HOME}\" / \"${CATALINA_NAME}\" install success...\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"

