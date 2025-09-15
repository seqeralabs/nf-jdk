#!/bin/bash
set -e

MIMALLOC_VERSION="2.1.7"
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

echo "Building mimalloc ${MIMALLOC_VERSION} for ${TARGET_ARCH} (native build)"

# Create build directory
BUILD_DIR="mimalloc-build-${TARGET_ARCH}"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Download and extract mimalloc
echo "Downloading mimalloc ${MIMALLOC_VERSION}..."
curl -sSL "https://github.com/microsoft/mimalloc/archive/refs/tags/v${MIMALLOC_VERSION}.tar.gz" | tar -xz

cd mimalloc-${MIMALLOC_VERSION}

# Create build directory for CMake
mkdir -p build
cd build

# Configure with CMake
echo "Configuring mimalloc..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/mimalloc \
    -DMI_BUILD_SHARED=ON \
    -DMI_BUILD_STATIC=ON \
    -DMI_BUILD_OBJECT=ON \
    -DMI_BUILD_TESTS=OFF \
    -DMI_OVERRIDE=ON

echo "Building mimalloc..."
make -j$(nproc)

echo "Installing mimalloc to temporary directory..."
make install DESTDIR="$(pwd)/install"

# Create target directory structure
echo "Creating binary package..."
mkdir -p "../../../mimalloc-binaries/${TARGET_ARCH}"
cp -r "$(pwd)/install/opt/mimalloc"/* "../../../mimalloc-binaries/${TARGET_ARCH}/"

# Verify the build
echo "Verifying build..."
ls -la "../../../mimalloc-binaries/${TARGET_ARCH}/"
file "../../../mimalloc-binaries/${TARGET_ARCH}/lib/libmimalloc.so.2.1"

echo "mimalloc ${MIMALLOC_VERSION} built successfully for ${TARGET_ARCH}"
echo "Binaries available in: mimalloc-binaries/${TARGET_ARCH}/"