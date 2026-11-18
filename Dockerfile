ARG DEBIAN_IMAGE=debian:trixie-slim

FROM ${DEBIAN_IMAGE} AS fetch
ARG TARGETARCH
ARG APTLY_VERSION=1.6.3
# SHA-256 of the upstream release zips (the release publishes no checksum file; these are the digests GitHub records for the assets)
ARG APTLY_SHA256_AMD64=535ed24eb706bc25a316b59d709a7e74e10165f2ffab8552097ba7e4816a3e7e
ARG APTLY_SHA256_ARM64=dd0988ebe8bfd547482e55de83f178c14e95d5d829d956ce683e0ca045cdb86c

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl unzip; \
    case "${TARGETARCH:-amd64}" in \
        amd64) sha="${APTLY_SHA256_AMD64}" ;; \
        arm64) sha="${APTLY_SHA256_ARM64}" ;; \
        *) echo "unsupported architecture ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/aptly-dev/aptly/releases/download/v${APTLY_VERSION}/aptly_${APTLY_VERSION}_linux_${TARGETARCH:-amd64}.zip" -o /tmp/aptly.zip; \
    echo "${sha}  /tmp/aptly.zip" | sha256sum -c -; \
    unzip -j /tmp/aptly.zip "aptly_${APTLY_VERSION}_linux_${TARGETARCH:-amd64}/aptly" -d /tmp/aptly-bin; \
    install -m 0755 /tmp/aptly-bin/aptly /usr/local/bin/aptly

FROM ${DEBIAN_IMAGE}
ARG DEBIAN_IMAGE
ARG BASE_DIGEST
ARG APTLY_VERSION=1.6.3
ARG BUILD_RECIPE
ARG VCS_REF
LABEL org.opencontainers.image.title="aptly" \
      org.opencontainers.image.description="aptly Debian repository manager (upstream release binary) on Debian trixie-slim" \
      org.opencontainers.image.source="https://github.com/CygnusNetworks/docker-aptly" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${APTLY_VERSION}" \
      org.opencontainers.image.base.name="${DEBIAN_IMAGE}" \
      org.opencontainers.image.base.digest="${BASE_DIGEST}" \
      org.cygnusnetworks.aptly-version="${APTLY_VERSION}" \
      org.cygnusnetworks.build-recipe="${BUILD_RECIPE}"

# gnupg (gpg, gpg-agent) is called by aptly for signing; gpgv verifies signatures; bzip2 and xz-utils are called to compress the published index files; curl is used by the healthcheck
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg gpgv bzip2 xz-utils; \
    rm -rf /var/lib/apt/lists/*

COPY --from=fetch /usr/local/bin/aptly /usr/local/bin/aptly

ENV GNUPGHOME=/opt/aptly/gpg \
    GIN_MODE=release

EXPOSE 8080
VOLUME /opt/aptly
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -fsS http://localhost:8080/api/version || exit 1

# Runs as root on purpose: existing aptly volumes are root-owned.
CMD ["aptly", "api", "serve", "-listen=:8080", "-no-lock"]
