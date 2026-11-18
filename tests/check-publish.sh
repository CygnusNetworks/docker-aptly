#!/usr/bin/env bash
set -euo pipefail

output=$(mktemp)
trap 'rm -f "$output"' EXIT

check() {
  local name=$1 expected=$2
  shift 2
  : > "$output"
  env GITHUB_OUTPUT="$output" "$@" bash scripts/check-publish.sh > /dev/null
  if [[ "$(<"$output")" != "$expected" ]]; then
    printf 'FAIL: %s\nExpected:\n%s\nActual:\n%s\n' "$name" "$expected" "$(<"$output")" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$name"
}

common=(
  BASE_DIGEST=sha256:new
  APTLY_VERSION=1.6.3
  GHCR_LATEST_DIGEST=sha256:published
  DOCKERHUB_LATEST_DIGEST=sha256:published
  PUBLISHED_BASE_DIGEST=sha256:new
  PUBLISHED_APTLY_VERSION=1.6.3
  GHCR_VERSION_DIGEST=sha256:published
  DOCKERHUB_VERSION_DIGEST=sha256:published
  BUILD_RECIPE=recipe
  PUBLISHED_BUILD_RECIPE=recipe
  NOW_EPOCH=1800000000
  PUBLISHED_CREATED_EPOCH=1799000000
)

check 'unchanged upstream and complete tags skip publishing' \
  $'build=false\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}"

check 'changed Debian base digest rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_BASE_DIGEST=sha256:old

check 'new aptly release rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_APTLY_VERSION=1.6.2

check 'changed Dockerfile or workflow rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_BUILD_RECIPE=old-recipe

check 'image older than 30 days rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_CREATED_EPOCH=1790000000

check 'missing latest tag rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" DOCKERHUB_LATEST_DIGEST=

check 'differing latest tags rebuild' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" DOCKERHUB_LATEST_DIGEST=sha256:other

check 'forced build rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" FORCE_BUILD=true

check 'missing version tags are re-created without rebuilding' \
  $'build=false\nretag_ghcr=true\nretag_dockerhub=true' \
  "${common[@]}" GHCR_VERSION_DIGEST= DOCKERHUB_VERSION_DIGEST=sha256:stale
