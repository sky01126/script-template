#!/bin/bash

# 참조 : http://www.linuxfromscratch.org/blfs/view/svn/multimedia/ffmpeg.html

# 멀티 쉘 실행 : bash <(curl -f -L -sS http://shell.pe.kr/document/install/ffmpeg_4.1_install.sh)

########## FFMpeg 설치 전에 설치 될 패키지 ##########
## Cent OS
# 개발 : yum install -y cmake bison ncurses-devel xz hg patch lbzip2
#
## CentOS 7
# yum install -y fribidi-devel fontconfig-devel patch lbzip2
#
## MacOS
# brew install mercurial cmake bison autoconf automake libtool xz pkg-config

# Exit on error
set -e

# shopt은 shell option의 약자로 유틸이다.
# 사용 하는 extglob 쉘 옵션 shopt 내장 명령을 사용 하 여 같은 확장된 패턴 일치 연산자를 사용
shopt -s extglob

## OS를 확인한다.
OS='unknown'
if [ "$(uname)" == "Darwin" ]; then
    OS="darwin"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
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
# 소스 디렉토리와 서버 디렉토리 설정.
SRC_HOME=${HOME}/src
if [ ! -d "${SRC_HOME}" ]; then
    printf "\n\e[00;32m| create ${SRC_HOME} dir...\e[00m\n"
    mkdir -p ${SRC_HOME}
fi


# ----------------------------------------------------------------------------------------------------------------------
# Server Home 경로 설정.
# export SERVER_HOME=/home/server
if [[ -z ${SERVER_HOME} ]]; then
    read -e -p 'Enter the server home path> ' SERVER_HOME
    while [[ -z ${SERVER_HOME} ]]; do
        read -e -p 'Enter the tomcat home path> ' SERVER_HOME
    done
    echo
fi
export SERVER_HOME=${SERVER_HOME}


# ----------------------------------------------------------------------------------------------------------------------
# Programe Home 경로 설정.
export PROGRAME_HOME='opt/local'
if [ ! -d "${SERVER_HOME}/${PROGRAME_HOME}" ]; then
    echo " | CREATE - ${SERVER_HOME}/${PROGRAME_HOME}"
    mkdir -p ${SERVER_HOME}/${PROGRAME_HOME}
fi


# ----------------------------------------------------------------------------------------------------------------------
# File Extension
EXTENSION='.tar.gz'
GIT_EXTENSION='.git'
BZ2_EXTENSION='.tar.bz2'
XZ_EXTENSION='.tar.xz'


# ----------------------------------------------------------------------------------------------------------------------
# FreeType2 (항상 제일 먼저 설치해야한다.)
FREETYPE2_DOWNLOAD_URL='http://downloads.sourceforge.net/freetype/freetype-2.10.1.tar.gz'

# FriBidi
FRIBIDI_DOWNLOAD_URL='https://github.com/fribidi/fribidi/releases/download/v1.0.5/fribidi-1.0.5.tar.bz2'

# python2
PYTHON2_DOWNLOAD_URL='https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tar.xz'

# Gperf
GPERF_DOWNLOAD_URL='http://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz'

# libass
LIBASS_DOWNLOAD_URL='https://github.com/libass/libass/releases/download/0.14.0/libass-0.14.0.tar.gz'

# YASM
YASM_DOWNLOAD_URL='http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz'

# NASM
NASM_DOWNLOAD_URL='https://www.nasm.us/pub/nasm/releasebuilds/2.14.01/nasm-2.14.01.tar.gz'

# libx264
X264_DOWNLOAD_URL='https://download.videolan.org/x264/snapshots/x264-snapshot-20190701-2245-stable.tar.bz2'

# libx265
X265_DOWNLOAD_URL='https://bitbucket.org/multicoreware/x265/downloads/x265_3.0.tar.gz'

# fdk-aac
FDKAAC_DOWNLOAD_URL='https://downloads.sourceforge.net/opencore-amr/fdk-aac-2.0.0.tar.gz'

# libmp3lame
LAME_DOWNLOAD_URL='https://downloads.sourceforge.net/lame/lame-3.100.tar.gz'

# Opus
OPUS_DOWNLOAD_URL='http://downloads.xiph.org/releases/opus/opus-1.3.1.tar.gz'

# libogg
LIBOGG_DOWNLOAD_URL='http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz'

# libvorbis
LIBVORBIS_DOWNLOAD_URL='http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.gz'

# LibTIFF
LIBTIFF_DOWNLOAD_URL='http://download.osgeo.org/libtiff/tiff-4.0.9.tar.gz'

