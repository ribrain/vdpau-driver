#!/bin/bash

BUILDDIR=`pwd`
PREFIX=`pwd`/prefix
TARGET=`pwd`/target

if [ ! -e build.env ]; then echo "Build environment not configured, run setup-build.sh"; exit 1; fi

source build.env

mkdir -p $PREFIX/usr/include/vdpau
mkdir -p $PREFIX/usr/lib

git submodule init
git submodule update

echo "Copying VDPAU headers and libs from viatech-drivers"
[ -x `which basename` ] || { echo "basename command not found"; exit 1; }
vdpau_tarball=`ls platform/viatech-drivers/VDPAU_*`
vdpau_release=`basename $vdpau_tarball | sed s/\.tar\.gz//`
tar -f $vdpau_tarball -C prefix/usr/include/vdpau --wildcards -x "$vdpau_release/include/*" --strip-components=2
tar -f $vdpau_tarball -C prefix/usr/lib --wildcards -x "$vdpau_release/bin/*.so*" --strip-components=2
cd prefix/usr/lib
ln -sf libvdpau.so.1.0.0 libvdpau.so

cd $BUILDDIR
# reconfigure using host version. host-autotools break because of hard-coded paths
PATH=/bin:/usr/bin autoreconf -v --install
CFLAGS="-I$PREFIX/usr/include" LDFLAGS="-L$PREFIX/usr/lib" ./configure --prefix=/usr || exit 1
make || exit 1
make install DESTDIR=$PREFIX

mkdir -p $TARGET
cd $PREFIX
tar cfpz $TARGET/libva-vdpau-driver.tar.gz `cat $BUILDDIR/tar-filelist.txt`

cd $BUILDDIR
echo "Build result:"
ls -l  target
