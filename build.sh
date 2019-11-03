#!/bin/bash -e
#
# Build Docker container images

# Defaults
REPO_NAME_D=dovetailautomata/mk-cross-builder
IMAGE_NAME_D=amd64_10

# Read settings from file
if test -f "$HOME/.mk-cross-builder.conf.sh"; then
    . $HOME/.mk-cross-builder.conf.sh
fi

USAGE="Usage:  $0 [ -r <docker_id> ] [ -t <docker_repo> ]
        $0 -i <docker_id>/<docker_repo>:<tag>"

# Read command line options
while getopts r:t:i: ARG; do
    case $ARG in
        r) REPO_NAME=$OPTARG ;;
        t) CACHE_TAG=$OPTARG ;;
        i) IMAGE_NAME=$OPTARG ;;
	    h) echo "$USAGE" >&2; exit ;;
	    *) echo "$USAGE" >&2; exit 1 ;;
    esac
done
if test -n "$REPO_NAME" -o -n "$CACHE_NAME"; then
    REPO_NAME=${REPO_NAME:-${REPO_NAME_D}}
    CACHE_TAG=${IMAGE_NAME:-${IMAGE_NAME_D}}
    IMAGE_NAME="${REPO_NAME}:${CACHE_TAG}"
else
    IMAGE_NAME="${IMAGE_NAME:-${REPO_NAME_D}:${IMAGE_NAME_D}}"
    REPO_NAME=${IMAGE_NAME%%:*}
    CACHE_TAG=${IMAGE_NAME##*:}
fi

# Set Dockerfile path
DOCKERFILE_PATH=Dockerfile

# Build configuration variables for each tag
# - Architecture settings
case "${CACHE_TAG}" in
    amd64_*)
        DEBIAN_ARCH="amd64"
        SYS_ROOT=
        HOST_MULTIARCH="x86_64-linux-gnu"
        EXTRA_FLAGS=
        LDEMULATION=elf_x86_64
        ;;
    armhf_*)
        DEBIAN_ARCH="armhf"
        SYS_ROOT="/sysroot"
        HOST_MULTIARCH="arm-linux-gnueabihf"
        EXTRA_FLAGS=
        LDEMULATION=armelf_linux_eabi
        ;;
    arm64_*)
        DEBIAN_ARCH="arm64"
        SYS_ROOT="/sysroot"
        HOST_MULTIARCH="aarch64-linux-gnu"
        EXTRA_FLAGS=
        LDEMULATION=aarch64linux
        ;;
    i386_*)
        DEBIAN_ARCH="i386"
        SYS_ROOT="/sysroot"
        HOST_MULTIARCH="i386-linux-gnu"
        EXTRA_FLAGS="-m32"
        LDEMULATION="elf_i386"
        ;;
    *)
        echo "Unknown tag '${CACHE_TAG}'" >&2
        exit 1
        ;;
esac
# - Distro settings
case "${CACHE_TAG}" in
    *_8)
        DISTRO_CODENAME="jessie"
        BASE_IMAGE="debian:jessie"
        DISTRO_VER="8"
        ;;
    *_9)
        DISTRO_CODENAME="stretch"
        BASE_IMAGE="debian:stretch"
        DISTRO_VER="9"
        ;;
    *_10)
        DISTRO_CODENAME="buster"
        BASE_IMAGE="debian:buster"
        DISTRO_VER="10"
        ;;
    *_11)
        DISTRO_CODENAME="bullseye"
        BASE_IMAGE="debian:bullseye"
        DISTRO_VER="11"
        ;;
    *)
        echo "Unknown tag '${CACHE_TAG}'" >&2
        exit 1
        ;;
esac

# Debug info
(
    echo "Build settings:"
    echo "    IMAGE_NAME=${IMAGE_NAME}"
    echo "    CACHE_TAG=${CACHE_TAG}"
    echo "    DEBIAN_ARCH=${DEBIAN_ARCH}"
    echo "    SYS_ROOT=${SYS_ROOT}"
    echo "    HOST_MULTIARCH=${HOST_MULTIARCH}"
    echo "    DISTRO_CODENAME=${DISTRO_CODENAME}"
    echo "    BASE_IMAGE=${BASE_IMAGE}"
    echo "    DISTRO_VER=${DISTRO_VER}"
    echo "    EXTRA_FLAGS=${EXTRA_FLAGS}"
    echo "    LDEMULATION=${LDEMULATION}"
) >&2

# Be sure we're in the right directory
cd "$(dirname $0)"

# Build the image
set -x
exec docker build \
       --build-arg DEBIAN_ARCH=${DEBIAN_ARCH} \
       --build-arg SYS_ROOT=${SYS_ROOT} \
       --build-arg HOST_MULTIARCH=${HOST_MULTIARCH} \
       --build-arg DISTRO_CODENAME=${DISTRO_CODENAME} \
       --build-arg BASE_IMAGE=${BASE_IMAGE} \
       --build-arg DISTRO_VER=${DISTRO_VER} \
       --build-arg EXTRA_FLAGS=${EXTRA_FLAGS} \
       --build-arg LDEMULATION=${LDEMULATION} \
       ${DOCKER_BUILD_ARGS} \
       -f $DOCKERFILE_PATH -t $IMAGE_NAME .
