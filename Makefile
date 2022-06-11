repo = public.ecr.aws/seqera-labs
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
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/seqera-labs
	docker push ${repo}/${image}
	echo "++ Pushing: quay.io/seqeralabs/${image}"
	docker tag ${repo}/${image} quay.io/seqeralabs/${image}
	docker push quay.io/seqeralabs/${image}
