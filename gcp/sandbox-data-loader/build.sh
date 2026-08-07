#!/bin/bash

image_path="northamerica-northeast1-docker.pkg.dev/c4hnrd-tools/cicd-repo/sandbox-data-loader"
image_package_path="projects/c4hnrd-tools/locations/northamerica-northeast1/repositories/cicd-repo/packages/sandbox-data-loader"

# Versioned build arguments — override via env vars at build time
CLOUD_SQL_PROXY_VERSION="${CLOUD_SQL_PROXY_VERSION:-2.23.0}"
IMAGE_TAG="${IMAGE_TAG:-1.0.7}"

# Cloud Build VMs run linux/amd64. Force the platform so the image is usable
# regardless of the host architecture (e.g. Apple Silicon).
export DOCKER_BUILD_PLATFORM="linux/amd64"

docker build \
  --platform "$DOCKER_BUILD_PLATFORM" \
  --build-arg "CLOUD_SQL_PROXY_VERSION=${CLOUD_SQL_PROXY_VERSION}" \
  -t "${image_path}:${IMAGE_TAG}" \
  .
docker push "${image_path}:${IMAGE_TAG}"
