# nf-jdk

Multi-architecture Java JDK containers optimized with different memory allocators for backend execution in the Seqera ecosystem.

## Container Variants

This project builds three types of Java containers, each optimized for different use cases:

### 🏗️ Base Container
- **Image**: `nf-jdk:corretto-{version}`
- **Architecture**: AMD64, ARM64
- **Memory Allocator**: System default
- **Use Case**: Standard Java applications

### ⚡ Jemalloc Container  
- **Image**: `nf-jdk:corretto-{version}-jemalloc`
- **Architecture**: AMD64 only
- **Memory Allocator**: [jemalloc 5.3.0](https://github.com/jemalloc/jemalloc)
- **Use Case**: High-performance applications with intensive memory allocation

### 🚀 Mimalloc Container
- **Image**: `nf-jdk:corretto-{version}-mimalloc`  
- **Architecture**: AMD64, ARM64
- **Memory Allocator**: [mimalloc 2.1.7](https://github.com/microsoft/mimalloc)
- **Use Case**: Cross-platform performance optimization

## Architecture Support Matrix

| Variant  | AMD64 | ARM64 | Notes                           |
|----------|-------|-------|---------------------------------|
| Base     | ✅     | ✅     | Standard Java runtime           |
| Jemalloc | ✅     | ❌     | AMD64 only (see ARM64 issues)   |
| Mimalloc | ✅     | ✅     | Full multi-architecture support |

## Available Versions

All container variants are built for multiple Java versions:
- **Java 17**: `17-al2023` (Amazon Linux 2023)
- **Java 21**: `21-al2023` (Amazon Linux 2023)  
- **Java 25**: `25-al2023` (Amazon Linux 2023)

## Registry

Images are published to Seqera Labs' container registry:
- **Registry**: `cr.seqera.io/public`
- **Repository**: `nf-jdk`

## Usage Examples

```bash
# Pull base containers
docker pull cr.seqera.io/public/nf-jdk:corretto-25-al2023
docker pull cr.seqera.io/public/nf-jdk:corretto-21-al2023
docker pull cr.seqera.io/public/nf-jdk:corretto-17-al2023

# Pull jemalloc-optimized containers (AMD64 only)
docker pull cr.seqera.io/public/nf-jdk:corretto-25-al2023-jemalloc
docker pull cr.seqera.io/public/nf-jdk:corretto-21-al2023-jemalloc
docker pull cr.seqera.io/public/nf-jdk:corretto-17-al2023-jemalloc

# Pull mimalloc-optimized containers (multi-architecture)
docker pull cr.seqera.io/public/nf-jdk:corretto-25-al2023-mimalloc
docker pull cr.seqera.io/public/nf-jdk:corretto-21-al2023-mimalloc
docker pull cr.seqera.io/public/nf-jdk:corretto-17-al2023-mimalloc
```

## ARM64 and Jemalloc Compatibility Issues

### The Problem

Jemalloc has fundamental compatibility issues with ARM64 architectures, particularly Apple Silicon (M-series chips). As documented in [Facebook Buck2 issue #91](https://github.com/facebook/buck2/issues/91), the core problems are:

1. **Page Size ABI Binding**: Jemalloc compiles the host system's memory page size directly into the library ABI
2. **Cross-Platform Incompatibility**: Binaries built on 4k page systems (traditional x86/ARM) crash when run on 16k page systems (Apple Silicon)
3. **Runtime Failures**: Applications simply crash rather than gracefully handling the incompatibility

### Facebook's Recommendation

Facebook's Buck2 team recommends **turning off jemalloc for ARM64 platforms** entirely, which is exactly what this project implements.

### The Mimalloc Alternative

[Microsoft's mimalloc](https://github.com/microsoft/mimalloc) provides an excellent alternative that:
- ✅ **Works across all architectures** including ARM64 and Apple Silicon
- ✅ **Handles different page sizes** gracefully  
- ✅ **Provides excellent performance** comparable to or better than jemalloc
- ✅ **Maintained by Microsoft** with active development

## Build System

### Automated Builds

The project uses a unified GitHub Actions workflow that:
- **Schedule**: Runs daily at 1:00 AM UTC
- **Manual Trigger**: Available via `workflow_dispatch`
- **No Push Builds**: Removed for cleaner development workflow
- **Matrix Strategy**: Builds 9 containers per run (3 versions × 3 variants)

### Build Architecture

1. **Binary Compilation**: Native compilation of jemalloc and mimalloc on respective architectures
2. **Container Building**: Multi-architecture container builds using pre-compiled binaries
3. **Automatic Publishing**: Images pushed to registry during build process

### Manual Builds

```bash
# Trigger build workflow manually
gh workflow run build.yml

# Check workflow status  
gh run list --workflow=build.yml --limit=5

# Monitor specific run
gh run view <run-id> --log
```

### Local Development

```bash
# Build all variants locally
make build

# Build specific variants  
make build-base version=25-al2023
make build-jemalloc version=25-al2023    # AMD64 only
make build-mimalloc version=25-al2023    # Multi-arch
```

## Memory Allocator Performance

### When to Use Each Variant

- **Base**: Default choice for standard applications
- **Jemalloc**: CPU-intensive workloads on AMD64 with heavy memory allocation
- **Mimalloc**: High-performance applications requiring ARM64 support or cross-platform consistency

### Performance Characteristics

- **Jemalloc**: Excellent for server workloads with sustained memory allocation patterns
- **Mimalloc**: Lower memory overhead, better for applications with varied allocation patterns
- **System Default**: Adequate for most use cases, lowest complexity

## Technical Documentation

For detailed technical information, build system architecture, and development guidelines, see [CLAUDE.md](./CLAUDE.md).

## References

- [Jemalloc Project](https://github.com/jemalloc/jemalloc)
- [Microsoft mimalloc](https://github.com/microsoft/mimalloc)  
- [Facebook Buck2 ARM64 Issue](https://github.com/facebook/buck2/issues/91)
- [Amazon Corretto](https://aws.amazon.com/corretto/)
- [Seqera](https://www.seqera.io/)
