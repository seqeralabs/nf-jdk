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

### Main Build (.github/workflows/build.yml)

**Execution Flow:**
1. **Parallel Binary Builds**: 
   - `build-jemalloc` workflow → builds AMD64/ARM64 jemalloc binaries
   - `build-mimalloc` workflow → builds AMD64/ARM64 mimalloc binaries

2. **Parallel Container Builds**:
   - `build-base`: Independent base container
   - `build-jemalloc-container`: Uses jemalloc artifacts
   - `build-mimalloc-container`: Uses mimalloc artifacts

3. **Post-build**: Release tasks (if commit contains `[release]`)

### Binary Build Workflows

- **build-jemalloc.yml**: Compiles jemalloc 5.3.0 natively for AMD64 only
- **build-mimalloc.yml**: Compiles mimalloc 2.1.7 natively for both architectures
- **Artifacts**: 1-day retention, consumed by container builds

### Nightly Builds (.github/workflows/nightlybuild.yml)

- **Schedule**: Daily at 1:00 AM UTC
- **Matrix**: Java versions 17-al2023, 21-al2023, 25-al2023 (all three variants: base, jemalloc, mimalloc)
- **Version Source**: Hardcoded matrix in workflow
- **Structure**: Matches main build.yml with separate jobs for each container variant
- **Architecture**: Base and mimalloc support AMD64/ARM64, jemalloc is AMD64-only
- **Release**: Implicit release behavior - all nightly builds are automatically tagged

## Release Process

### Automated Release (tag-and-push.sh)

**Trigger**: Commit message contains `[release]`
**Process**:
1. Extract version from `VERSION` file
2. Create Git tag: `v{VERSION}_{COMMIT_ID}`
3. Push tag to repository

**Force Release**: Use `[force release]` to override existing tags

### Version Management

- **Production**: `VERSION` file (currently: 25-al2023)
- **Nightly**: Hardcoded matrix in workflow (17-al2023, 21-al2023, 25-al2023)

## Development Commands

### Testing Builds Locally
```bash
# Build all variants
make build

# Build specific variant
make build-jemalloc
make build-mimalloc
```

### Release Process
```bash
# Create release (add [release] to commit message)
git commit -m "Update feature [release]"
git push

# Force release (override existing tag)
git commit -m "Hotfix [force release]"
git push
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