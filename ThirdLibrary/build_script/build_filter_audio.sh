#!/bin/bash

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBITIM_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
#   RABBITIM_BUILD_PREFIX=`pwd`/../${RABBITIM_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBITIM_BUILD_SOURCE_CODE    #源码目录
#   RABBITIM_BUILD_CROSS_PREFIX   #交叉编译前缀
#   RABBITIM_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM (android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
    RABBITIM_BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

if [ -z "${RABBITIM_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBITIM_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBITIM_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBITIM_BUILD_SOURCE_CODE=$2
else
    RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_PREFIX}/../src/filter_audio
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBITIM_BUILD_SOURCE_CODE} ]; then
    if [ "TRUE" = "$RABBITIM_USE_REPOSITORIES" ]; then
        echo "git clone -q https://github.com/irungentoo/filter_audio.git ${RABBITIM_BUILD_SOURCE_CODE}"
        git clone -q  https://github.com/irungentoo/filter_audio.git ${RABBITIM_BUILD_SOURCE_CODE}
    else
        echo "wget -q  https://github.com/irungentoo/filter_audio/archive/master.zip"
        mkdir -p ${RABBITIM_BUILD_SOURCE_CODE}
        cd ${RABBITIM_BUILD_SOURCE_CODE}
        wget -q -c https://github.com/irungentoo/filter_audio/archive/master.zip
        unzip -q  master.zip
        mv filter_audio-master ..
        rm -fr *
        cd ..
        rm -fr ${RABBITIM_BUILD_SOURCE_CODE}
        mv -f filter_audio-master ${RABBITIM_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBITIM_BUILD_SOURCE_CODE}

#清理
if [ "$RABBITIM_CLEAN" = "TRUE" ]; then
    if [ -d ".git" ]; then
        echo "clean ..."
        git clean -xdf
    fi
fi

echo ""
echo "RABBITIM_BUILD_TARGERT:${RABBITIM_BUILD_TARGERT}"
echo "RABBITIM_BUILD_SOURCE_CODE:$RABBITIM_BUILD_SOURCE_CODE"
echo "CUR_DIR:`pwd`"
echo "RABBITIM_BUILD_PREFIX:$RABBITIM_BUILD_PREFIX"
echo "RABBITIM_BUILD_HOST:$RABBITIM_BUILD_HOST"
echo "RABBITIM_BUILD_CROSS_HOST:$RABBITIM_BUILD_CROSS_HOST"
echo "RABBITIM_BUILD_CROSS_PREFIX:$RABBITIM_BUILD_CROSS_PREFIX"
echo "RABBITIM_BUILD_CROSS_SYSROOT:$RABBITIM_BUILD_CROSS_SYSROOT"
echo "RABBITIM_BUILD_STATIC:$RABBITIM_BUILD_STATIC"
echo ""

echo "configure ..."

case ${RABBITIM_BUILD_TARGERT} in
    android)
        export CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc 
        export CXX=${RABBITIM_BUILD_CROSS_PREFIX}g++
        export AR=${RABBITIM_BUILD_CROSS_PREFIX}ar
        export LD=${RABBITIM_BUILD_CROSS_PREFIX}ld
        export AS=${RABBITIM_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBITIM_BUILD_CROSS_PREFIX}strip
        export NM=${RABBITIM_BUILD_CROSS_PREFIX}nm
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="${CFLAGS}"
    ;;
    unix)
        ;;
    windows_msvc)
        echo "build_speex.sh don't support windows_msvc. please manually use msvc ide complie"
        cd $CUR_DIR
        exit 2
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                export CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc 
                export CXX=${RABBITIM_BUILD_CROSS_PREFIX}g++
                export AR=${RABBITIM_BUILD_CROSS_PREFIX}ar
                export LD=${RABBITIM_BUILD_CROSS_PREFIX}ld
                export AS=${RABBITIM_BUILD_CROSS_PREFIX}as
                export STRIP=${RABBITIM_BUILD_CROSS_PREFIX}strip
                export NM=${RABBITIM_BUILD_CROSS_PREFIX}nm
        esac
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 3
    ;;
esac

echo "make install"
make ${RABBITIM_MAKE_JOB_PARA} VERBOSE=1 && make install PREFIX=${RABBITIM_BUILD_PREFIX}
if [ -f "${RABBITIM_BUILD_PREFIX}/lib/libfilteraudio.dll" ]; then
    mv ${RABBITIM_BUILD_PREFIX}/lib/libfilteraudio.dll ${RABBITIM_BUILD_PREFIX}/bin
fi

cd $CUR_DIR
