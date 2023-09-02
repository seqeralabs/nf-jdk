repo = cr.seqera.io/public
version = $(shell cat VERSION)
image = nf-jdk:corretto-${version}

all: build push

build:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64 \
	 -o type=docker \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image} \
	 -f Dockerfile \
	 .

	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64 \
	 -o type=docker \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image}-jemalloc \
	 -f Dockerfile_jemalloc \
	 .

push:
	echo "++ Pushing: ${repo}/${image}"
	docker push ${repo}/${image}
	docker push ${repo}/${image}-jemalloc

