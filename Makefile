repo = cr.seqera.io/public
version ?= $(shell cat VERSION)
image = nf-jdk:corretto-${version}
image_jemalloc = nf-jdk:corretto-${version}-jemalloc

ifdef DATE_TAG
  immutable_tag = -t ${repo}/${image}-${DATE_TAG}
  immutable_tag_jemalloc = -t ${repo}/${image_jemalloc}-${DATE_TAG}
endif

# Versions to build (single source of truth for CI matrix)
VERSIONS = 17-al2023 21-al2023 25-al2023

# Base image pins with digests (Renovate bumps digests here)
CORRETTO_17_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023@sha256:1b0f8efb6fed722997d40d8983b1b9973822e69c0dd9851c037eb43fa1e4d84e
CORRETTO_21_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:21-al2023@sha256:ee41dc0d4789eabcc490e928d50b3545cce511a2e46668831f5894f2a84d5548
CORRETTO_25_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:25-al2023@sha256:d805adaadb49bd54903cfedac55c020d5c1b092e0b0873e8ba354bbcbc9f1a92

# Map version to base image (used when version= is set)
base_image_17-al2023 = $(CORRETTO_17_AL2023)
base_image_21-al2023 = $(CORRETTO_21_AL2023)
base_image_25-al2023 = $(CORRETTO_25_AL2023)
BASE_IMAGE = $(base_image_$(version))

all: build push

build: build-base build-jemalloc

build-base:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 --build-arg BASE_IMAGE=$(BASE_IMAGE) \
	 -t ${repo}/${image} \
	 $(immutable_tag) \
	 -f Dockerfile \
	 --push \
	 .

build-jemalloc:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 --build-arg BASE_IMAGE=$(BASE_IMAGE) \
	 -t ${repo}/${image}-jemalloc \
	 $(immutable_tag_jemalloc) \
	 -f Dockerfile_jemalloc \
	 --push \
	 .

push:
	echo "++ Multi-arch images already pushed during build"

# Output JSON array of versions for CI dynamic matrix (e.g. ["17-al2023","21-al2023","25-al2023"])
print-versions:
	@printf '["%s"]\n' "$$(echo $(VERSIONS) | sed 's/ /","/g')"
