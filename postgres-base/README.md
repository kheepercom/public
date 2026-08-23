# postgres-base

`us.kheeper.com/public/postgres-base` — [`metrics-base`](../metrics-base) plus a local Postgres alongside another application. Ships `postgresql-server`, continuous WAL archiving via wal-g, scheduled base backups, and a `postgres_exporter` scrape config wired into vmsingle.

This image is meant to be layered, not booted directly. If you want a server that just runs Postgres (with public TLS on `5432`), use [`postgres`](../postgres) instead — it builds on this image and adds Let's Encrypt issuance and the firewall openings.

## Configuration

Inherits `admin_authorized_keys` from [`base`](../base). No additional config fields are exposed.

## Ports

Inherits `22/tcp` from [`base`](../base). Postgres binds to `127.0.0.1:5432` and the unix socket at `/var/run/postgresql` — no additional ports are opened. Downstream images that want Postgres reachable externally must drop a higher-numbered snippet in `/etc/kheeper/postgresql-conf.d/` to widen `listen_addresses` and add their own firewall rule (see [`postgres`](../postgres) for the reference layering).

## Layering on this image

```Containerfile
FROM us.kheeper.com/public/postgres-base:v0.3.2

# install your app, configure it to talk to localhost:5432 (or the unix
# socket at /var/run/postgresql), etc.
```

The init service runs `initdb` as the `postgres` user on first boot so the cluster is ready before your app starts.

### Overriding `postgresql.conf`

Drop snippets into `/etc/kheeper/postgresql-conf.d/` at build time. The init script appends them in alphabetical order on first boot (and after a `pg_basebackup` restore), so a higher-numbered snippet wins for any duplicate setting. `postgres-base` ships `10-listen.conf` (loopback only) and `20-walg.conf` (wal-g archiving); use `30-` and up for your own overrides.

## What's inside

- `postgresql-server` from the Fedora repos, configured to listen only on `localhost` and the unix socket
- `postgresql-init.service` — runs `initdb` on first boot, then appends snippets from `/etc/kheeper/postgresql-conf.d/*.conf` to `postgresql.conf`
- `wal-g` for continuous WAL archiving and base backups
- `kheeper-object-proxy` — adapts wal-g's S3-compatible client to Kheeper's object store (`objects.kheeper.com`) using the host authentication key
- `walg-base-backup.timer` — daily base backup
- `walg-retention.timer` — daily prune, keeping the last 7 full backups
- `postgres_exporter` registered with vmsingle via a drop-in scrape config
- `kheeper-db-init.service` — creates a configured application database and its local peer-auth users (see [Application database](#application-database))
- `postgresql-contrib` extensions and the `en_US.utf8` locale (via `glibc-langpack-en`) available in the image
- `kheeper` CLI bundled at `/usr/local/bin` needed for the object proxy

## Backups

WAL segments archive on every Postgres flush via `archive_command = 'wal-g wal-push %p'`. Base backups run daily on `walg-base-backup.timer`; `walg-retention.timer` prunes anything older than the most recent 7 full backups.

All wal-g traffic is routed through `kheeper-object-proxy` running on localhost. No object-store credentials are stored on the host.

To inspect backups from the host:

```
sudo -u postgres bash -c 'set -a; . /etc/kheeper/walg.env; wal-g backup-list'
```

To force a base backup outside the timer:

```
systemctl start walg-base-backup.service
```

## Metrics

`postgres_exporter` runs as a system service and exposes Postgres metrics on the loopback. A scrape config at `/etc/victoria-metrics/scrape.d/postgres.json` registers it with the local vmsingle from `metrics-base`. A `Postgres Overview` Grafana dashboard ships at `/etc/grafana/dashboards/postgres.json` (connections, transaction rate, cache hit ratio, locks, WAL archiving, deadlocks).

## Application database

`kheeper-db-init.service` creates one application database and its local users
at first boot, driven by the `database` config namespace:

- `database.name` — the database to create.
- `database.users` — roles created `LOGIN`, each `{name, password?}`. The
  first user owns the database; any additional users get full DDL/DML on it.
  A user with a `password` can authenticate over TCP (`scram-sha-256`,
  including `127.0.0.1` — and remotely in the standalone [`postgres`](../postgres)
  image); a user without one is local peer-auth only.

Peer auth requires a matching OS user in the `postgres` group; create it in your
layer (`useradd --system --no-create-home --shell /sbin/nologin --user-group
--groups postgres <user>`). A consuming service must declare an ordering dependency
on this one — add `After=kheeper-db-init.service` and
`Requires=kheeper-db-init.service` to its unit so the database exists before the
app starts. Leaving `database` unset is fine — the service then does nothing.
`name` and `users` must be set together; omitting either causes the service to
skip init silently.

The rendered `kheeper-db-init.sql` carries any configured passwords, so it is
secured at `0640 root:postgres` via the factory + tmpfiles pattern.
