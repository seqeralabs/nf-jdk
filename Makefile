repo = cr.seqera.io/public
version = $(shell cat VERSION)
image = nf-jdk:corretto-${version}-up2

all: build push

build:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64 \
	 -o type=docker \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image} \
	 .

push:
	echo "++ Pushing: ${repo}/${image}"
	docker push ${repo}/${image}

