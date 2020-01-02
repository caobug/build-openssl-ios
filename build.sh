#!/usr/bin/env bash

ROOTPATH=$(cd `dirname $0`; pwd)

export OPENSSL_VER=1.1.1d

curl -O https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz
tar xf openssl-${OPENSSL_VER}.tar.gz
pushd openssl-${OPENSSL_VER}

${ROOTPATH}/build_openssl_dist.sh

popd

rm -rf openssl-${OPENSSL_VER}
rm -f openssl-${OPENSSL_VER}.tar.gz
