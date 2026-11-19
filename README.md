# docker-aptly

[![Docker Build and Publish](https://github.com/CygnusNetworks/docker-aptly/actions/workflows/docker-build.yml/badge.svg)](https://github.com/CygnusNetworks/docker-aptly/actions/workflows/docker-build.yml)
[![Docker Hub](https://img.shields.io/docker/pulls/cygnusnetworks/aptly)](https://hub.docker.com/r/cygnusnetworks/aptly)

Minimal container image for [aptly](https://www.aptly.info/), the Debian repository manager, built on `debian:trixie-slim`.

The image contains the upstream aptly release binary (checksum-verified against the SHA-256 digest GitHub records for the release asset), plus `gnupg`/`gpgv` (aptly calls gpg for signing), `bzip2`/`xz-utils` (compression of the published index files), `curl` (healthcheck) and CA certificates. It has no web server and no process supervisor: aptly serves its REST API only. Publish the `public/` directory with a separate web server (see [Serving the published repository](#serving-the-published-repository)).

## Tags

| Tag | Meaning |
| --- | --- |
| `latest` | the most recent build |
| `<aptly-version>` (e.g. `1.6.3`) | that aptly release; rebuilt whenever the Debian base image is updated |

Available on Docker Hub (`cygnusnetworks/aptly`) and GHCR (`ghcr.io/cygnusnetworks/aptly`) for `linux/amd64` and `linux/arm64`. Pin the version tag in production.

### Automatic rebuilds and security updates

A daily check (03:23 UTC) rebuilds and publishes the image when

- the `debian:trixie-slim` base image has a new digest (Debian security updates),
- a new aptly release is published upstream,
- this repository's `Dockerfile` or build workflow changed, or
- the published image is older than 30 days.

Otherwise nothing is rebuilt. Update your running container regularly (for example with Watchtower or `docker compose pull && docker compose up -d`) to pick up rebuilt images.

## Usage

The image runs as root, uses `GNUPGHOME=/opt/aptly/gpg` and expects the aptly root directory (`rootDir` in the config) at the volume `/opt/aptly`.

```
docker run -d --name aptly \
  -v aptly_data:/opt/aptly \
  -v ./aptly.conf:/etc/aptly.conf \
  cygnusnetworks/aptly:1.6.3
```

Default command: `aptly api serve -listen=:8080 -no-lock`. The REST API listens on port 8080; the built-in healthcheck queries `/api/version`.

### Serving the published repository

aptly writes the published repositories to `<rootDir>/public`. Serve that directory read-only with a web server of your choice, for example with Docker Compose:

```yaml
services:
  aptly:
    image: cygnusnetworks/aptly:1.6.3
    restart: unless-stopped
    volumes:
      - aptly_data:/opt/aptly
      - ./aptly.conf:/etc/aptly.conf
  web:
    image: nginx:stable-alpine
    restart: unless-stopped
    ports:
      - 127.0.0.1:8082:80
    volumes:
      - aptly_data:/usr/share/nginx/html:ro   # serves the whole root dir; restrict to public/ via your nginx config
volumes:
  aptly_data:
```

The REST API has no authentication of its own: do not expose port 8080 to untrusted networks, and put access control (IP allow lists, Basic auth, TLS) in front of the web server.

## Local build

```
docker build -t aptly:local .
```

Override `APTLY_VERSION`, `APTLY_SHA256_AMD64` and `APTLY_SHA256_ARM64` to build another release.

## CI and publishing

The GitHub Actions workflows in this repository

- lint and test the publishing scripts and build the image without publishing on every pull request and push to `main` (`ci.yml`),
- check the Debian base digest and the latest aptly release daily and publish to GHCR and Docker Hub only when something changed (`docker-build.yml`); a manual rebuild is possible via **Run workflow** with the `force` input,
- record the base digest, aptly version and a hash of the build recipe as image labels so the next check can detect changes,
- re-enable the build workflow on every scheduled run so GitHub does not suspend the schedule for inactivity,
- sync this `README.md` to the Docker Hub description whenever it changes (`docker-readme.yaml`).

## Credits

Thanks to the [aptly project](https://github.com/aptly-dev/aptly) for the upstream software.
