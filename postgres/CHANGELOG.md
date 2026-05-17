# Changelog

## v0.1.0

### Features

- Built on `postgres-base`, which provides `postgresql-server`, wal-g, `kheeper-object-proxy`, `postgres_exporter`, and the `kheeper` CLI
- Let's Encrypt certificate issuance and deploy via `lego`, with auto-renewal on a dedicated `postgres-cert-renew.timer`; falls back to IP-address certs when no domain is configured
- Overrides `postgres-base`'s loopback default with `listen_addresses = '*'` so Postgres is reachable on the public 5432
- `postgres` superuser password configured from kheeper host config, with a `hostssl ... scram-sha-256` rule in `pg_hba.conf` for external clients
- Firewall opens `5432/tcp` (PostgreSQL) and `80/tcp` (ACME)