# libvpx
LIBVPX_DOWNLOAD_URL='https://github.com/webmproject/libvpx/archive/v1.8.0/libvpx-1.8.0.tar.gz'

# lcms2
LCMS2_DOWNLOAD_URL='http://downloads.sourceforge.net/lcms/lcms2-2.9.tar.gz'

# libpng
LIBPNG_DOWNLOAD_URL='http://downloads.sourceforge.net/libpng/libpng-1.6.37.tar.gz'

LIBPNG_APNG_EXTENSION='-apng.patch.gz'
LIBPNG_APNG_DOWNLOAD_URL='https://downloads.sourceforge.net/sourceforge/libpng-apng/libpng-1.6.37-apng.patch.gz'

# openjpeg
OPENJPEG_DOWNLOAD_URL='https://github.com/uclouvain/openjpeg/archive/v2.3.1/openjpeg-2.3.1.tar.gz'

# libtheora
LIBTHEORA_DOWNLOAD_URL='https://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz'

# FFMpeg
FFMPEG_DOWNLOAD_URL='http://ffmpeg.org/releases/ffmpeg-4.1.3.tar.gz'


# ----------------------------------------------------------------------------------------------------------------------
# FFmpeg Home
FFMPEG_NAME=${FFMPEG_DOWNLOAD_URL##+(*/)}
#FFMPEG_HOME=${FFMPEG_NAME%$GIT_EXTENSION}
FFMPEG_HOME=${FFMPEG_NAME%$EXTENSION}
FFMPEG_ALIAS='ffmpeg'

# FFMPEG 빌드 경로 설정
FFMPEG_BUILD_PATH="$HOME/ffmpeg_build"

## 환경설정.
PATH=${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}/bin:${FFMPEG_BUILD_PATH}/bin:${PATH}


# ----------------------------------------------------------------------------------------------------------------------
# 설치 여부 확인
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}" ]]; then
    echo
    printf "\e[00;32m기존에 설치된 FFmpeg가 있습니다. 삭제하고 다시 설치하려면 \"Y\"를 입력하세요.\e[00m\n"
    echo
    read -e -p "Enter whether to reinstall the FFMpeg? [Y / no(enter]) > " INSTALL_FFMPEG
    if [[ "$(uppercase $INSTALL_FFMPEG)" != "Y" ]]; then
        printf "\n\e[00;31m \"${FFMPEG_HOME}\" 서비스 생성 취소...\e[00m\n\n"
        exit 1
    fi
fi


# ----------------------------------------------------------------------------------------------------------------------
# FFmpeg 설치
# delete the previous home
if [[ -d "${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}" ]]; then
    printf "\e[00;32m| \"${FFMPEG_HOME}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}
fi
if [[ -d "${SERVER_HOME}/${FFMPEG_ALIAS}" || -L "${SERVER_HOME}/${FFMPEG_ALIAS}" ]]; then
    printf "\e[00;32m| \"${FFMPEG_ALIAS}\" delete...\e[00m\n"
    rm -rf ${SERVER_HOME}/${FFMPEG_ALIAS}
fi


