repo = cr.seqera.io/public
version = $(shell cat VERSION)
image = nf-jdk:corretto-${version}

all: build push

build: build-base build-jemalloc build-mimalloc

build-base:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image} \
	 -f Dockerfile \
	 --push \
	 .

build-jemalloc:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64 \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image}-jemalloc \
	 -f Dockerfile_jemalloc \
	 --push \
	 .

build-mimalloc:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image}-mimalloc \
	 -f Dockerfile_mimalloc \
	 --push \
	 .

push:
	echo "++ Multi-arch images already pushed during build"

