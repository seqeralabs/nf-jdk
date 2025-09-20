#!/bin/bash
set -e

JEMALLOC_VERSION="5.3.0"
BUILD_DIR="jemalloc-build"
ARCH="${1:-$(uname -m)}"

case $ARCH in
    x86_64|amd64)
        TARGET_ARCH="amd64"
        TARGET_TRIPLE="x86_64-linux-gnu"
        ;;
    aarch64|arm64)
        TARGET_ARCH="arm64"
        TARGET_TRIPLE="aarch64-linux-gnu"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Building jemalloc ${JEMALLOC_VERSION} for ${TARGET_ARCH}"

# Clean up previous builds
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Download and extract jemalloc
curl -sSL "https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2" | tar -xj

cd jemalloc-${JEMALLOC_VERSION}

# Configure and build
./configure \
    --enable-prof \
    --prefix="/opt/jemalloc" \
    --host=${TARGET_TRIPLE}

make -j$(nproc)
make install DESTDIR="$(pwd)/install"

# Copy to architecture-specific directory
mkdir -p "../../jemalloc-binaries/${TARGET_ARCH}"
cp -r "$(pwd)/install/opt/jemalloc"/* "../../jemalloc-binaries/${TARGET_ARCH}/"

echo "jemalloc ${JEMALLOC_VERSION} built successfully for ${TARGET_ARCH}"
echo "Binaries available in: jemalloc-binaries/${TARGET_ARCH}/"