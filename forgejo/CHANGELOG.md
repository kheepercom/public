# Changelog

## v0.7.0

### Fixes

- Admin sshd on port 2222 is now socket-activated (`sshd.socket`) instead of a
  long-running `sshd.service`. SELinux labels only tcp/22 as `ssh_port_t` and
  `sshd_t` may not `name_bind` any other port, so under enforcing `sshd -D`
  exited 255 with "Cannot bind any address" and crash-looped on `Restart=on-failure`
  — leaving nothing on 2222 and, because the unit stays in `activating (auto-restart)`,
  showing nothing in `systemctl --failed`. systemd binds the socket as `init_t`,
  which may bind any `port_type`, so admin SSH now works with SELinux enforcing

## v0.6.0

### Changes

- Bump to Forgejo v16.0.3 (from v15.0.5). Git hooks now live in a centralized
  location instead of being copied into every repository; existing repositories
  keep working, and their leftover per-repository hook files can be cleaned up
  by following the [upgrade guide](https://forgejo.org/docs/v16.0/admin/upgrade/#hooks)
- Bump the Actions runner to v13.0.0 (from v12.13.0). The `add-path`, `set-output`
  and `set-env` workflow commands are gone — write to `$FORGEJO_PATH`,
  `$FORGEJO_OUTPUT` and `$FORGEJO_ENV` instead — and a failed expression
  interpolation or an invalid job matrix is now a hard error rather than a warning
- Rebuild on `postgres-base` v0.4.0 (kheeper CLI v0.21.0, Grafana 13)

## v0.5.0

### Changes

- Runner `capacity` raised from 1 to 12, so up to 12 jobs run concurrently instead
  of queuing behind a single slot

## v0.4.1

### Changes

- Bump to forgejo v15.0.5
- Rebuild on `postgres-base` v0.3.2

## v0.4.0

### Features

- Forgejo Actions enabled (`[actions] ENABLED = true`), with a co-located runner
  (`act_runner` v12.13.0) so CI runs on the same machine — no separate runner host
- Runner uses the **host executor** (`native:host`): job steps run directly on the
  host as the unprivileged `act-runner` user (uid/gid 971, via `sysusers.d`). Target
  it from workflows with `runs-on: native`. `nodejs` installed so JS actions
  (e.g. `actions/checkout`) run
- `act-runner-init.service` waits for Forgejo's HTTP API, mints a runner
  registration token via the `git` user, and registers the runner on first boot
  (idempotent — skipped once `/var/lib/act-runner/.runner` exists); `act-runner.service`
  then runs `act_runner daemon`
- `DEFAULT_ACTIONS_URL = https://code.forgejo.org` so actions not hosted on this
  instance resolve. No new firewall ports (the runner only dials `127.0.0.1:3500`)
- `act-runner` gets a subordinate uid/gid range (`/etc/subuid` + `/etc/subgid`)
  so rootless podman works under the host executor — CI workflows that stand up
  containers (e.g. testcontainers) run. Without it `podman run` fails with
  `no subuid ranges found for user act-runner`. Written at boot by
  `act-runner-subid.service` (idempotent) rather than at build time, since bootc
  drops build-time `/etc` writes on a fresh host — the same reason the `git` and
  `act-runner` accounts come from `sysusers.d`
- A Docker-compatible podman API socket runs continuously as `act-runner`
  (`act-runner-podman.service`), and `DOCKER_HOST` is injected into every job
  (runner `envs` in `act-runner-config.yaml`), so container test harnesses like
  testcontainers work with no per-workflow podman setup

## v0.3.2

### Changes

- Fix `forgejo-init`/`forgejo` failing with `217/USER` ("Unknown user: git") on a fresh host. The `git` user was created only by a build-time `useradd`, whose `/etc/passwd` write bootc drops during its 3-way `/etc` merge on first boot. Now shipped via `/usr/lib/sysusers.d/forgejo-git.conf` (regenerated every boot), matching how `base` provides `admin`. UID/GID pinned to 973 so `/var/lib/forgejo` data keeps its owner across rebuilds.

## v0.3.1

### Changes

- Rebuild on `postgres-base` v0.3.1

## v0.3.0

### Changes

- Bump `postgres-base` to v0.3.0. `database.users` items are now objects; `starter.d/database.json` updated to `{ "name": "git" }` (no password — Forgejo keeps peer auth over the unix socket)

## v0.2.3

### Changes

- Bump `postgres-base` to v0.2.4 (latest `fedora-bootc:44` digest, kheeper v0.12.2)

## v0.2.2

### Changes

- Bump `postgres-base` to v0.2.3 (kheeper v0.11.2 fixes wal-g object store origin)

## v0.2.1

- postgres-base bumped to v0.2.2 (peer auth). DB role renamed from `forgejo` to `git` so the OS user (`git`) matches the DB role under peer auth.

## v0.2.0

### Changes

- Provision the `forgejo` role and database via the shared `kheeper-db-init` from `postgres-base` (with a `starter.d/database.json` default) instead of a forgejo-specific `forgejo-db-init.service`, removing a duplicate-database race that left `kheeper-db-init` failed
- Forgejo's built-in SSH server now listens on the default port `22`; clone URLs no longer need an explicit port (`git@<domain>:<user>/<repo>.git`)
- Admin sshd moved to `2222` (forgejo-only `sshd_config.d` drop-in) — administer the host with `ssh -p 2222 admin@<host>`
- `forgejo.service` granted `CAP_NET_BIND_SERVICE` so the non-root `git` user can bind privileged port `22`

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
