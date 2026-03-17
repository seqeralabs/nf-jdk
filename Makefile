repo = cr.seqera.io/public
version ?= $(shell cat VERSION)
# Optional: set DATE_TAG (YYYYMMDD) to also push an immutable date tag
# e.g. nf-jdk:corretto-17-al2023-20250317
image = nf-jdk:corretto-${version}
image_jemalloc = nf-jdk:corretto-${version}-jemalloc
ifdef DATE_TAG
  immutable_tag = -t ${repo}/${image}-${DATE_TAG}
  immutable_tag_jemalloc = -t ${repo}/${image_jemalloc}-${DATE_TAG}
endif

all: build push

build: build-base build-jemalloc

build-base:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 -t ${repo}/${image} \
	 $(immutable_tag) \
	 -f Dockerfile.$(version) \
	 --push \
	 .

build-jemalloc:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 -t ${repo}/${image_jemalloc} \
	 $(immutable_tag_jemalloc) \
	 -f Dockerfile_jemalloc.$(version) \
	 --push \
	 .

push:
	echo "++ Multi-arch images already pushed during build"

