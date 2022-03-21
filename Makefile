repo = public.ecr.aws/seqera-labs
version = 11.0.14
image = nf-jdk:corretto-${version}_2

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
	aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 195996028523.dkr.ecr.eu-west-1.amazonaws.com
	docker push ${repo}/${image}
	echo "++ Pushing: quay.io/seqeralabs/${image}"
	docker tag ${repo}/${image} quay.io/seqeralabs/${image}
	docker push quay.io/seqeralabs/${image}
