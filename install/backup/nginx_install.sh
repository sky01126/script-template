#!/bin/bash
# ------------------------------------------------------------------------------
#     __ __
#    / //_/__  __  ______  __  ______ _____  ____ _
#   / ,< / _ \/ / / / __ \/ / / / __ `/ __ \/ __ `/
#  / /| /  __/ /_/ / / / / /_/ / /_/ / / / / /_/ /
# /_/ |_\___/\__,_/_/ /_/\__, /\__,_/_/ /_/\__, /
#                       /____/            /____/
#
# 멀티 쉘 실행 : bash <(curl -fsSL https://raw.githubusercontent.com/sky01126/script-template/master/install/nginx_install.sh)
#
# 중요 - 아래 패키지 설치, Apache와 Nginx에서 사용되는 OpenSSL은 소스를 가지고 설치를 진행한다.
#
# ------------------------ CentOS --------------------------
# - 개발 리눅스
#   yum install -y zlib zlib-devel openssl-devel gd gd-devel ImageMagick ImageMagick-devel bzip2-devel bzip2 ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel libxml2-devel libxslt-devel  xz-devel
#   yum install -y zlib-devel gd-devel ImageMagick-devel bzip2-devel ncurses-devel libpcap-devel libxml2-devel libxslt-devel
# - 상용 리눅스
#   yum install -y zlib gd ImageMagick bzip2
#
# ------------------------ Ubuntu --------------------------
# sudo apt install -y zlib1g-dev libgd-dev bzip2 libbz2-dev libncurses5-dev libpcap-dev libxml2-dev libxslt-dev
#
# ------------------------- MacOS --------------------------
# brew install libgd --with-freetype --with-libtiff --with-libvpx && brew info libgd
#
# --------------------- GeoIP Install ----------------------
# curl -O -L https://fossies.org/linux/misc/GeoIP-1.6.12.tar.gz
# tar xvzf GeoIP-1.6.12.tar.gz && cd GeoIP-1.6.12
# ./configure && make && sudo make install
#
# ----------------------- Alias 등록 ------------------------
# echo "# Nginx Start / Stop Script.
# alias nginx-start=\"sudo   /home/server/nginx/bin/start.sh\"
# alias nginx-stop=\"sudo    /home/server/nginx/bin/stop.sh\"
# alias nginx-restart=\"sudo /home/server/nginx/bin/restart.sh\"
# alias nginx-conf=\"sudo /home/server/nginx/bin/configtest.sh\"
# " >> $HOME/.bash_aliases && source $HOME/.bashrc


# ------------------------------------------------------------------------------
# Exit on error
set -e

# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

SERVER_HOME=/nkapps/nkshop

## OS를 확인한다.
export OS='unknown'
if [ "$(uname)" == "Darwin" ]; then
    OS="darwin"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    OS="linux"
fi

unset TMOUT


# ------------------------------------------------------------------------------
PRG="$0"
while [ -h "$PRG" ]; do
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


