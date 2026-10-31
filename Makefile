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
CORRETTO_17_AL2023 = $(ECR_MIRROR)/amazoncorretto/amazoncorretto:17.0.21-al2023@sha256:52bfe5bfef9204b5da96ea5d8b2c5e9cafd2af1d1f8a771078929fde9cac827c
CORRETTO_21_AL2023 = $(ECR_MIRROR)/amazoncorretto/amazoncorretto:21.0.13-al2023@sha256:a9589d4842ace85a42dfb131b0c1d20ddeb259570d859d3bbd114423fd574318
CORRETTO_25_AL2023 = $(ECR_MIRROR)/amazoncorretto/amazoncorretto:25.0.5-al2023@sha256:1d4209157bc2eb0851b74f5971009048381ecde00beaaf61487f0a9f7688f075

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
