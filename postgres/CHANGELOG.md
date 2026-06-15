# Changelog

## v0.2.0
- Remote clients now connect as their configured app users (`database.users`), each with its own password, over TLS.
- Removed the superuser `password` config field; `postgres` is now peer/local-only (admin via SSH).
- Built on postgres-base v0.3.0.

## v0.1.4

### Changes

- Bump `postgres-base` to v0.2.4 (latest `fedora-bootc:44` digest, kheeper v0.12.2)

## v0.1.3

### Changes

- Bump `postgres-base` to v0.2.3 (kheeper v0.11.2 fixes wal-g object store origin)

## v0.1.2

### Changes

- Bump `postgres-base` to v0.2.2 (peer auth + socket-only listen default hardening); no functional change — `30-listen.conf`'s `listen_addresses = '*'` still overrides the new base default, and external TLS clients continue to use the appended `hostssl all postgres … scram-sha-256` rule with the superuser password as before

## v0.1.1

### Changes

- Build on `postgres-base` v0.2.0, picking up the latest `fedora-bootc:44` base digest

## v0.1.0

### Features

- Built on `postgres-base`, which provides `postgresql-server`, wal-g, `kheeper-object-proxy`, `postgres_exporter`, and the `kheeper` CLI
- Let's Encrypt certificate issuance and deploy via `lego`, with auto-renewal on a dedicated `postgres-cert-renew.timer`; falls back to IP-address certs when no domain is configured
- Overrides `postgres-base`'s loopback default with `listen_addresses = '*'` so Postgres is reachable on the public 5432
- `postgres` superuser password configured from kheeper host config, with a `hostssl ... scram-sha-256` rule in `pg_hba.conf` for external clients
- Firewall opens `5432/tcp` (PostgreSQL) and `80/tcp` (ACME)
