#!/bin/bash

set -x

ROOTPATH=$(cd `dirname $0`; pwd)
TMP_DIR=${ROOTPATH}/build
CROSS_TOP_SIM="`xcode-select --print-path`/Platforms/iPhoneSimulator.platform/Developer"
CROSS_SDK_SIM="iPhoneSimulator.sdk"

CROSS_TOP_IOS="`xcode-select --print-path`/Platforms/iPhoneOS.platform/Developer"
CROSS_SDK_IOS="iPhoneOS.sdk"

BUILD_THREADS=$(sysctl hw.ncpu | awk '{print $2}')

FAT_DIST_DIR=${TMP_DIR}/fat
THIN_DIST_DIR=${TMP_DIR}/thin

export CROSS_COMPILE=`xcode-select --print-path`/Toolchains/XcodeDefault.xctoolchain/usr/bin/

rm -rf ${TMP_DIR}
mkdir -p ${FAT_DIST_DIR} ${FAT_DIST_DIR}/lib THIN_DIST_DIR

function build_for ()
{
  PLATFORM=$1
  ARCH=$2
  CROSS_TOP_ENV=CROSS_TOP_$3
  CROSS_SDK_ENV=CROSS_SDK_$3

  make clean

  export CROSS_TOP="${!CROSS_TOP_ENV}"
  export CROSS_SDK="${!CROSS_SDK_ENV}"
  ./Configure $PLATFORM "-arch $ARCH -fembed-bitcode" no-asm no-shared no-hw no-async --prefix=${THIN_DIST_DIR}/${ARCH} || exit 1
  make -j "${BUILD_THREADS}" && make install_sw || exit 2
  unset CROSS_TOP
  unset CROSS_SDK
}

function pack_for ()
{
  LIBNAME=$1
  ${DEVROOT}/usr/bin/lipo \
  ${THIN_DIST_DIR}/x86_64/lib/lib${LIBNAME}.a \
  ${THIN_DIST_DIR}/armv7s/lib/lib${LIBNAME}.a \
  ${THIN_DIST_DIR}/arm64/lib/lib${LIBNAME}.a \
  -output ${FAT_DIST_DIR}/lib/lib${LIBNAME}.a -create
}

patch Configurations/10-main.conf < ${ROOTPATH}/patch-conf.patch

build_for ios64sim-cross x86_64 SIM || exit 3
build_for ios-cross armv7s IOS || exit 4
build_for ios64-cross arm64 IOS || exit 5

pack_for ssl || exit 6
pack_for crypto || exit 7

cp -r ${THIN_DIST_DIR}/armv7s/include ${FAT_DIST_DIR}/
curl https://raw.githubusercontent.com/sinofool/build-openssl-ios/master/patch-include.patch ${ROOTPATH}/patch-include.patch
#cp ../build-openssl-ios/patch-include.patch .
patch -p3 ${FAT_DIST_DIR}/include/openssl/opensslconf.h < ${ROOTPATH}/patch-include.patch

echo "Successfully output to ${TMP_DIR}"
