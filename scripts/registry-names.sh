#!/usr/bin/env bash
set -euo pipefail

# The repository is named docker-aptly, the published images are named aptly.
image_name=${IMAGE_NAME:-aptly}
owner_lc=$(printf '%s' "${GITHUB_REPOSITORY%%/*}" | tr '[:upper:]' '[:lower:]')
username_lc=$(printf '%s' "$DOCKER_USERNAME" | tr '[:upper:]' '[:lower:]')

{
  printf 'GHCR_IMAGE=ghcr.io/%s/%s\n' "$owner_lc" "$image_name"
  printf 'DOCKERHUB_IMAGE=%s/%s\n' "$username_lc" "$image_name"
  printf 'DOCKERHUB_REF=docker.io/%s/%s\n' "$username_lc" "$image_name"
} >> "$GITHUB_ENV"