# ------------------------------------------------------------------------------
# 멀티의 setting.sh 읽기
# if [ ! -f "${PRGDIR}/library/setting.sh" ]; then
#     source <(curl -fsSL https://raw.githubusercontent.com/sky01126/script-template/master/install/library/setting.sh)
# else
#     source ${PRGDIR}/library/setting.sh
#     bash   ${PRGDIR}/library/setting.sh
# fi
source <(curl -fsSL https://raw.githubusercontent.com/sky01126/script-template/master/install/library/setting.sh)

# ------------------------------------------------------------------------------
# NginX 설치 버전 선택.
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| NginX 설치를 진행하려면 아래 옵션 중 하나를 선택하십시오.\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| 1.12 :\e[00m NginX v1.12.X\n"
printf "\e[00;32m| 1.13 :\e[00m NginX v1.13.X\n"
printf "\e[00;32m| 1.14 :\e[00m NginX v1.14.X\n"
printf "\e[00;32m| 1.16 :\e[00m NginX v1.16.X\n"
printf "\e[00;32m| 1.19 :\e[00m NginX v1.19.X\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"

# ARCHETYPE_ARTIFACT_ID을 받기위해서 대기한다.
export NGINX_VERSION='1.21.4'
printf "\e[00;32m| Enter nginx version\e[00m"
read -e -p " (default. 1.21) > " CHECK_NGINX_VERSION
if [ "${CHECK_NGINX_VERSION}" == "1.12" ]; then
    NGINX_VERSION='1.12.2'
elif [ "${CHECK_NGINX_VERSION}" == "1.14" ]; then
    NGINX_VERSION='1.14.2'
elif [ "${CHECK_NGINX_VERSION}" == "1.16" ]; then
    NGINX_VERSION='1.16.1'
elif [ "${CHECK_NGINX_VERSION}" == "1.19" ]; then
    NGINX_VERSION='1.19.9'
fi


# ------------------------------------------------------------------------------
# NginX
export NGINX_DOWNLOAD_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
export NGINX_RTMP_MODULE_DOWNLOAD_URL="https://github.com/arut/nginx-rtmp-module.git"
export NGINX_HEADERS_MORE_MODULE_DOWNLOAD_URL="https://github.com/openresty/headers-more-nginx-module.git"


# ------------------------------------------------------------------------------
# Nginx Install
export NGINX_NAME=${NGINX_DOWNLOAD_URL##+(*/)}
export NGINX_HOME=${NGINX_NAME%$EXTENSION}
export NGINX_ALIAS='nginx'


# ------------------------------------------------------------------------------
printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m|     _   _____________   ___  __   \n"
printf "\e[00;32m|    / | / / ____/  _/ | / / |/ /   \n"
printf "\e[00;32m|   /  |/ / / __ / //  |/ /|   /    \n"
printf "\e[00;32m|  / /|  / /_/ // // /|  //   |     \n"
printf "\e[00;32m| /_/ |_/\____/___/_/ |_//_/|_|     \n"
printf "\e[00;32m|  :: Nginx ::        (v${NGINX_VERSION})    \n"

# ------------------------------------------------------------------------------
printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| SRC_HOME     :\e[00m ${SRC_HOME}\n"
printf "\e[00;32m| SERVER_HOME  :\e[00m ${SERVER_HOME}\n"
printf "\e[00;32m| NGINX_HOME   :\e[00m ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}\n"
printf "\e[00;32m| NGINX_ALIAS  :\e[00m ${SERVER_HOME}/${NGINX_ALIAS}\n"


# ------------------------------------------------------------------------------
# 설치 여부 확인
if [ -d "${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}" ]; then
    printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| 기존에 설치된 \"${NGINX_ALIAS}\"가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
    printf "\e[00;32m| Enter whether to install \"${NGINX_HOME}\" service?\e[00m"
    read -e -p ' [Y / n] > ' INSTALL_CHECK
    if [ -z "${INSTALL_CHECK}" ]; then
        INSTALL_CHECK="n"
    fi

    if [ "$(uppercase ${INSTALL_CHECK})" != "Y" ]; then
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        printf "\e[00;32m|\e[00m \e[00;31m\"${NGINX_ALIAS}\" 서비스 설치 취소...\e[00m\n"
        printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
        exit 1
    fi
fi


# ------------------------------------------------------------------------------
# OpenSSL 다운로드 확인
#
# verify that the source exists download
if [ ! -f "${SRC_HOME}/${OPENSSL_NAME}" ]; then
    cd ${SRC_HOME}
    printf "\e[00;32m| ${OPENSSL_NAME} download (URL : ${OPENSSL_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${OPENSSL_DOWNLOAD_URL}
    sleep 0.5
fi

# OpenSSL source uncompress
if [ ! -d "${SRC_HOME}/${OPENSSL_HOME}" ]; then
    cd ${SRC_HOME}
    printf "\e[00;32m| \"${OPENSSL_NAME}\" uncompress...\e[00m\n"
    tar xvzf ${OPENSSL_NAME}
    sleep 0.5
fi


# ------------------------------------------------------------------------------
# PCRE  다운로드 확인
#
# verify that the source exists download
if [ ! -f "${SRC_HOME}/${PCRE_NAME}" ]; then
    cd ${SRC_HOME}
    printf "\e[00;32m| \"${PCRE_NAME}\" download (URL : ${PCRE_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${PCRE_DOWNLOAD_URL}
    sleep 0.5
fi

# uncompress source
if [ ! -d "${SRC_HOME}/${PCRE_HOME}" ]; then
    cd ${SRC_HOME}
    printf "\e[00;32m| \"${PCRE_NAME}\" uncompress...\e[00m\n"
    tar xvzf ${PCRE_NAME}
    sleep 0.5
fi


# ------------------------------------------------------------------------------
# Nginx RTMP Module
NGINX_RTMP_MODULE_NAME=${NGINX_RTMP_MODULE_DOWNLOAD_URL##+(*/)}
NGINX_RTMP_MODULE_HOME=${NGINX_RTMP_MODULE_NAME%$GIT_EXTENSION}

# printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
# printf "\e[00;32m| RTMP 모듈을 설치 하시겠습니까?\e[00m\n"
# printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
# printf "\e[00;32m| Enter whether to install the nginx rtmp module?\e[00m"
# read -e -p ' [Y / no(enter]) > ' INSTALL_NGINX_RTMP
# if [ "$(uppercase $INSTALL_NGINX_RTMP)" == "Y" ]; then
#     # cd the compile source directory
#     cd ${SRC_HOME}
#
#     printf "\e[00;32m| \"${NGINX_RTMP_MODULE_HOME}\" install start...\e[00m\n"
#
#     # verify that the source exists download
#     if [ ! -d "${SRC_HOME}/${NGINX_RTMP_MODULE_HOME}" ]; then
#         printf "\e[00;32m| \"${NGINX_RTMP_MODULE_HOME}\" download (URL : ${NGINX_RTMP_MODULE_DOWNLOAD_URL})\e[00m\n"
#         git clone ${NGINX_RTMP_MODULE_DOWNLOAD_URL} ${NGINX_RTMP_MODULE_HOME}
#     fi
#     sleep 0.5
# fi


# ------------------------------------------------------------------------------
# Nginx Headers Modre Module
NGINX_HEADERS_MORE_MODULE_NAME=${NGINX_HEADERS_MORE_MODULE_DOWNLOAD_URL##+(*/)}
NGINX_HEADERS_MORE_MODULE_HOME=${NGINX_HEADERS_MORE_MODULE_NAME%$GIT_EXTENSION}
if [ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HEADERS_MORE_MODULE_HOME}" ]; then
    # cd the compile source directory
    cd ${SRC_HOME}

    printf "\e[00;32m| \"${NGINX_HEADERS_MORE_MODULE_HOME}\" install start...\e[00m\n"

    # verify that the source exists download
    if [ ! -d "${SRC_HOME}/${NGINX_HEADERS_MORE_MODULE_HOME}" ]; then
        printf "\e[00;32m| \"${NGINX_HEADERS_MORE_MODULE_HOME}\" download (URL : ${NGINX_HEADERS_MORE_MODULE_DOWNLOAD_URL})\e[00m\n"
        git clone ${NGINX_HEADERS_MORE_MODULE_DOWNLOAD_URL} ${NGINX_HEADERS_MORE_MODULE_HOME}
    fi
    sleep 0.5
fi


# ------------------------------------------------------------------------------
# delete the previous home
if [ -d "${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}" ]; then
    printf "\e[00;32m| \"${NGINX_HOME}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}
fi
if [ -d "${SERVER_HOME}/${NGINX_ALIAS}" || -L "${SERVER_HOME}/${NGINX_ALIAS}" ]; then
    printf "\e[00;32m| \"${NGINX_ALIAS}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${NGINX_ALIAS}
fi

# cd the compile source directory
cd ${SRC_HOME}

# verify that the source exists download
if [ ! -f "${SRC_HOME}/${NGINX_NAME}" ]; then
    printf "\e[00;32m| \"${NGINX_NAME}\" download (URL : ${NGINX_DOWNLOAD_URL})\e[00m\n"
    curl -L -O ${NGINX_DOWNLOAD_URL}
fi

tar xvzf ${NGINX_NAME}
cd ${SRC_HOME}/${NGINX_HOME}

### Nginx 버전 수정 (보안강화)
if [ "${CHECK_NGINX_VERSION}" == "1.11" ]; then
    sed -i "49s/.*/\/* static u_char ngx_http_server_string[] = \"Server: nginx\" CRLF; *\//g"                          ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "50s/.*/\/* static u_char ngx_http_server_full_string[] = \"Server: nginx\" CRLF; *\//g"                     ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "51s/.*/\/* static u_char ngx_http_server_build_string[] = \"Server: nginx\" CRLF; *\//g"                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "281s/.*/    \/* if (r->headers_out.server == NULL) {;/g"                                                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "291s/.*/    }; *\//g"                                                                                       ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "450s/.*/    \/* if (r->headers_out.server == NULL) {;/g"                                                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "465s/.*/    }; *\//g"                                                                                       ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "22s/.*/\"<hr><center>Error<\/center>\" CRLF/g"                                                              ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_special_response.c
    sed -i "29s/.*/\"<hr><center>Error<\/center>\" CRLF/g"                                                              ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_special_response.c

elif [ "${CHECK_NGINX_VERSION}" == "1.12" ]; then
    sed -i "49s/.*/\/* static u_char ngx_http_server_string[] = \"Server: nginx\" CRLF; *\//g"                          ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "50s/.*/\/* static u_char ngx_http_server_full_string[] = \"Server: nginx\" CRLF; *\//g"                     ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "51s/.*/\/* static u_char ngx_http_server_build_string[] = \"Server: nginx\" CRLF; *\//g"                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "281s/.*/    \/* if (r->headers_out.server == NULL) {;/g"                                                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "291s/.*/    }; *\//g"                                                                                       ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "450s/.*/    \/* if (r->headers_out.server == NULL) {;/g"                                                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "465s/.*/    }; *\//g"                                                                                       ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "22s/.*/\"<hr><center>Error<\/center>\" CRLF/g"                                                              ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_special_response.c
    sed -i "29s/.*/\"<hr><center>Error<\/center>\" CRLF/g"                                                              ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_special_response.c
else
    sed -i "49s/.*/\/* static u_char ngx_http_server_string[] = \"Server: nginx\" CRLF; *\//g"                          ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "50s/.*/\/* static u_char ngx_http_server_full_string[] = \"Server: nginx\" CRLF; *\//g"                     ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "51s/.*/\/* static u_char ngx_http_server_build_string[] = \"Server: nginx\" CRLF; *\//g"                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "282s/.*/    \/* if (r->headers_out.server == NULL) {;/g"                                                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "292s/.*/    }; *\//g"                                                                                       ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "451s/.*/    \/* if (r->headers_out.server == NULL) {;/g"                                                    ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c
    sed -i "466s/.*/    }; *\//g"                                                                                       ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_header_filter_module.c

    sed -i "22s/.*/\"<hr><center>Error<\/center>\" CRLF/g"                                                              ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_special_response.c
    sed -i "29s/.*/\"<hr><center>Error<\/center>\" CRLF/g"                                                              ${SRC_HOME}/${NGINX_HOME}/src/http/ngx_http_special_response.c
fi


# +---------------------+-------------------------------------------------------
# | http_fastcgi_module | FastCGI 프로세스와 연동되는 FastCGI 모듈
# | http_scgi_module    | SCGI 프로토콜 지원 모듈
# | http_uwsgi_module   | uWSGI 프로토콜 지원 모듈
# +---------------------+-------------------------------------------------------
# Config 설정.
INSTALL_CONFIG="--prefix=${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}"
#INSTALL_CONFIG="${INSTALL_CONFIG} --user=${USERNAME}"
#INSTALL_CONFIG="${INSTALL_CONFIG} --group=${GROUPNAME}"
INSTALL_CONFIG="${INSTALL_CONFIG} --sbin-path=${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/sbin/nginx"
INSTALL_CONFIG="${INSTALL_CONFIG} --conf-path=${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/nginx.conf"
INSTALL_CONFIG="${INSTALL_CONFIG} --pid-path=${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/work/nginx.pid"
INSTALL_CONFIG="${INSTALL_CONFIG} --lock-path=${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/work/nginx.lock"
INSTALL_CONFIG="${INSTALL_CONFIG} --modules-path=${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/modules"
INSTALL_CONFIG="${INSTALL_CONFIG} --http-proxy-temp-path=${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/var/lib/nginx/proxy"
INSTALL_CONFIG="${INSTALL_CONFIG} --http-client-body-temp-path=${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/var/lib/nginx/body"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-openssl=${SRC_HOME}/${OPENSSL_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-pcre=${SRC_HOME}/${PCRE_HOME}"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-cc-opt=-Wno-error"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_addition_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_auth_request_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_degradation_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_dav_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_gunzip_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_gzip_static_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_random_index_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_realip_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_slice_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_ssl_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_stub_status_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_sub_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_v2_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-threads"

INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_geoip_module=dynamic"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_image_filter_module=dynamic"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-http_xslt_module=dynamic"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-mail=dynamic"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-mail_ssl_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-stream=dynamic"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-stream_ssl_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --with-stream_ssl_preread_module"

INSTALL_CONFIG="${INSTALL_CONFIG} --without-http_uwsgi_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --without-http_fastcgi_module"
INSTALL_CONFIG="${INSTALL_CONFIG} --without-http_scgi_module"

INSTALL_CONFIG="${INSTALL_CONFIG} --add-module=${SRC_HOME}/${NGINX_HEADERS_MORE_MODULE_HOME}"

# Nginx RTMP Module
if [ "$(uppercase $INSTALL_NGINX_RTMP)" == "Y" ]; then
    INSTALL_CONFIG="${INSTALL_CONFIG} --add-module=${SRC_HOME}/${NGINX_RTMP_MODULE_HOME}"
fi

./configure ${INSTALL_CONFIG} --with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC"
make
make install

# 링크 설정
cd ${SERVER_HOME}
ln -sf ./${PROGRAME_HOME}/${NGINX_HOME} ${NGINX_ALIAS}

# Nginx 디렉토리 생성
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/work
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/var/lib/nginx

# 불필요한 파일 삭제.
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/*.default

# 컴파일 소스 삭제.
if [ -d "${SRC_HOME}/${NGINX_HOME}" ]; then
    rm -rf ${SRC_HOME}/${NGINX_HOME}
fi
if [ -d "${SRC_HOME}/${PCRE_HOME}" ]; then
    rm -rf ${SRC_HOME}/${PCRE_HOME}
fi
if [ -d "${SRC_HOME}/${OPENSSL_HOME}" ]; then
    rm -rf ${SRC_HOME}/${OPENSSL_HOME}
fi


# ------------------------------------------------------------------------------
# nginx.sh
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     _   _____________   ___  __
#    / | / / ____/  _/ | / / |/ /
#   /  |/ / / __ / //  |/ /|   /
#  / /|  / /_/ // // /|  //   |
# /_/ |_/\\____/___/_/ |_//_/|_|
#  :: Nginx ::       (v${NGINX_VERSION})
#
# chkconfig: 2345 85 15
# description: NginX is a World Wide Web server.
#

NGINX_HOME=\"${SERVER_HOME}/${NGINX_ALIAS}\"

NGINX=\"\${NGINX_HOME}/sbin/nginx\"

NGINX_CONFIG=\"\${NGINX_HOME}/conf/nginx.conf\"

NGINX_LOCKFILE=\"\${NGINX_HOME}/work/nginx.lock\"

PROG=\$(basename \${NGINX_HOME})

# ------------------------------------------------------------------------------
# Friendly Logo
logo() {
    printf \"\e[00;32m+---------------------------------------\e[00m\n\"
    printf \"\e[00;32m|     _   _____________   ___  __   \e[00m\\\\n\"
    printf \"\e[00;32m|    / | / / ____/  _/ | / / |/ /   \e[00m\\\\n\"
    printf \"\e[00;32m|   /  |/ / / __ / //  |/ /|   /    \e[00m\\\\n\"
    printf \"\e[00;32m|  / /|  / /_/ // // /|  //   |     \e[00m\\\\n\"
    printf \"\e[00;32m| /_/ |_/\\____/___/_/ |_//_/|_|     \e[00m\\\\n\"
    printf \"\e[00;32m|  :: Nginx ::       (v${NGINX_VERSION})     \e[00m\\\\n\"
    printf \"\e[00;32m+---------------------------------------\e[00m\n\"
    printf \"\e[00;32m| NGINX_HOME:   \${NGINX_HOME}\e[00m\n\"
    printf \"\e[00;32m+---------------------------------------\e[00m\n\"
}

# ------------------------------------------------------------------------------
# Help
usage() {
    # start|stop|reload|restart|status|configtest
    printf \"Script starts and stops a Nginx web instance by invoking the standard \${0} file.\"
    echo
    printf \"Usage: \${0} {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;31mreload\e[00m|\e[00;31mrestart\e[00m|\e[00;32mstatus\e[00m|\e[00;32mconfigtest\e[00m}\"
    echo
    exit 1
}

# ------------------------------------------------------------------------------
# 파라미터가 없는 경우 종료.
if [ -z \"\$1\" ]; then
    logo
    usage
    exit 0
fi
PARAM1=\$1

# ------------------------------------------------------------------------------
# print friendly logo and information useful for debugging
logo

# ------------------------------------------------------------------------------
server_pid() {
    echo \`ps aux | grep -v grep | grep \${NGINX} | grep master | grep root | awk '{ print \$2 }'\`
}

# ------------------------------------------------------------------------------
# Nginx run 사용자 확인.
check_user() {
    if [ \"\$USER\" != \"root\" ]; then
        printf \"\e[00;31mPlease Nginx \\\"\${PARAM1}\\\" with the \\\"root\\\" account.\e[00m\"
        echo
        exit 1
    fi
}

# ------------------------------------------------------------------------------
start() {
    check_user
    pid=\$(server_pid)
    if [ -n \"\${pid}\" ]; then
        printf \"Nginx is already running (PID: \e[00;32m\${pid}\e[00m)\"
        echo
    else
        [ -x \${NGINX} ] || exit 5
        [ -f \${NGINX_CONFIG} ] || exit 6
        printf \"Starting \$PROG: \"
        nohup \${NGINX} -c \${NGINX_CONFIG} >> /dev/null 2>&1 &
        sleep .5

        retval=\$?
        if [ \$retval -eq 0 ]; then
            printf \"                               [    \e[00;32mOK\e[00m    ]\"
            echo
            touch \$NGINX_LOCKFILE
        else
            printf \"                               [  \e[00;31mFAILED\e[00m  ]\"
            echo
        fi
        return \$retval
    fi
}

# ------------------------------------------------------------------------------
stop() {
    check_user
    pid=\$(server_pid)
    if [ -n \"\${pid}\" ]; then
        printf \"Stopping \$PROG: \"
        # killproc \$PROG -QUIT
        \${NGINX} -s stop
        sleep .5

        retval=\$?
        if [ \$retval -eq 0 ]; then
            printf \"                               [    \e[00;32mOK\e[00m    ]\"
            echo
            rm -f \$NGINX_LOCKFILE
        else
            printf \"                               [  \e[00;31mFAILED\e[00m  ]\"
            echo
        fi
        return \$retval
    else
        printf \"Nginx is \e[00;31mnot running\e[00m\"
        echo
    fi
}

# ------------------------------------------------------------------------------
reload() {
    check_user
    pid=\$(server_pid)
    if [ -n \"\${pid}\" ]; then
        configtest || return \$?
        echo -n \$\" Reloading \$PROG: \"
        #killproc \${NGINX} -HUP
        \${NGINX} -s reload
        RETVAL=\$?
        echo
    else
        start
    fi
}

# ------------------------------------------------------------------------------
restart() {
    check_user
    configtest || return \$?
    stop
    sleep 1
    start
}

# ------------------------------------------------------------------------------
status(){
    pid=\$(server_pid)
    if [ -n \"\${pid}\" ]; then
        printf \"Nginx is running with pid: \e[00;32m\${pid}\e[00m\"
    else
        printf \"Nginx is \e[00;31mnot running\e[00m\"
    fi
    echo
}

# ------------------------------------------------------------------------------
configtest() {
    check_user
    \${NGINX} -t -c \${NGINX_CONFIG}
}

# start|stop|reload|restart|status|configtest
case "\$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    reload)
        reload
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    configtest)
        configtest
        ;;
    *)
    usage
    exit 2
esac
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin/nginx.sh


# ------------------------------------------------------------------------------
# start.sh
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     _   _____________   ___  __
#    / | / / ____/  _/ | / / |/ /
#   /  |/ / / __ / //  |/ /|   /
#  / /|  / /_/ // // /|  //   |
# /_/ |_/\\____/___/_/ |_//_/|_|
#  :: Nginx ::       (v${NGINX_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# NGINX_HOME is the location of the configuration files of this instance of nginx
export NGINX_HOME=\`cd \"\${PRGDIR}/..\" >/dev/null; pwd\`

\${NGINX_HOME}/bin/nginx.sh start
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin/start.sh


# ------------------------------------------------------------------------------
# stop.sh
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     _   _____________   ___  __
#    / | / / ____/  _/ | / / |/ /
#   /  |/ / / __ / //  |/ /|   /
#  / /|  / /_/ // // /|  //   |
# /_/ |_/\\____/___/_/ |_//_/|_|
#  :: Nginx ::       (v${NGINX_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# NGINX_HOME is the location of the configuration files of this instance of nginx
export NGINX_HOME=\`cd \"\${PRGDIR}/..\" >/dev/null; pwd\`

\${NGINX_HOME}/bin/nginx.sh stop
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin/stop.sh


# ------------------------------------------------------------------------------
# reload.sh
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     _   _____________   ___  __
#    / | / / ____/  _/ | / / |/ /
#   /  |/ / / __ / //  |/ /|   /
#  / /|  / /_/ // // /|  //   |
# /_/ |_/\\____/___/_/ |_//_/|_|
#  :: Nginx ::       (v${NGINX_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# NGINX_HOME is the location of the configuration files of this instance of nginx
export NGINX_HOME=\`cd \"\${PRGDIR}/..\" >/dev/null; pwd\`

\${NGINX_HOME}/bin/nginx.sh reload
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin/reload.sh


# ------------------------------------------------------------------------------
# restart.sh
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     _   _____________   ___  __
#    / | / / ____/  _/ | / / |/ /
#   /  |/ / / __ / //  |/ /|   /
#  / /|  / /_/ // // /|  //   |
# /_/ |_/\\____/___/_/ |_//_/|_|
#  :: Nginx ::       (v${NGINX_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# NGINX_HOME is the location of the configuration files of this instance of nginx
export NGINX_HOME=\`cd \"\${PRGDIR}/..\" >/dev/null; pwd\`

\${NGINX_HOME}/bin/nginx.sh restart
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin/restart.sh


# ------------------------------------------------------------------------------
# status.sh
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     _   _____________   ___  __
#    / | / / ____/  _/ | / / |/ /
#   /  |/ / / __ / //  |/ /|   /
#  / /|  / /_/ // // /|  //   |
# /_/ |_/\\____/___/_/ |_//_/|_|
#  :: Nginx ::       (v${NGINX_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# NGINX_HOME is the location of the configuration files of this instance of nginx
export NGINX_HOME=\`cd \"\${PRGDIR}/..\" >/dev/null; pwd\`

\${NGINX_HOME}/bin/nginx.sh status
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin/status.sh


# ------------------------------------------------------------------------------
# configtest.sh
echo "#!/bin/sh
# ------------------------------------------------------------------------------
#     _   _____________   ___  __
#    / | / / ____/  _/ | / / |/ /
#   /  |/ / / __ / //  |/ /|   /
#  / /|  / /_/ // // /|  //   |
# /_/ |_/\\____/___/_/ |_//_/|_|
#  :: Nginx ::       (v${NGINX_VERSION})

# resolve links - \$0 may be a softlink
PRG=\"\$0\"
while [ -h \"\$PRG\" ]; do
    ls=\`ls -ld \"\$PRG\"\`
    link=\`expr \"\$ls\" : '.*-> \(.*\)\$'\`
    if expr \"\$link\" : '/.*' > /dev/null; then
        PRG=\"\$link\"
    else
        PRG=\`dirname \"\$PRG\"\`/\"\$link\"
    fi
done

# Get standard environment variables
PRGDIR=\`dirname \"\$PRG\"\`

# NGINX_HOME is the location of the configuration files of this instance of nginx
export NGINX_HOME=\`cd \"\${PRGDIR}/..\" >/dev/null; pwd\`

\${NGINX_HOME}/bin/nginx.sh configtest
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin/configtest.sh


# ------------------------------------------------------------------------------
chmod +x ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/bin/*


# ------------------------------------------------------------------------------
# nginx.conf
if [ "$OS" == "darwin" ]; then
    WORKER_PROCESSES='2'
else
    WORKER_PROCESSES=`grep processor /proc/cpuinfo | wc -l`
fi

echo "user ${USERNAME};

# 프로세스 확인 : grep processor /proc/cpuinfo | wc -l
worker_processes auto;
# worker_processes ${WORKER_PROCESSES};

# CPU의 할당을 명시적으로 사용할 경우 사용.
# worker_cpu_affinity 0001 0010 0100 1000;

# 프로세스당 파일 디스크립터의 상한수로 worker_connections 의 3~4배 정도가 기준이된다.
worker_rlimit_nofile 8192;

# PID 저장 위치 지정
# pid work/nginx.pid;

include modules-enabled/*.conf;

events {
    worker_connections 2048;
}

#stream {
#    log_format main_stream '\$remote_addr '
#                           '\$time_local '
#                           '\$protocol '
#                           '\$status '
#                           '\$bytes_sent '
#                           '\$bytes_received '
#                           '\$session_time '
#                           '\"\$upstream_addr\" '
#                           '\"\$upstream_bytes_sent\" '
#                           '\"\$upstream_bytes_received\" '
#                           '\"\$upstream_connect_time\"';
#
#    # access_log logs/stream-access.log main_stream buffer=32k;
#
#    upstream mysql {
#        server 127.0.0.1:3306;
#    }
#    server {
#        listen 8080;
#        proxy_pass mysql;
#    }
#}

http {
    include mime.types;
    default_type application/octet-stream;

    # log_format main    '\$remote_addr '
    #                    '\$http_NS_CLIENT_IP '
    #                    '\$remote_user '
    #                    '\$time_local '
    #                    '\"\$host\" '
    #                    '\"\$request\" '
    #                    '\$status  '
    #                    '\$body_bytes_sent '
    #                    '\"\$http_referer\" '
    #                    '\"\$http_user_agent\" '
    #                    'TIME:\$request_time '
    #                    'UPTIME:\$upstream_response_time';
    log_format main    '\$remote_addr '
                       '\$remote_user '
                       '\$time_local '
                       '\"\$host\" '
                       '\"\$request\" '
                       '\$status  '
                       '\$body_bytes_sent '
                       '\"\$http_referer\" '
                       '\"\$http_user_agent\" '
                       'TIME:\$request_time '
                       'UPTIME:\$upstream_response_time';

    # access_log logs/access.log  main;

    # error_log logs/error.log;
    # error_log logs/error.log notice;
    # error_log logs/error.log info;
    error_log logs/error.log error;


    server_names_hash_bucket_size 64;

    # 버전 숨기기 활성화
    server_tokens off;

    # ----------------------------------------------------
    # Proxy를 사용할 경우 버퍼의 크기가 너무 작으면 nginx는 임시 파일을 만들어 proxy에서 전달되는 내용을 저장하게 된다.
    # 장비의 메모리 상황등을 참조하여 적당한 수준으로 늘려줘야 한다.
    client_body_buffer_size 8K;
    client_header_buffer_size 1k;

    # 파일 업로드를 1mb 이상할 예정이라면 이 값을 늘려줘야 한다. (기본값 1m)
    client_max_body_size 10m;

    # Request Header Or Cookie Too Large 발생 시 늘려 줄 것
    large_client_header_buffers 4 16k;

    # 지연시간이 길 경우 브라우저의 접속을 끊어서 서버 성능을 높여 주도록 한다.
    client_body_timeout 10;
    client_header_timeout 10;
    send_timeout 10;

    # ----------------------------------------------------
    # 보통은 할 필요 없다.
    # 하면 성능 향상이 있을 수 있지만, 때로는 오히려 저하가 발생할 수도 있다.
    # 따라서 꼭 테스트가 필요하다.
    sendfile on;
    # tcp_nopush on;
    # tcp_nodelay off;

    # ----------------------------------------------------
    # keepalive를 무작정 선택하지 말고 성능 테스트를 해가며 조정해 볼 것.
    keepalive_timeout 30;

    # ----------------------------------------------------
    # Disk IO 병목 - 확인필요
    # open_file_cache max=1000 inactive=20s;
    # open_file_cache_valid 30s;
    # open_file_cache_min_uses 2;
    # open_file_cache_errors on;

    # ----------------------------------------------------
    # Enable Gzip compressed.
    gzip on;
    gzip_disable \"msie6\";
    gzip_disable \"Wget\";

    # Enable compression both for HTTP/1.0 and HTTP/1.1.
    # gzip_http_version 1.1;

    # Compression level (1-9).
    # 5 is a perfect compromise between size and cpu usage, offering about
    # 75% reduction for most ascii files (almost identical to level 9).
    gzip_comp_level 5;

    # Don't compress anything that's already small and unlikely to shrink much
    # if at all (the default is 20 bytes, which is bad as that usually leads to
    # larger files after gzipping).
    gzip_min_length 256;

    # Compress data even for clients that are connecting to us via proxies,
    # identified by the \"Via\" header (required for CloudFront).
    gzip_proxied any;

    # Tell proxies to cache both the gzipped and regular version of a resource
    # whenever the client's Accept-Encoding capabilities header varies;
    # Avoids the issue where a non-gzip capable client (which is extremely rare
    # today) would display gibberish if their proxy gave them the gzipped version.
    gzip_vary on;

    # Compress all output labeled with one of the following MIME-types.
    # text/html is always compressed by HttpGzipModule
    gzip_types application/atom+xml
               application/javascript
               application/json
               application/rss+xml
               application/vnd.ms-fontobject
               application/x-font-ttf
               application/x-web-app-manifest+json
               application/xhtml+xml
               application/xml
               font/opentype
               image/svg+xml
               image/x-icon
               text/css
               text/plain
               text/x-component;

    # ----------------------------------------------------
    proxy_buffering on;
    proxy_buffer_size 4k;
    proxy_buffers 100 8k;
    proxy_connect_timeout 60;
    proxy_send_timeout 60;
    proxy_read_timeout 60;

    # ----------------------------------------------------
    # HTTP/2
    http2_chunk_size 8k;
    http2_body_preread_size 64k;

    # ----------------------------------------------------
    # Headers More Module
    more_clear_headers Server;

    # ----------------------------------------------------
    # Virtual Host Configs
    include conf.d/*.conf;
    include sites-enabled/*;
}
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/nginx.conf


# ------------------------------------------------------------------------------
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/conf.d
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/modules-available
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/modules-enabled
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/sites-available
mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/sites-enabled


# ------------------------------------------------------------------------------
echo "load_module modules/ngx_http_geoip_module.so;"        > ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-http-geoip.conf
echo "load_module modules/ngx_http_image_filter_module.so;" > ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-http-image-filter.conf
echo "load_module modules/ngx_http_xslt_filter_module.so;"  > ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-http-xslt-filter.conf
echo "load_module modules/ngx_mail_module.so;"              > ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-mail.conf
echo "load_module modules/ngx_stream_module.so;"            > ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-stream.conf

ln -sf ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-http-geoip.conf          ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-enabled/50-mod-http-geoip.conf
ln -sf ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-http-image-filter.conf   ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-enabled/50-mod-http-image-filter.conf
ln -sf ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-http-xslt-filter.conf    ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-enabled/50-mod-http-xslt-filter.conf
ln -sf ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-mail.conf                ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-enabled/50-mod-mail.conf
ln -sf ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-available/50-mod-stream.conf              ${SERVER_HOME}/${NGINX_ALIAS}/conf/modules-enabled/50-mod-stream.conf


# ------------------------------------------------------------------------------
echo "server {
    listen 80;
    server_name localhost;

    # charset koi8-r;

    # access_log logs/host.access.log main;

    location / {
        root html;
        index index.html index.htm;
    }

    # location /document {
    #     alias /data/document;
    #     allow all;
    #     autoindex on;
    #     autoindex_exact_size off;
    #     autoindex_localtime on;
    # }

    # # redirect server error pages to the static page
    # #
    # error_page 403 /error/nginx/ec/403.html;
    # error_page 404 /error/nginx/ec/404.html;
    # error_page 500 /error/nginx/ec/404.html;
    # error_page 502 503 504 /error/nginx/ec/502.html;

    # ## Locations -> Fallback
    # location = /error/nginx/403.html {
    #     root html;
    # }
    # location = /error/nginx/404.html {
    #     root html;
    # }
    # location = /error/nginx/500.html {
    #     root html;
    # }
    # location = /error/nginx/502.html {
    #     root html;
    # }


    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    # location ~ \.php\$ {
    #     proxy_pass http://127.0.0.1;
    # }

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    # location ~ \.php\$ {
    #     root html;
    #     fastcgi_pass 127.0.0.1:9000;
    #     fastcgi_index index.php;
    #     fastcgi_param SCRIPT_FILENAME  /scripts\$fastcgi_script_name;
    #     include fastcgi_params;
    # }

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    # location ~ /\.ht {
    #     deny all;
    # }
}


# ----------------------------------------------------
# another virtual host using mix of IP-, name-, and port-based configuration
#
#server {
#    listen 8000;
#    listen somename:8080;
#    server_name somename  alias  another.alias;
#
#    location / {
#        root html;
#        index index.html index.htm;
#    }
#}


# ----------------------------------------------------
# HTTPS server
#server {
#    listen 443 ssl http2;
#    server_name localhost;
#
#    ssl_certificate ssl/server.crt;
#    ssl_certificate_key ssl/server.key;
#
#    ssl_session_cache shared:SSL:1m;
#    ssl_session_timeout 5m;
#
#    # ssl_ciphers HIGH:!aNULL:!MD5;
#    # ssl_prefer_server_ciphers on;
#
#    location / {
#        root html;
#        index index.html index.htm;
#    }
#}
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/sites-available/default

ln -sf ${SERVER_HOME}/${NGINX_ALIAS}/conf/sites-available/default ${SERVER_HOME}/${NGINX_ALIAS}/conf/sites-enabled/default


# ------------------------------------------------------------------------------
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| 사설 인증키를 생성하려면 도메인을 입력주세요.\e[00m\n"
printf "\e[00;32m+---------------------------------------------------------------------------------\e[00m\n"
printf "Enter whether to ssl setting? [\e[00;32mY\e[00m / \e[00;31mn(enter)\e[00m] (default. n)"
read -e -p ' > ' CHECK_SSL
if [ ! -z ${CHECK_SSL}  ] && [ "$(uppercase ${CHECK_SSL})" == "Y" ]; then
    # 사설 인증키 생성
    mkdir ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl

    if [[ -z ${DOMAIN_NAME} ]]; then
        printf "Enter your domain (ex. scala.or.kr)"
        read -e -p " > " DOMAIN
        while [[ -z ${DOMAIN_NAME} ]]; do
            printf "Enter your domain (ex. scala.or.kr)"
            read -e -p " > " DOMAIN
        done
        echo
    fi

    echo "[v3_extensions]
# Extensions to add to a certificate request
basicConstraints                = CA:FALSE
authorityKeyIdentifier          = keyid,issuer
subjectKeyIdentifier            = hash
keyUsage                        = nonRepudiation, digitalSignature, keyEncipherment

## SSL 용 확장키 필드
extendedKeyUsage                = serverAuth,clientAuth
subjectAltName                  = @subject_alternative_name

[subject_alternative_name]
# Subject AltName의 DNSName field에 SSL Host 의 도메인 이름을 적어준다.
# 멀티 도메인일 경우 *.lesstif.com 처럼 쓸 수 있다.
DNS.1                           = *.${DOMAIN_NAME}

[distinguished_name]
countryName                     = Seoul
countryName_default             = KR
countryName_min                 = 2
countryName_max                 = 2

# 회사명 입력
organizationName                = KTH
organizationName_default        = KTH Inc.

# 부서 입력
#organizationalUnitName         = Organizational Unit Name (eg, section)
#organizationalUnitName_default = lesstif SSL Project

# SSL 서비스할 domain 명 입력
commonName                      = ${DOMAIN_NAME}
commonName_default              = admin@${DOMAIN_NAME}
commonName_max                  = 64

[req]
# 화면으로 입력 받지 않도록 설정.
prompt                          = no
default_bits                    = 2048
default_md                      = sha1
default_keyfile                 = lesstif-rootca.key
distinguished_name              = distinguished_name
x509_extensions                 = v3_extensions
# 인증서 요청시에도 extension 이 들어가면 authorityKeyIdentifier 를 찾지 못해 에러가 나므로 막아둔다.
#req_extensions                  = v3_extensions
" > ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.conf

    #${SERVER_HOME}/${OPENSSL_ALIAS}/bin/openssl genpkey                                                                 \
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096                                                        \
                    -out ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.key

    chmod 400 ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.key

    #${SERVER_HOME}/${OPENSSL_ALIAS}/bin/openssl req                                                                     \
    openssl req -new -sha256                                                                                            \
                -key    ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.key                            \
                -out    ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.csr                            \
                -config ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.conf

    #${SERVER_HOME}/${OPENSSL_ALIAS}/bin/openssl x509 -req                                                               \
    openssl x509 -req -days 3650 -extensions v3_extensions                                                              \
                 -in      ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.csr                          \
                 -signkey ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.key                          \
                 -out     ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.crt                          \
                 -extfile ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.conf

    # 인증서 확인
    openssl x509 -text -in ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.crt

    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${NGINX_HOME}/conf/ssl/${DOMAIN_NAME}.conf
fi


# ------------------------------------------------------------------------------
printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"
printf "\e[00;32m| \"${NGINX_ALIAS}\" install success...\e[00m\n"
printf "\e[00;32m+-------------------------------------------------------------------------\e[00m\n"