# ----------------------------------------------------------------------------------------------------------------------
if [[ "${OS}" == "linux" ]]; then
    # ------------------------------------------------------------------------------------------------------------------
    # FreeType2
    if [[ ! -f "${FFMPEG_BUILD_PATH}/build/freetype2" ]]; then
        FREETYPE2_NAME=${FREETYPE2_DOWNLOAD_URL##+(*/)}
        FREETYPE2_HOME=${FREETYPE2_NAME%$EXTENSION}

        printf "\n\e[00;32m| ${FREETYPE2_HOME}\e[00m install start...\n"

        cd ${SRC_HOME}

        # verify that the source exists download
        if [[ ! -f "${SRC_HOME}/${FREETYPE2_NAME}" ]]; then
            printf "\n\e[00;32m| ${FREETYPE2_NAME}\e[00m download...\n"
            curl -L -O ${FREETYPE2_DOWNLOAD_URL}
        fi

        # 이전 소스 디렉토리 삭제.
        if [[ -d "${SRC_HOME}/${FREETYPE2_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${FREETYPE2_HOME}
        fi

        tar xvzf ${FREETYPE2_NAME}
        cd ${SRC_HOME}/${FREETYPE2_HOME}

        sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg                                                              &&
        sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" -i include/freetype/config/ftoption.h                               &&
        ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                       \
                    --enable-static                                                                                     \
                    --disable-shared
        make
        make install

        mkdir -p ${FFMPEG_BUILD_PATH}/build
        touch ${FFMPEG_BUILD_PATH}/build/freetype2

        # 컴파일된 소스 삭제
        if [[ -d "${SRC_HOME}/${FREETYPE2_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${FREETYPE2_HOME}
        fi

        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "| \e[00;32m${FREETYPE2_NAME}\e[00m install success...\n"
        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "\n"
        sleep 0.5
    fi


    # -------------------------------------------------------------------------------------------------------------------
    # FriBidi
    if [[ ! -f "${FFMPEG_BUILD_PATH}/build/fribidi" ]]; then
        FRIBIDI_NAME=${FRIBIDI_DOWNLOAD_URL##+(*/)}
        FRIBIDI_HOME=${FRIBIDI_NAME%$BZ2_EXTENSION}

        printf "\n\e[00;32m| ${FRIBIDI_HOME}\e[00m install start...\n"

        cd ${SRC_HOME}

        # verify that the source exists download
        if [[ ! -f "${SRC_HOME}/${FRIBIDI_NAME}" ]]; then
            printf "\n\e[00;32m| ${FRIBIDI_NAME}\e[00m download...\n"
            curl -L -O ${FRIBIDI_DOWNLOAD_URL}
        fi

        # 이전 소스 디렉토리 삭제.
        if [[ -d "${SRC_HOME}/${FRIBIDI_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${FRIBIDI_HOME}
        fi

        tar xvf ${FRIBIDI_NAME}
        cd ${SRC_HOME}/${FRIBIDI_HOME}

        ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                       \
                    --enable-static                                                                                     \
                    --disable-shared                                                                                    \
                    --disable-docs
        make
        make install

        mkdir -p ${FFMPEG_BUILD_PATH}/build
        touch ${FFMPEG_BUILD_PATH}/build/fribidi

        # 컴파일된 소스 삭제
        if [[ -d "${SRC_HOME}/${FRIBIDI_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${FRIBIDI_HOME}
        fi

        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "| \e[00;32m${FRIBIDI_NAME}\e[00m install success...\n"
        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "\n"
        sleep 0.5
    fi


    # -------------------------------------------------------------------------------------------------------------------
    # python2
    PYTHON2_NAME=${PYTHON2_DOWNLOAD_URL##+(*/)}
    PYTHON2_HOME=${PYTHON2_NAME%$XZ_EXTENSION}
    PYTHON2_ALIAS='python'

    # Python2 설치 여부를 확인한다.
    if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${PYTHON2_HOME}" ]]; then
        printf "\n\e[00;32m| ${PYTHON2_HOME}\e[00m install start...\n"

        cd ${SRC_HOME}
        rm -rf ${SERVER_HOME}/${PYTHON2_ALIAS}*

        # verify that the source exists download
        if [[ ! -f "${SRC_HOME}/${PYTHON2_NAME}" ]]; then
            printf "\n\e[00;32m| ${PYTHON2_NAME}\e[00m download...\n"
            curl -L -O ${PYTHON2_DOWNLOAD_URL}
        fi

        # 이전 소스 디렉토리 삭제.
        if [[ -d "${SRC_HOME}/${PYTHON2_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${PYTHON2_HOME}
        fi

        tar xJvf ${PYTHON2_NAME}
        cd ${SRC_HOME}/${PYTHON2_HOME}

        ./configure --prefix=${SERVER_HOME}/${PROGRAME_HOME}/${PYTHON2_HOME}                                            \
                    --enable-shared
        make
        # make test
        make install
        sleep 0.5

        cd ${SERVER_HOME}
        ln -s ./${PROGRAME_HOME}/${PYTHON2_HOME} ${PYTHON2_ALIAS}

        # 컴파일된 소스 삭제
        if [[ -d "${SRC_HOME}/${PYTHON2_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${PYTHON2_HOME}
        fi

        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "| \e[00;32m${PYTHON2_NAME}\e[00m install success...\n"
        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "\n"
        sleep 0.5

        echo "# Python2 Home
export PYTHON_HOME='${SERVER_HOME}/${PYTHON2_ALIAS}'
export PATH=\$PYTHON_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$PYTHON_HOME/lib:\$LD_LIBRARY_PATH
" | tee -a ${HOME}/.bashrc
    fi
    PYTHON_HOME=${SERVER_HOME}/${PROGRAME_HOME}/${PYTHON2_HOME}
    PATH=${PYTHON_HOME}/bin:$PATH


    # -------------------------------------------------------------------------------------------------------------------
    # Gperf
    GPERF_NAME=${GPERF_DOWNLOAD_URL##+(*/)}
    GPERF_HOME=${GPERF_NAME%$EXTENSION}
    GPERF_ALIAS='gperf'

    # Gperf 설치 여부를 확인한다.
    if [[ ! -d "${SERVER_HOME}/${PROGRAME_HOME}/${GPERF_HOME}" ]]; then
        printf "\n\e[00;32m| ${GPERF_HOME}\e[00m install start...\n"

        cd ${SRC_HOME}
        rm -rf ${SERVER_HOME}/${GPERF_ALIAS}*

        # verify that the source exists download
        if [[ ! -f "${SRC_HOME}/${GPERF_NAME}" ]]; then
            printf "\n\e[00;32m| ${GPERF_NAME}\e[00m download...\n"
            curl -L -O ${GPERF_DOWNLOAD_URL}
        fi

        # 이전 소스 디렉토리 삭제.
        if [[ -d "${SRC_HOME}/${GPERF_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${GPERF_HOME}
        fi

        tar xvzf ${GPERF_NAME}
        cd ${SRC_HOME}/${GPERF_HOME}

        ./configure --prefix=${SERVER_HOME}/${PROGRAME_HOME}/${GPERF_HOME}                                              \
                    --enable-shared
        make
        make install
        sleep 0.5

        cd ${SERVER_HOME}
        ln -s ./${PROGRAME_HOME}/${GPERF_HOME} ${GPERF_ALIAS}

        # 컴파일된 소스 삭제
        if [[ -d "${SRC_HOME}/${GPERF_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${GPERF_HOME}
        fi

        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "| \e[00;32m${GPERF_NAME}\e[00m install success...\n"
        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "\n"
        sleep 0.5

        echo "# Gperf Home
export GPERF_HOME='${SERVER_HOME}/${GPERF_ALIAS}'
export PATH=\$GPERF_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$GPERF_HOME/lib:\$LD_LIBRARY_PATH
" | tee -a ${HOME}/.bashrc
    fi
    GPERF_HOME=${SERVER_HOME}/${PROGRAME_HOME}/${GPERF_HOME}
    PATH=${GPERF_HOME}/bin:$PATH


    # -------------------------------------------------------------------------------------------------------------------
    # libass
    if [[ ! -f "${FFMPEG_BUILD_PATH}/build/libass" ]]; then
        LIBASS_NAME=${LIBASS_DOWNLOAD_URL##+(*/)}
        LIBASS_HOME=${LIBASS_NAME%$EXTENSION}

        printf "\n\e[00;32m| ${LIBASS_HOME}\e[00m install start...\n"

        cd ${SRC_HOME}

        # verify that the source exists download
        if [[ ! -f "${SRC_HOME}/${LIBASS_NAME}" ]]; then
            printf "\n\e[00;32m| ${LIBASS_NAME}\e[00m download...\n"
            curl -L -O ${LIBASS_DOWNLOAD_URL}
        fi

        FRIBIDI_LIBS="${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}/lib"
        FONTCONFIG_LIBS="${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}/lib"

        tar xvzf ${LIBASS_NAME}
        cd ${SRC_HOME}/${LIBASS_HOME}

        ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                       \
                    --enable-static                                                                                     \
                    --disable-enca                                                                                      \
                    --disable-shared                                                                                    \
                    --disable-fontconfig                                                                                \
                    --disable-require-system-font-provider                                                              \
                    FRIBIDI_CFLAGS="-I${FFMPEG_BUILD_PATH}/include/fribidi"                                             \
                    FRIBIDI_LIBS="${FFMPEG_BUILD_PATH}/lib/libfribidi.a"

        make
        make install

        mkdir -p ${FFMPEG_BUILD_PATH}/build
        touch ${FFMPEG_BUILD_PATH}/build/libass

        # 컴파일된 소스 삭제
        if [[ -d "${SRC_HOME}/${LIBASS_HOME}" ]]; then
            rm -rf ${SRC_HOME}/${LIBASS_HOME}
        fi

        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "| \e[00;32m${LIBASS_NAME}\e[00m install success...\n"
        printf "\e[00;32m----------------------------------------------\e[00m\n"
        printf "\n"
        sleep 0.5
    fi
fi


# -------------------------------------------------------------------------------------------------------------------
# YASM
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/yasm" ]]; then
    YASM_NAME=${YASM_DOWNLOAD_URL##+(*/)}
    YASM_HOME=${YASM_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${YASM_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${YASM_NAME}" ]]; then
        printf "\n\e[00;32m| ${YASM_NAME} download...\e[00m\n"
        curl -L -O ${YASM_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${YASM_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${YASM_HOME}
    fi

    tar xzvf ${YASM_NAME}
    cd ${SRC_HOME}/${YASM_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/yasm

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${YASM_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${YASM_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${YASM_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# NASM
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/nasm" ]]; then
    NASM_NAME=${NASM_DOWNLOAD_URL##+(*/)}
    NASM_HOME=${NASM_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${NASM_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${NASM_NAME}" ]]; then
        printf "\n\e[00;32m| ${NASM_NAME} download...\e[00m\n"
        curl -L -O ${NASM_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${NASM_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${NASM_HOME}
    fi

    tar xvzf ${NASM_NAME}
    cd ${SRC_HOME}/${NASM_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/nasm

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${NASM_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${NASM_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${NASM_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# X264
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/x264" ]]; then
    X264_NAME=${X264_DOWNLOAD_URL##+(*/)}
    X264_HOME=${X264_NAME%$BZ2_EXTENSION}

    printf "\n\e[00;32m| ${X264_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${X264_NAME}" ]]; then
        printf "\n\e[00;32m| ${X264_NAME}\e[00m download...\n"
        curl -L -O ${X264_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${X264_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${X264_HOME}
    fi

    tar xvf ${X264_NAME}
    cd ${SRC_HOME}/${X264_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --enable-static                                                                                         \
                --disable-shared                                                                                        \
                --disable-cli
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/x264

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${X264_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${X264_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${X264_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# X265
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/x265" ]]; then
    X265_NAME=${X265_DOWNLOAD_URL##+(*/)}
    X265_HOME=${X265_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${X265_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${X265_NAME}" ]]; then
        printf "\n\e[00;32m| ${X265_NAME}\e[00m download...\n"
        curl -L -O ${X265_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${X265_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${X265_HOME}
    fi

    tar xvzf ${X265_NAME}
    cd ${SRC_HOME}/${X265_HOME}

    mkdir bld && cd bld
    cmake -DCMAKE_INSTALL_PREFIX=${FFMPEG_BUILD_PATH}                                                                   \
          -DENABLE_SHARED:bool=off                                                                                      \
          ../source
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/x265

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${X265_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${X265_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${X265_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# FDK AAC
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/fdk-aac" ]]; then
    FDKAAC_NAME=${FDKAAC_DOWNLOAD_URL##+(*/)}
    FDKAAC_HOME=${FDKAAC_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${FDKAAC_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${FDKAAC_NAME}" ]]; then
        printf "\n\e[00;32m| ${FDKAAC_NAME}\e[00m download...\n"
        curl -L -O ${FDKAAC_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${FDKAAC_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${FDKAAC_HOME}
    fi

    tar xzvf ${FDKAAC_NAME}
    cd ${SRC_HOME}/${FDKAAC_HOME}

    autoreconf -fiv
    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --disable-shared
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/fdk-aac

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${FDKAAC_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${FDKAAC_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${FDKAAC_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# lame
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/lame" ]]; then
    LAME_NAME=${LAME_DOWNLOAD_URL##+(*/)}
    LAME_HOME=${LAME_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${LAME_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${LAME_NAME}" ]]; then
        printf "\n\e[00;32m| ${LAME_NAME}\e[00m download...\n"
        curl -L -O ${LAME_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${LAME_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LAME_HOME}
    fi

    tar xzvf ${LAME_NAME}
    cd ${SRC_HOME}/${LAME_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --enable-nasm                                                                                           \
                --disable-shared
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/lame

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${LAME_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LAME_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${LAME_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# Opus
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/opus" ]]; then
    OPUS_NAME=${OPUS_DOWNLOAD_URL##+(*/)}
    OPUS_HOME=${OPUS_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${OPUS_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${OPUS_NAME}" ]]; then
        printf "\n\e[00;32m| ${OPUS_NAME}\e[00m download...\n"
        curl -L -O ${OPUS_DOWNLOAD_URL}
    fi

    echo ${SRC_HOME}/${OPUS_HOME}

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${OPUS_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${OPUS_HOME}
    fi

    tar xvzf ${OPUS_NAME}
    cd ${SRC_HOME}/${OPUS_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --enable-static                                                                                         \
                --disable-shared                                                                                        \
                --docdir=${FFMPEG_BUILD_PATH}/share/doc/opus-1.2.1
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/opus

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${OPUS_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${OPUS_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${OPUS_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# libogg
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/libogg" ]]; then
    LIBOGG_NAME=${LIBOGG_DOWNLOAD_URL##+(*/)}
    LIBOGG_HOME=${LIBOGG_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${LIBOGG_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${LIBOGG_NAME}" ]]; then
        printf "\n\e[00;32m| ${LIBOGG_NAME}\e[00m download...\n"
        curl -L -O ${LIBOGG_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${LIBOGG_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBOGG_HOME}
    fi

    tar xzvf ${LIBOGG_NAME}
    cd ${SRC_HOME}/${LIBOGG_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --disable-shared
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/libogg

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${LIBOGG_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBOGG_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${LIBOGG_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# libvorbis
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/libvorbis" ]]; then
    LIBVORBIS_NAME=${LIBVORBIS_DOWNLOAD_URL##+(*/)}
    LIBVORBIS_HOME=${LIBVORBIS_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${LIBVORBIS_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${LIBVORBIS_NAME}" ]]; then
        printf "\n\e[00;32m| ${LIBVORBIS_NAME}\e[00m download...\n"
        curl -L -O ${LIBVORBIS_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${LIBVORBIS_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBVORBIS_HOME}
    fi

    tar xvzf ${LIBVORBIS_NAME}
    cd ${SRC_HOME}/${LIBVORBIS_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --disable-oggtest                                                                                       \
                --disable-shared
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/libvorbis

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${LIBVORBIS_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBVORBIS_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${LIBVORBIS_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# LibTIFF
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/libtiff" ]]; then
    LIBTIFF_NAME=${LIBTIFF_DOWNLOAD_URL##+(*/)}
    LIBTIFF_HOME=${LIBTIFF_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${LIBTIFF_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${LIBTIFF_NAME}" ]]; then
        printf "\n\e[00;32m| ${LIBTIFF_NAME}\e[00m download...\n"
        curl -L -O ${LIBTIFF_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${LIBTIFF_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBTIFF_HOME}
    fi

    tar xzvf ${LIBTIFF_NAME}
    cd ${SRC_HOME}/${LIBTIFF_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --disable-shared
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/libtiff

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${LIBTIFF_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBTIFF_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${LIBTIFF_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# libvpx
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/libvpx" ]]; then
    LIBVPX_NAME=${LIBVPX_DOWNLOAD_URL##+(*/)}
    LIBVPX_HOME=${LIBVPX_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${LIBVPX_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -d "${SRC_HOME}/${LIBVPX_HOME}" ]]; then
        printf "\n\e[00;32m| ${LIBVPX_HOME}\e[00m download...\n"
        curl -L -O ${LIBVPX_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${LIBVPX_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBVPX_HOME}
    fi

    tar xvzf ${LIBVPX_NAME}
    cd ${SRC_HOME}/${LIBVPX_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --disable-shared                                                                                        \
                --disable-examples                                                                                      \
                --disable-unit-tests
    make
    make install
    make distclean

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/libvpx

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${LIBVPX_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBVPX_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${LIBVPX_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# lcms2
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/lcms2" ]]; then
    LCMS2_NAME=${LCMS2_DOWNLOAD_URL##+(*/)}
    LCMS2_HOME=${LCMS2_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${LCMS2_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${LCMS2_NAME}" ]]; then
        printf "\n\e[00;32m| ${LCMS2_NAME}\e[00m download...\n"
        curl -L -O ${LCMS2_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${LCMS2_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LCMS2_HOME}
    fi

    tar xzvf ${LCMS2_NAME}
    cd ${SRC_HOME}/${LCMS2_HOME}

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --disable-shared
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/lcms2

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${LCMS2_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LCMS2_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${LCMS2_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# libpng
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/libpng" ]]; then
    LIBPNG_NAME=${LIBPNG_DOWNLOAD_URL##+(*/)}
    LIBPNG_HOME=${LIBPNG_NAME%$EXTENSION}
    LIBPNG_APNG_NAME=${LIBPNG_APNG_DOWNLOAD_URL##+(*/)}

    printf "\n\e[00;32m| ${LIBPNG_HOME}\e[00m install start...\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${LIBPNG_NAME}" ]]; then
        printf "\n\e[00;32m| ${LIBPNG_NAME}\e[00m download...\n"
        curl -L -O ${LIBPNG_DOWNLOAD_URL}
    fi

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${LIBPNG_APNG_NAME}" ]]; then
        printf "\n\e[00;32m| ${LIBPNG_APNG_NAME}\e[00m download...\n"
        curl -L -O ${LIBPNG_APNG_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${LIBPNG_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBPNG_HOME}
    fi

    tar xvzf ${LIBPNG_NAME}
    cd ${SRC_HOME}/${LIBPNG_HOME}

    # gzip -cd ${LIBPNG_APNG_NAME}
    # gzip -cd ../${LIBPNG_APNG_NAME} | patch -p0

    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --disable-shared
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/share/doc/libpng
    cp -v README libpng-manual.txt ${FFMPEG_BUILD_PATH}/share/doc/libpng

    mkdir -p ${FFMPEG_BUILD_PATH}/build
    touch ${FFMPEG_BUILD_PATH}/build/libpng

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${LIBPNG_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBPNG_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "| \e[00;32m${LIBPNG_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


## -------------------------------------------------------------------------------------------------------------------
## openjpeg
#if [[ ! -f "${FFMPEG_BUILD_PATH}/build/openjpeg" ]]; then
#    OPENJPEG_NAME=${OPENJPEG_DOWNLOAD_URL##+(*/)}
#    OPENJPEG_HOME=${OPENJPEG_NAME%$EXTENSION}
#
#    printf "\n\e[00;32m| ${OPENJPEG_HOME} install start...\e[00m\n"
#
#    cd ${SRC_HOME}
#
#    # verify that the source exists download
#    if [[ ! -f "${SRC_HOME}/${OPENJPEG_NAME}" ]]; then
#        printf "\n\e[00;32m| ${OPENJPEG_NAME}\e[00m download...\n"
#        curl -L -O ${OPENJPEG_DOWNLOAD_URL}
#    fi
#
#    # 이전 소스 디렉토리 삭제.
#    if [[ -d "${SRC_HOME}/${OPENJPEG_HOME}" ]]; then
#        rm -rf ${SRC_HOME}/${OPENJPEG_HOME}
#    fi
#
#    tar xvzf ${OPENJPEG_NAME}
#    cd ${SRC_HOME}/${OPENJPEG_HOME}
#
#    # export CFLAGS="$CFLAGS -DOPJ_STATIC"
#    mkdir build && cd build
#    cmake -DCMAKE_INSTALL_PREFIX="${FFMPEG_BUILD_PATH}"                                                                 \
#          -DBUILD_SHARED_LIBS:bool=off                                                                                  \
#          -DCMAKE_BUILD_TYPE=Release                                                                                    \
#          -DBUILD_THIRDPARTY:BOOL=on                                                                                    \
#          -DBUILD_PKGCONFIG_FILES:BOOL=on
#
#    make
#    make install
#
#    mkdir -p ${FFMPEG_BUILD_PATH}/build
#    touch ${FFMPEG_BUILD_PATH}/build/openjpeg
#
#    # 컴파일된 소스 삭제
#    if [[ -d "${SRC_HOME}/${OPENJPEG_HOME}" ]]; then
#        rm -rf ${SRC_HOME}/${OPENJPEG_HOME}
#    fi
#
#    printf "\e[00;32m----------------------------------------------\e[00m\n"
#    printf "| \e[00;32m${OPENJPEG_NAME}\e[00m install success...\n"
#    printf "\e[00;32m----------------------------------------------\e[00m\n"
#    printf "\n"
#    sleep 0.5
#fi


# -------------------------------------------------------------------------------------------------------------------
# libtheora
if [[ ! -f "${FFMPEG_BUILD_PATH}/build/libtheora" ]]; then
    LIBTHEORA_NAME=${LIBTHEORA_DOWNLOAD_URL##+(*/)}
    LIBTHEORA_HOME=${LIBTHEORA_NAME%$EXTENSION}

    printf "\n\e[00;32m| ${LIBTHEORA_HOME} install start...\e[00m\n"

    cd ${SRC_HOME}

    # verify that the source exists download
    if [[ ! -f "${SRC_HOME}/${LIBTHEORA_NAME}" ]]; then
        printf "\n\e[00;32m| ${LIBTHEORA_NAME}\e[00m download...\n"
        curl -L -O ${LIBTHEORA_DOWNLOAD_URL}
    fi

    # 이전 소스 디렉토리 삭제.
    if [[ -d "${SRC_HOME}/${LIBTHEORA_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBTHEORA_HOME}
    fi

    tar xvzf ${LIBTHEORA_NAME}
    cd ${SRC_HOME}/${LIBTHEORA_HOME}

    sed -i 's/png_\(sizeof\)/\1/g' examples/png2theora.c &&
    ./configure --prefix=${FFMPEG_BUILD_PATH}                                                                           \
                --with-ogg="${FFMPEG_BUILD_PATH}"                                                                       \
                --disable-shared
    make
    make install

    mkdir -p ${FFMPEG_BUILD_PATH}/build
        touch ${FFMPEG_BUILD_PATH}/build/libtheora

    # 컴파일된 소스 삭제
    if [[ -d "${SRC_HOME}/${LIBTHEORA_HOME}" ]]; then
        rm -rf ${SRC_HOME}/${LIBTHEORA_HOME}
    fi

    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\e[00;32m| ${LIBTHEORA_NAME}\e[00m install success...\n"
    printf "\e[00;32m----------------------------------------------\e[00m\n"
    printf "\n"
    sleep 0.5
fi


# -------------------------------------------------------------------------------------------------------------------
# FFmpeg
printf "\n\e[00;32m |${FFMPEG_HOME}\e[00m install start...\n"

cd ${SRC_HOME}

# verify that the source exists download
if [[ ! -f "${SRC_HOME}/${FFMPEG_NAME}" ]]; then
    printf "\n\e[00;32m| ${FFMPEG_NAME}\e[00m download...\n"
    curl -L -O ${FFMPEG_DOWNLOAD_URL}
fi

    # 이전 소스 디렉토리 삭제.
if [[ -d "${SRC_HOME}/${FFMPEG_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${FFMPEG_HOME}
fi

tar xzvf ${FFMPEG_NAME}
cd ${SRC_HOME}/${FFMPEG_HOME}

export PKG_CONFIG_PATH="${FFMPEG_BUILD_PATH}/lib/pkgconfig"
#pkg-config --cflags opus
#pkg-config --libs   libass
#pkg-config --cflags libass

# -------------------------------------------------------------------------------------------------------------------
# | --enable-gpl            | allow use of GPL code, the resulting libs                                             |
# |                         | and binaries will be under GPL [no]                                                   |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-nonfree        | allow use of nonfree code, the resulting libs                                         |
# |                         | and binaries will be unredistributable [no]                                           |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libx264        | enable H.264 encoding via x264 [no]                                                   |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libx265        | enable HEVC encoding via x265 [no]                                                    |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-version3       | upgrade (L)GPL to version 3 [no]                                                      |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libfdk-aac     | enable AAC de/encoding via libfdk-aac [no]                                            |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libmp3lame     | enable MP3 encoding via libmp3lame [no]                                               |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libopus        | enable Opus de/encoding via libopus [no]                                              |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libvorbis      | enable Vorbis en/decoding via libvorbis,                                              |
# |                         | native implementation exists [no]                                                     |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libvpx         | enable VP8 and VP9 de/encoding via libvpx [no]                                        |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libass         | enable libass subtitles rendering,                                                    |
# |                         | needed for subtitles and ass filter [no]                                              |
# |-----------------------------------------------------------------------------------------------------------------|
# | --enable-libopenjpeg    | enable JPEG 2000 de/encoding via OpenJPEG [no]                                        |
# -------------------------------------------------------------------------------------------------------------------

#INSTALL_CONFIG="--prefix=${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}"
#INSTALL_CONFIG="${INSTALL_CONFIG} --extra-cflags=-I${FFMPEG_BUILD_PATH}/include"
#INSTALL_CONFIG="${INSTALL_CONFIG} --extra-ldflags=-L${FFMPEG_BUILD_PATH}/lib"
#INSTALL_CONFIG="${INSTALL_CONFIG} --extra-libs=-lpthread"

INSTALL_CONFIG="${INSTALL_CONFIG} --disable-debug"
INSTALL_CONFIG="${INSTALL_CONFIG} --disable-ffplay"

INSTALL_CONFIG="${INSTALL_CONFIG} --enable-gpl"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-nonfree"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-version3"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libfdk-aac"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libmp3lame"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libopus"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libtheora"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libvorbis"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libvpx"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libx264"
INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libx265"
#INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libopenjpeg"

if [[ "${OS}" == "linux" ]]; then
    INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libfreetype"
    INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libfribidi"
    INSTALL_CONFIG="${INSTALL_CONFIG} --enable-libass"

    # nVidia-based GPU acceleration
    #INSTALL_CONFIG="${INSTALL_CONFIG} --enable-nvenc"
fi

./configure  --prefix=${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}                                                    \
             --extra-cflags="-I${FFMPEG_BUILD_PATH}/include"                                                            \
             --extra-ldflags="-L${FFMPEG_BUILD_PATH}/lib"                                                               \
             --extra-libs="-lpthread"                                                                                   \
             --pkg-config-flags="--static"                                                                              \
             ${INSTALL_CONFIG}

make
make install
make distclean

cd ${SERVER_HOME}
ln -s ./${PROGRAME_HOME}/${FFMPEG_HOME} ${FFMPEG_ALIAS}

# 컴파일된 소스 삭제
if [[ -d "${SRC_HOME}/${FFMPEG_HOME}" ]]; then
    rm -rf ${SRC_HOME}/${FFMPEG_HOME}
fi

# bin 디렉토리 이외의 디렉토리 색제
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}/include
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}/lib
rm -rf ${SERVER_HOME}/${PROGRAME_HOME}/${FFMPEG_HOME}/share

printf "\e[00;32m----------------------------------------------\e[00m\n"
printf "\e[00;32m| ${FFMPEG_HOME} install success...\e[00m\n"
printf "\e[00;32m----------------------------------------------\e[00m\n"
printf "\n"
sleep 0.5
