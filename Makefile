repo = public.cr.seqera.io/seqeralabs
# DEPRECATED: legacy root repository, still pushed as a mirror for backward compatibility
legacy_repo = public.cr.seqera.io
version ?= $(shell cat VERSION)
image = nf-jdk:corretto-${version}

# Extract the specific version tag from the pinned base image
# e.g. "$(ECR_MIRROR)/amazoncorretto/amazoncorretto:17.0.18-al2023@sha256:..." → "17.0.18-al2023"
BASE_IMAGE_TAG = $(word 2,$(subst :, ,$(word 1,$(subst @, ,$(BASE_IMAGE)))))
image_versioned = nf-jdk:corretto-$(BASE_IMAGE_TAG)

ifdef DATE_TAG
  immutable_tag = -t ${repo}/${image_versioned}-${DATE_TAG} -t ${legacy_repo}/${image_versioned}-${DATE_TAG}
  immutable_tag_jemalloc = -t ${repo}/${image_versioned}-jemalloc-${DATE_TAG} -t ${legacy_repo}/${image_versioned}-jemalloc-${DATE_TAG}
endif

ifdef METADATA_FILE
  metadata_flag = --metadata-file $(METADATA_FILE)
endif

# Versions to build (single source of truth for CI matrix)
VERSIONS = 17-al2023 21-al2023 25-al2023

# Registry the base images are pulled from: the central ECR pull-through cache of public.ecr.aws.
# It needs an ECR login (CI does it via OIDC). Without AWS access (local builds, fork PRs) use
# the upstream registry instead: make build ECR_MIRROR=public.ecr.aws
ECR_MIRROR ?= 232933512461.dkr.ecr.eu-west-2.amazonaws.com/thirdparty/ecr-public

# Base image pins with digests (Renovate bumps digests here, looking them up on public.ecr.aws)
CORRETTO_17_AL2023 = $(ECR_MIRROR)/amazoncorretto/amazoncorretto:17.0.21-al2023@sha256:b5b1d232e150fa301a0da1eef38813d2cb2a62d4cea2d673ad208670316eec7a
CORRETTO_21_AL2023 = $(ECR_MIRROR)/amazoncorretto/amazoncorretto:21.0.13-al2023@sha256:ffc24a5a0f53cd72751846662190bdfcc78223b808f08e7888cbf46f2e891989
CORRETTO_25_AL2023 = $(ECR_MIRROR)/amazoncorretto/amazoncorretto:25.0.5-al2023@sha256:52c31cd025e2bc9746f0209301da8958271d56643f987b1b6b620d4a6ba36a0e

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
	 -t ${legacy_repo}/${image} \
	 -t ${legacy_repo}/${image_versioned} \
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
	 -t ${legacy_repo}/${image}-jemalloc \
	 -t ${legacy_repo}/${image_versioned}-jemalloc \
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

# Output the pinned base image for the given version (e.g. make -s print-base-image version=21-al2023)
print-base-image:
	@echo $(BASE_IMAGE)

# Output JSON array of versions for CI dynamic matrix (e.g. ["17-al2023","21-al2023","25-al2023"])
print-versions:
	@printf '["%s"]\n' "$$(echo $(VERSIONS) | sed 's/ /","/g')"
