#!/bin/bash

source functions.sh

image_path="northamerica-northeast1-docker.pkg.dev/c4hnrd-tools/cicd-repo/sre-cd-runner"
image_package_path="projects/c4hnrd-tools/locations/northamerica-northeast1/repositories/cicd-repo/packages/sre-cd-runner"

# Cloud Build VMs run linux/amd64. Force the platform so the image is usable
# regardless of the host architecture (e.g. Apple Silicon).
export DOCKER_BUILD_PLATFORM="linux/amd64"

build_and_push_image "$image_path" "$image_package_path" "1.2.1"
