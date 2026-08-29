# Changelog

## v0.3.0

### Changes

- Bump OpenFGA to v1.19.0
- Rebuild on `postgres-base` v0.4.0 (kheeper CLI v0.21.0, Grafana 13)

## v0.2.3

### Changes

- Rebuild on `postgres-base` v0.3.2

## v0.2.2

### Changes

- Fix `openfga` failing with `217/USER` ("Unknown user: openfga") on a fresh host. The `openfga` user was created only by a build-time `useradd`, whose `/etc/passwd` write bootc drops during its 3-way `/etc` merge on first boot. Now shipped via `/usr/lib/sysusers.d/openfga.conf` (regenerated every boot); nothing references the user at build time, so the build-time `useradd` is dropped. UID/GID pinned to 972.

## v0.2.1

### Changes

- Rebuild on `postgres-base` v0.3.1

## v0.2.0

### Changes

- Bump `postgres-base` to v0.3.0. `database.users` items are now objects; `starter.d/database.json` updated to `{ "name": "openfga" }` (no password — OpenFGA keeps peer auth over the unix socket)

## v0.1.4

### Changes

- Bump OpenFGA to v1.17.0
- Bump `postgres-base` to v0.2.4 (latest `fedora-bootc:44` digest, kheeper v0.12.2)

## v0.1.3

### Changes

- Bump `postgres-base` to v0.2.3 (kheeper v0.11.2 fixes wal-g object store origin)

## v0.1.2

### Changes

- Bump `postgres-base` to v0.2.2 (peer auth hardened). No config change: `openfga` already connects as OS user `openfga` == DB role `openfga` over the socket.

## v0.1.1

### Changes

- Database and `openfga` role are now provisioned by the shared `kheeper-db-init` service from `postgres-base` instead of a bespoke `openfga-db-init.service`; db identity supplied via `starter.d/database.json`

## v0.1.0

### Features

- OpenFGA v1.14.1 with runtime config rendered from kheeper host config
- Caddy reverse proxy with automatic TLS via Let's Encrypt
- Firewall opens `80/tcp` and `443/tcp` for ACME and HTTPS
- Runs as a dedicated `openfga` system user against an `openfga` role and database (peer auth over the postgres unix socket); `openfga-db-init.service` provisions both idempotently on first boot
- vmsingle scrape config and Grafana dashboard for OpenFGA metrics on `127.0.0.1:2112`
