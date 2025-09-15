#!/bin/bash
set -e

echo "Building jemalloc for multiple architectures using Docker"

# Build for AMD64
echo "Building for AMD64..."
docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    --platform linux/amd64 \
    amazonlinux:2023 \
    bash -c "
        yum update -y && \
        yum groupinstall -y 'Development Tools' && \
        yum install -y bzip2 curl && \
        ./build-jemalloc.sh x86_64
    "

# Build for ARM64
echo "Building for ARM64..."
docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    --platform linux/arm64 \
    amazonlinux:2023 \
    bash -c "
        yum update -y && \
        yum groupinstall -y 'Development Tools' && \
        yum install -y bzip2 curl && \
        ./build-jemalloc.sh aarch64
    "

echo "Multi-architecture build complete!"
echo "AMD64 binaries: jemalloc-binaries/amd64/"
echo "ARM64 binaries: jemalloc-binaries/arm64/"