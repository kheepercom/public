# Changelog

## v0.1.0

### Features

- Forgejo v15.0.2 installed as a binary at `/usr/local/bin/forgejo`, supervised by `forgejo.service` as a dedicated `git` system user
- Postgres-backed (peer auth over the unix socket); `forgejo-db-init.service` provisions the `forgejo` role and database idempotently on first boot
- `forgejo-init.service` injects the operator-supplied domain into `[server]` of `app.ini`, runs `forgejo migrate`, and creates the bootstrapped admin user (idempotent); Forgejo persists its own `SECRET_KEY`, `INTERNAL_TOKEN`, `JWT_SECRET`, and `LFS_JWT_SECRET` into `app.ini` on first boot
- `/etc/forgejo` is owned `root:git` mode `0770` (and `app.ini` mode `0660`) so Forgejo can persist its generated secrets; `forgejo.service` `ReadWritePaths` permits writes to that directory
- Caddy reverse proxy with automatic TLS via Let's Encrypt fronts the web UI on `127.0.0.1:3500` (Forgejo binds `:3500` rather than its default `:3000` to avoid colliding with Grafana from `metrics-base`)
- Git-over-SSH via Forgejo's built-in SSH server on `0.0.0.0:2222` (avoids colliding with the host admin sshd on port 22)
- Firewall opens `80/tcp` + `443/tcp` (Caddy/ACME) and `2222/tcp` (git SSH)
- `git` package installed (required by Forgejo's migrate path)
- vmsingle scrape config and Grafana dashboard for Forgejo metrics on `127.0.0.1:3500/metrics`
- Open registration disabled by default; admin can create users from the UI
