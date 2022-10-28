repo = cr.seqera.io/public
version = $(shell cat VERSION)
image = nf-jdk:corretto-${version}

all: build push

build:
	docker buildx \
	 build \
	 --platform linux/amd64 \
	 -o type=docker \
	 --build-arg VERSION=${version} \
	 -t ${repo}/${image} \
	 .

push:
	echo "++ Pushing: ${repo}/${image}"
	docker push ${repo}/${image}

