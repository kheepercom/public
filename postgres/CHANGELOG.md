# Changelog

## v0.3.0

### Changes

- Bump lego to v5.4.0 (from v4.35.2). v5 redesigned the CLI: `renew` folded into
  `run`, global flags became command flags, `--days` became `--renew-days`,
  `--run-hook`/`--renew-hook` became `--deploy-hook`, and the hook's
  `LEGO_CERT_*` environment variables became `LEGO_HOOK_CERT_*`. Renewal timing
  is now driven by ARI when the CA offers it, with `--renew-days` as the floor
- `postgres-cert` runs `lego migrate` before issuing, converting an existing
  `/var/lib/lego` to the v5 layout. It is skipped on a host that has never
  issued, and is a no-op once done
- IP certificates are now ordered through lego directly instead of a hand-built
  CSR. v4 put the target in the certificate's common name, which Let's Encrypt
  rejects for an IP, so the image generated its own empty-subject CSR and passed
  `--csr`. v5 leaves the common name empty by default and turns an IP in
  `--domains` into an ACME `ip` identifier, producing the same request. The
  deploy hook drops the key-path fallback that only the `--csr` path needed.
  A host holding an IP cert issued the old way keeps it until its next renewal;
  the leftover `/var/lib/lego/csr` is unused and can be deleted
- Rebuild on `postgres-base` v0.4.0 (kheeper CLI v0.21.0, Grafana 13)

### Notes

- Rolling a host back to v0.2.2 after it has booted this image will leave lego
  v4 unable to read the migrated `/var/lib/lego`. Certificate issuance and
  renewal would need `/var/lib/lego` cleared to recover

## v0.2.2

### Changes

- Rebuild on `postgres-base` v0.3.2

## v0.2.1

### Changes

- Rebuild on `postgres-base` v0.3.1

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
