# Build Structure Documentation

## Project Overview

This is a multi-architecture Java JDK container project (`nf-jdk`) that builds three variants of Java containers with different memory allocators, specifically designed for backend execution in the Nextflow ecosystem.

## Build Architecture

### Container Variants

1. **Base Container** (`Dockerfile`)
   - Image: `nf-jdk:corretto-{version}`
   - Standard JDK with basic utilities (tar, gzip, procps, which)
   - Includes `wait-for-it.sh` script

2. **Jemalloc Container** (`Dockerfile_jemalloc`)
   - Image: `nf-jdk:corretto-{version}-jemalloc`
   - Pre-compiled jemalloc 5.3.0 binaries for AMD64 only
   - Environment: `LD_PRELOAD=/opt/jemalloc/lib/libjemalloc.so.2`

3. **Mimalloc Container** (`Dockerfile_mimalloc`)
   - Image: `nf-jdk:corretto-{version}-mimalloc`
   - Pre-compiled mimalloc 2.1.7 binaries for AMD64/ARM64
   - Environment: `LD_PRELOAD=/opt/mimalloc/lib/libmimalloc.so.2.1`

### Multi-Architecture Support

- **Architectures**: linux/amd64, linux/arm64
- **Build Method**: Docker Buildx with multi-platform support
- **Native Compilation**: Memory allocators compiled natively on respective architectures
- **Runners**: `ubuntu-latest` (AMD64), `ubuntu-24.04-arm64` (ARM64)

## Build Targets (Makefile)

- `make all`: Build and push all variants
- `make build`: Build all variants (base + jemalloc + mimalloc)
- `make build-base`: Standard Java container
- `make build-jemalloc`: Container with jemalloc
- `make build-mimalloc`: Container with mimalloc
- `make push`: No-op (images pushed during build)

## Workflow Structure

### Unified Build (.github/workflows/build.yml)

**Triggers:**
- **Schedule**: Daily at 1:00 AM UTC (cron: "0 1 * * *")
- **Manual**: workflow_dispatch for on-demand builds
- **No push builds**: Removed automatic builds on code pushes

**Execution Flow:**
1. **Parallel Binary Builds** (inline jobs):
   - `build-jemalloc-amd64`: Builds AMD64 jemalloc binaries
   - `build-mimalloc-amd64`: Builds AMD64 mimalloc binaries
   - `build-mimalloc-arm64`: Builds ARM64 mimalloc binaries

2. **Parallel Container Matrix Builds**:
   - `build-base`: Matrix job (3 versions) - independent base containers
   - `build-jemalloc-container`: Matrix job (3 versions) - uses AMD64 jemalloc artifacts
   - `build-mimalloc-container`: Matrix job (3 versions) - uses AMD64/ARM64 mimalloc artifacts

**Matrix Strategy:**
- **Versions**: ['17-al2023', '21-al2023', '25-al2023']
- **Total Builds**: 9 container images per run (3 versions × 3 variants)
- **Architecture Support**: Base and mimalloc multi-arch, jemalloc AMD64-only

## Release Process

### Container Image Publishing
- **Automatic**: Images are pushed during build with `--push` flag
- **No Git tagging**: Removed tag-and-push.sh script and post-build jobs
- **Registry**: cr.seqera.io/public
- **Image naming**: nf-jdk:corretto-{version}[-jemalloc|-mimalloc]

### Version Management

- **Unified Matrix**: ['17-al2023', '21-al2023', '25-al2023'] hardcoded in workflow
- **No VERSION file dependency**: All versions specified directly in workflow

## Development Commands

### Testing Builds Locally
```bash
# Build all variants
make build

# Build specific variant
make build-jemalloc
make build-mimalloc
```

### Manual Builds
```bash
# Trigger build workflow manually via GitHub Actions UI
# or using GitHub CLI:
gh workflow run build.yml

# Check workflow status
gh run list --workflow=build.yml --limit=5
```

## Key Dependencies

- **Registry**: cr.seqera.io/public
- **Base Image**: Amazon Corretto JDK on Amazon Linux 2023
- **Required Secrets**: SEQERA_CR_USERNAME, SEQERA_CR_PASSWORD
- **Build Tools**: Docker Buildx, native compilation scripts

## Performance Optimizations

1. **Multi-Stage Builds**: Separate binary compilation and container assembly
2. **Artifact Caching**: Binary artifacts cached between workflows
3. **Parallel Execution**: Independent builds run concurrently
4. **Native Compilation**: Architecture-specific binary building
5. **Docker Layer Caching**: Buildx optimization for multi-platform builds