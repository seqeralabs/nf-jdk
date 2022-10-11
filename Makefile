repo = public.ecr.aws/seqera-labs
version = $(shell cat VERSION)
image = nf-jdk:corretto-${version}
username = "non-root"
useruid = 1000
usergid = 1000

all: build push

build:
	docker buildx \
	 build \
	 --platform linux/amd64 \
	 -o type=docker \
	 --build-arg VERSION=${version} USERNAME=${username} USER_UID=${useruid} USER_GID=${usergid} \
	 -t ${repo}/${image} \
	 .

push:
	echo "++ Pushing: ${repo}/${image}"
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/seqera-labs
	docker push ${repo}/${image}