repo = cr.seqera.io/public
version ?= $(shell cat VERSION)
image = nf-jdk:corretto-${version}

all: build push

build: build-base build-jemalloc

build-base:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 -t ${repo}/${image} \
	 -f Dockerfile.$(version) \
	 --push \
	 .

build-jemalloc:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 -t ${repo}/${image}-jemalloc \
	 -f Dockerfile_jemalloc.$(version) \
	 --push \
	 .

push:
	echo "++ Multi-arch images already pushed during build"

