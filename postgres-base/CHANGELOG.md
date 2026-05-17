# Changelog

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
