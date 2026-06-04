# Changelog

## v0.2.4

### Changes

- Rebuild on `metrics-base` v0.1.2 (latest `fedora-bootc:44` digest)
- Bump bundled kheeper CLI to v0.12.2

## v0.2.3

### Fixes

- kheeper version bumped to v0.11.2 fixes wal-g object store origin

## v0.2.2

### Security

- `initdb` now runs with `--auth-local=peer --auth-host=scram-sha-256`: local socket connections use peer auth (OS user must match the DB role), loopback TCP requires `scram-sha-256`. Removes the previous `trust` default. Applies to freshly initialized clusters only.
- `listen_addresses` now defaults to `''` (socket-only, no TCP listener). Images that need TCP override it (standalone postgres → `'*'`).

## v0.2.1

### Fixes

- kheeper version bumped to v0.11.1 fixes kheeper-walg-env service
- pin `POSTGRES_EXPORTER_VERSION` (0.19.1); the undeclared ARG broke the postgres_exporter download

## v0.2.0

### Features

- `kheeper-db-init.service` creates a configured application database and its local peer-auth users (`database.name` / `database.users`), so layered images don't ship their own db-init service and SQL
- `postgresql-contrib` extensions and the `en_US.utf8` locale (via `glibc-langpack-en`) available in the image

### Fixes

- `kheeper-walg-env.service` no longer blocks `postgresql.service` start; WAL archiving sources `walg.env` per `wal-g` call so postgres boots immediately and backups catch up once the env is rendered

## v0.1.0

### Features

- `postgresql-server` from the Fedora repos, listening only on `localhost` and the unix socket by default
- `postgresql-init.service` runs `initdb` on first boot, then appends snippets from `/etc/kheeper/postgresql-conf.d/` to `postgresql.conf` so layered images can override config
- wal-g for continuous WAL archiving and base backups
- `kheeper-object-proxy` adapts wal-g to Kheeper's object store (`objects.kheeper.com`) using the host JWT — no long-lived object-store credentials on the host
- Scheduled wal-g base backups and retention pruning via systemd timers
- `postgres_exporter` registered with vmsingle via a drop-in scrape config
- Grafana dashboard for Postgres overview metrics
- `kheeper` CLI bundled at `/usr/local/bin`
