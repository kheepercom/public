# Forgejo

[Homepage](https://forgejo.org)

[Codeberg](https://codeberg.org/forgejo/forgejo)

> Forgejo is a self-hosted lightweight software forge — a Git host with code review, issue tracking, releases, and CI.

Operate Forgejo on your server with persistence in a local Postgres and automatic TLS provided by [Caddy](https://caddyserver.com). Git-over-SSH is served by Forgejo's built-in SSH server on the default port `22`; admin SSH to the host is moved to port `2222`.

## Configuration

| Field | Description |
| ----- | ----------- |
| `domain` | Public domain resolving to this host. Used by Caddy for automatic TLS and as Forgejo's `ROOT_URL` / `SSH_DOMAIN`. After your host autoregisters it will have a DNS record at `<host>.<org>.kheeper.app` that you can use. |
| `admin_username` | Username for the initial admin account, created on first boot. |
| `admin_password` | Password for the initial admin account. **Create-only**: changing this in `config.json` after first boot will NOT rotate the password — see [Rotating the admin password](#rotating-the-admin-password). Minimum 12 characters. |
| `admin_email` | Email for the initial admin account. |

## Launch on GCP

Connect your GCP project to your kheeper org (once per project):

```
ORG=<your-kheeper-org>
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get project) --format='value(projectNumber)')
kheeper clouds create my-gcp --org $ORG --project-number $PROJECT_NUMBER
```

Open the firewall rules Forgejo needs. The image's host firewall opens `80/tcp` and `443/tcp` from anywhere (Caddy/ACME + HTTPS), `22/tcp` from anywhere (git SSH), and `2222/tcp` (admin SSH); the cloud-side firewall must match:

```
# 80/443 for ACME and the Forgejo HTTPS UI
gcloud compute firewall-rules create allow-https \
    --allow tcp:80,tcp:443 \
    --target-tags allow-https

# 22 for git-over-SSH
gcloud compute firewall-rules create allow-forgejo-ssh \
    --allow tcp:22 \
    --target-tags allow-forgejo-ssh

# 2222 for admin SSH to the host (scope to your admin IPs)
gcloud compute firewall-rules create allow-admin-ssh \
    --allow tcp:2222 \
    --source-ranges <your-admin-CIDRs> \
    --target-tags allow-admin-ssh
```

Create the VM:

```
HOST=my-forgejo
gcloud compute instances create $HOST \
    --image-family fedora-bootc --image-project kheeper \
    --zone us-central1-a \
    --machine-type c4-standard-2 \
    --boot-disk-size 40GB \
    --metadata=kheeper-region=us.kheeper.com \
    --tags=allow-https,allow-forgejo-ssh,allow-admin-ssh
```

The host auto-registers within a minute and gets a DNS A record at `$HOST.$ORG.kheeper.app` you can use for `domain`. Confirm:

```
kheeper hosts list --org $ORG
```

While the host is starting, configure your first release:

```
kheeper releases start config.json --image us.kheeper.com/public/forgejo:v0.6.0
```

That writes a default `./config.json`. Edit it so `domain` matches your DNS record, set `admin_username`, `admin_password` (min 12 chars), and `admin_email`. Then create and activate the release:

```
kheeper releases create $ORG/$HOST:v1 \
    --image us.kheeper.com/public/forgejo:v0.6.0 \
    --config-file config.json \
    --activate
```

`$ORG/$HOST:v1` is your release tag; `us.kheeper.com/public/forgejo:v0.6.0` is the image it's built from.

## Alternative platforms

- [Bare metal](https://kheeper.com/docs/getting-started/boot-bare-metal) — register a physical host via iPXE
- [AWS](https://kheeper.com/docs/getting-started/boot-aws) — same flow as GCP using EC2 + a security group

In both cases, replicate the firewall section above on your cloud / network: `80/443` and `22/tcp` from anywhere, `2222/tcp` scoped to your admin IPs.

## Git over SSH

Forgejo's built-in SSH server listens on `0.0.0.0:22`, so clone URLs use the default port:

```
git clone git@<your-domain>:<user>/<repo>.git
```

Add your public key in **Settings → SSH / GPG Keys** in the web UI before pushing.

## Actions (CI)

Forgejo Actions is enabled, with a runner co-located on the same host — no
separate runner machine to provision. On first boot the host registers a runner
against the local instance automatically; confirm it in the web UI under
**Site Administration → Actions → Runners**.

The runner uses the **host executor**: workflow steps run directly on the host as
the unprivileged `act-runner` user, rather than in containers. Target it with
`runs-on: native`:

```yaml
on: [push]
jobs:
  build:
    runs-on: native
    steps:
      - uses: actions/checkout@v4
      - run: echo "hello from CI"
```

Notes:

- Because steps run on the host, workflows have host-level access as `act-runner`.
  Only run workflows you trust.
- `node` is installed for JS actions (`actions/checkout`, etc.); actions not hosted
  on this instance resolve via `https://code.forgejo.org`.
- `podman` is available (rootless — `act-runner` has a subuid/subgid range) and a
  Docker-compatible API socket runs continuously (`act-runner-podman.service`).
  `DOCKER_HOST` is preset for every job, so a container test harness like
  testcontainers works with no setup — just run your tests.
- Up to 12 jobs run concurrently (runner `capacity`); size the host accordingly,
  since all of them run directly on it.
- The actions cache server is off by default (avoids binding an extra port); enable
  it in `/etc/act-runner/config.yaml` if you need `actions/cache`.

## Rotating the admin password

The `admin_password` field is consumed only on first boot; editing `config.json` afterwards does not rotate the password. To change it, SSH to the host (on port `2222`: `ssh -p 2222 admin@<host>`) and run:

```
sudo -u git /usr/local/bin/forgejo -c /etc/forgejo/app.ini \
    -w /var/lib/forgejo \
    admin user change-password --username <name> --password <new>
```
