#!/bin/bash
set -e

JEMALLOC_VERSION="5.3.0"
ARCH="${1:-$(uname -m)}"

case $ARCH in
    x86_64|amd64)
        TARGET_ARCH="amd64"
        ;;
    aarch64|arm64)
        TARGET_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Building jemalloc ${JEMALLOC_VERSION} for ${TARGET_ARCH} (native build)"

# Create build directory
BUILD_DIR="jemalloc-build-${TARGET_ARCH}"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Download and extract jemalloc
echo "Downloading jemalloc ${JEMALLOC_VERSION}..."
curl -sSL "https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2" | tar -xj

cd jemalloc-${JEMALLOC_VERSION}

# Configure and build natively
echo "Configuring jemalloc..."
./configure \
    --enable-prof \
    --prefix="/opt/jemalloc"

echo "Building jemalloc..."
make -j$(nproc)

echo "Installing jemalloc to temporary directory..."
make install DESTDIR="$(pwd)/install"

# Create target directory structure
echo "Creating binary package..."
mkdir -p "../../jemalloc-binaries/${TARGET_ARCH}"
cp -r "$(pwd)/install/opt/jemalloc"/* "../../jemalloc-binaries/${TARGET_ARCH}/"

# Verify the build
echo "Verifying build..."
ls -la "../../jemalloc-binaries/${TARGET_ARCH}/"
file "../../jemalloc-binaries/${TARGET_ARCH}/lib/libjemalloc.so.2"

echo "jemalloc ${JEMALLOC_VERSION} built successfully for ${TARGET_ARCH}"
echo "Binaries available in: jemalloc-binaries/${TARGET_ARCH}/"