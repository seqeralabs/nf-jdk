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
CORRETTO_17_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:17.0.19-al2023@sha256:89b1e9c4240a6364ab8900ec7c1f55be4b7e1fdfbeaf7b7d250b57639c8b8afd
CORRETTO_21_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:21.0.11-al2023@sha256:df5ecb112a7649f3112c29d070218cd360a6240d8b406fc50d9ebc96f4e32be2
CORRETTO_25_AL2023 = public.ecr.aws/amazoncorretto/amazoncorretto:25.0.3-al2023@sha256:249302248efa3784a1610f113e714f5d5a9337b0b3b0320cb7248c79f45f6243

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
