# nf-jdk

Multi-architecture Java JDK containers optimized with different memory allocators for backend execution in the Seqera ecosystem.

## Container Variants

This project builds two types of Java containers, each optimized for different use cases:

### 🏗️ Base Container
- **Image**: `nf-jdk:corretto-{version}`
- **Architecture**: AMD64, ARM64
- **Memory Allocator**: System default
- **Use Case**: Standard Java applications

### ⚡ Jemalloc Container
- **Image**: `nf-jdk:corretto-{version}-jemalloc`
- **Architecture**: AMD64, ARM64
- **Memory Allocator**: [jemalloc 5.2.1](https://github.com/jemalloc/jemalloc) (Amazon Linux 2023 package)
- **Use Case**: High-performance applications with intensive memory allocation

## Architecture Support Matrix

| Variant  | AMD64 | ARM64 | Notes                           |
|----------|-------|-------|---------------------------------|
| Base     | ✅     | ✅     | Standard Java runtime           |
| Jemalloc | ✅     | ✅     | Multi-arch via AL2023 package  |

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

# Pull jemalloc-optimized containers (multi-architecture)
docker pull cr.seqera.io/public/nf-jdk:corretto-25-al2023-jemalloc
docker pull cr.seqera.io/public/nf-jdk:corretto-21-al2023-jemalloc
docker pull cr.seqera.io/public/nf-jdk:corretto-17-al2023-jemalloc
```

## Jemalloc Multi-Architecture Support

### Amazon Linux 2023 Package Approach

This project uses the **Amazon Linux 2023 jemalloc package** instead of custom compilation, which provides several benefits:

#### ✅ **Native ARM64 Compatibility**
- AWS has configured jemalloc with appropriate page size settings for ARM64
- Optimized for Graviton processors with proper page size handling
- No custom compilation or cross-platform compatibility issues

#### ✅ **Simplified Build Process**
- Uses standard package manager installation (`yum install jemalloc`)
- Eliminates complex binary compilation and artifact management
- Reduced build time and fewer potential failure points

#### ✅ **Security and Maintenance**
- Officially maintained and regularly updated by AWS
- Security patches automatically included in package updates
- Consistent with Amazon Linux 2023 ecosystem optimizations

### ARM64 Page Size Compatibility

Jemalloc may have compatibility issues with ARM64 systems that use different page sizes, particularly:
- **Apple Silicon (16K pages)**: As documented in [Facebook Buck2 issue #91](https://github.com/facebook/buck2/issues/91) and [jemalloc issue #2178](https://github.com/jemalloc/jemalloc/issues/2178)
- **Some ARM64 server systems (64K pages)**: See [Red Hat Bugzilla #1545539](https://bugzilla.redhat.com/show_bug.cgi?id=1545539)

However, **Amazon Linux 2023 uses 4K page size** ([AWS documentation](https://docs.aws.amazon.com/linux/al2023/ug/ec2.html)), which is compatible with jemalloc's default configuration, ensuring reliable operation across all AWS Graviton instances.

## Build System

### Automated Builds

The project uses a unified GitHub Actions workflow that:
- **Schedule**: Runs daily at 1:00 AM UTC
- **Manual Trigger**: Available via `workflow_dispatch`
- **No Push Builds**: Removed for cleaner development workflow
- **Matrix Strategy**: Builds 6 containers per run (3 versions × 2 variants)

### Build Architecture

1. **Package Installation**: Jemalloc uses Amazon Linux 2023 package manager
2. **Container Building**: Multi-architecture container builds with optimized layers
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
make build-jemalloc version=25-al2023    # Multi-arch
```

## Memory Allocator Performance

### When to Use Each Variant

- **Base**: Default choice for standard applications
- **Jemalloc**: CPU-intensive workloads with heavy memory allocation (AMD64/ARM64)

### Performance Characteristics

- **Jemalloc**: Excellent for server workloads with sustained memory allocation patterns
- **System Default**: Adequate for most use cases, lowest complexity

## Technical Documentation

For detailed technical information, build system architecture, and development guidelines, see [CLAUDE.md](./CLAUDE.md).

## References

- [Jemalloc Project](https://github.com/jemalloc/jemalloc)
- [Facebook Buck2 ARM64 Issue](https://github.com/facebook/buck2/issues/91)
- [Amazon Corretto](https://aws.amazon.com/corretto/)
- [Seqera](https://www.seqera.io/)
