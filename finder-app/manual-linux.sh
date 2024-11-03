#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # apply patch
    git restore './scripts/dtc/dtc-lexer.l'
    sed -i '41d' './scripts/dtc/dtc-lexer.l'

    # Add kernel build steps here
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs

fi
echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# Create necessary base directories
echo "Creating root file and sub directories"
mkdir "rootfs"
cd "rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p "var/log"
echo "Created root file system"
tree -d

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    #  Configure busybox
    make defconfig
else
    cd busybox
    make distclean
    make defconfig
fi

# TODO: Make and install busybox
echo "CONFIG_STATIC=y" >> .config
echo "CONFIG_USE_BUNDLED_LIBC=y" >> .config
echo "CONFIG_FEATURE_INIT=y" >> .config

make CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)
make CROSS_COMPILE=${CROSS_COMPILE} install
# All files are installed in _install so copy to rootfs
echo "Adding files to rootfs"
cp -r _install/* $OUTDIR/rootfs
echo "building process of Busybox done."
echo "Library dependencies"
cd $OUTDIR/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
echo "Adding library dependencies to rootfs"
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -L $SYSROOT/lib64/libm.so.6 lib64
cp -L $SYSROOT/lib64/libresolv.so.2 lib64
cp -L $SYSROOT/lib64/libc.so.6 lib64

# TODO: Make device nodes
echo "Making device nodes"
cd $OUTDIR/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1

# TODO: Clean and build the writer utility
cd $FINDER_APP_DIR
echo "Clean and build writer utility"
if [ -e writer ]
then
  make clean
fi
make


# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copy finder.sh and writer.sh into home directory"
cp finder.sh $OUTDIR/rootfs/home/
cp writer $OUTDIR/rootfs/home/

# TODO: Chown the root directory
echo "chown root directory"
cd $OUTDIR/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
echo "Create initramfs.cpio.gz"
cd $OUTDIR/rootfs
find . | cpio -H newc -ov --owner root:root > $OUTDIR/initramfs.cpio
cd $OUTDIR
gzip initramfs.cpio
