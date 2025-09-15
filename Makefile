repo = cr.seqera.io/public
version = $(shell cat VERSION)
image = nf-jdk:corretto-${version}

all: setup-builder build push

setup-builder:
	docker buildx create --name multiarch --use --bootstrap || docker buildx use multiarch

build:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image} \
	 -f Dockerfile \
	 --push \
	 .

	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image}-jemalloc \
	 -f Dockerfile_jemalloc \
	 --push \
	 .

push:
	echo "++ Multi-arch images already pushed during build"

