repo = cr.seqera.io/public
version ?= $(shell cat VERSION)
image = nf-jdk:corretto-${version}

# Extract the specific version tag from the pinned base image
# e.g. "public.ecr.aws/.../amazoncorretto:17.0.18-al2023@sha256:..." → "17.0.18-al2023"
BASE_IMAGE_TAG = $(word 2,$(subst :, ,$(word 1,$(subst @, ,$(BASE_IMAGE)))))
image_versioned = nf-jdk:corretto-$(BASE_IMAGE_TAG)

ifdef DATE_TAG
  immutable_tag = -t ${repo}/${image_versioned}-${DATE_TAG}
  immutable_tag_jemalloc = -t ${repo}/${image_versioned}-jemalloc-${DATE_TAG}
endif

ifdef METADATA_FILE
  metadata_flag = --metadata-file $(METADATA_FILE)
endif

# Versions to build (single source of truth for CI matrix)
VERSIONS = 17-al2023 21-al2023 25-al2023

# Base image pins with digests (Renovate bumps digests here)
CORRETTO_17_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:17.0.20-al2023@sha256:c6558af083e5dec620ce676223ea4af24a0bae366c4418325047d00ab0af2077
CORRETTO_21_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:21.0.12-al2023@sha256:ad03a9cebb7e8ae1d1332f447c357fd3ff98d73e0889de9b26c1bb498e2bc649
CORRETTO_25_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:25.0.4-al2023@sha256:a61433d7af32e5b6a997ae818c8eea3380bed50c27998fc67fffd26764bb1f50

# Map version to base image (used when version= is set)
base_image_17-al2023 = $(CORRETTO_17_AL2023)
base_image_21-al2023 = $(CORRETTO_21_AL2023)
base_image_25-al2023 = $(CORRETTO_25_AL2023)
BASE_IMAGE = $(base_image_$(version))

all: build push

build: build-base build-jemalloc

build-base:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 --build-arg BASE_IMAGE=$(BASE_IMAGE) \
	 -t ${repo}/${image} \
	 -t ${repo}/${image_versioned} \
	 $(immutable_tag) \
	 -f Dockerfile \
	 --push \
	 $(metadata_flag) \
	 .

build-jemalloc:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64,linux/arm64 \
	 --build-arg BASE_IMAGE=$(BASE_IMAGE) \
	 -t ${repo}/${image}-jemalloc \
	 -t ${repo}/${image_versioned}-jemalloc \
	 $(immutable_tag_jemalloc) \
	 -f Dockerfile_jemalloc \
	 --push \
	 $(metadata_flag) \
	 .

build-base-local:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64 \
	 --build-arg BASE_IMAGE=$(BASE_IMAGE) \
	 -t ${image} \
	 -f Dockerfile \
	 --load \
	 .

build-jemalloc-local:
	docker buildx \
	 build \
	 --no-cache \
	 --platform linux/amd64 \
	 --build-arg BASE_IMAGE=$(BASE_IMAGE) \
	 -t ${image}-jemalloc \
	 -f Dockerfile_jemalloc \
	 --load \
	 .

test: build-base-local build-jemalloc-local
	bash tests/test-image.sh $(image) base
	bash tests/test-image.sh $(image)-jemalloc jemalloc

push:
	echo "++ Multi-arch images already pushed during build"

# Output JSON array of versions for CI dynamic matrix (e.g. ["17-al2023","21-al2023","25-al2023"])
print-versions:
	@printf '["%s"]\n' "$$(echo $(VERSIONS) | sed 's/ /","/g')"
