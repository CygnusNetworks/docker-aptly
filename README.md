### docker-aptly

Minimal container image for [aptly](https://www.aptly.info/), the Debian repository manager, built on `debian:trixie-slim`.

The image contains the upstream aptly release binary (checksum-verified against the SHA-256 digest GitHub records for the release asset), plus `gnupg`/`gpgv` (aptly calls gpg for signing), `curl` (healthcheck) and CA certificates. It has no web server and no process supervisor: aptly serves its REST API only. Publish the `public/` directory with a separate web server if needed.

#### Supported tags
- `latest` and `<aptly-version>` (e.g. `1.6.3`) on Docker Hub (`cygnusnetworks/aptly`) and GHCR (`ghcr.io/cygnusnetworks/aptly`), for `linux/amd64` and `linux/arm64`.
- A daily check rebuilds when the `debian:trixie-slim` digest, the latest aptly release or this repository's build recipe changes, and at least every 30 days. Pin the version tag in production; note that `<aptly-version>` is rebuilt for Debian updates.

#### Usage
The image runs as root, uses `GNUPGHOME=/opt/aptly/gpg` and expects the aptly root directory (`rootDir` in the config) at the volume `/opt/aptly`.

```
docker run -d --name aptly \
  -v aptly_data:/opt/aptly \
  -v ./aptly.conf:/etc/aptly.conf \
  cygnusnetworks/aptly:1.6.3
```

Default command: `aptly api serve -listen=:8080 -no-lock` (listening on port 8080).

#### Local build
```
docker build -t aptly:local .
```
Override `APTLY_VERSION`, `APTLY_SHA256_AMD64` and `APTLY_SHA256_ARM64` to build another release.
