# base

`us.kheeper.com/public/base` — the bootc base image that every other public kheeper image is built `FROM`. Built on `quay.io/fedora/fedora-bootc:latest` and adds the baseline that any internet-facing host should have: a refreshed package cache, a hardened SSH login for an unprivileged admin user, a locked-down firewall, and a persistent journal with sane retention.

This image is meant to be layered, not booted directly. Image-specific software and configuration belong in the downstream image. Anything that should be true of *every* kheeper public host (firewall posture, ssh policy, log retention) belongs here.

## Configuration

| Field | Description |
| ----- | ----------- |
| `admin_authorized_keys` | Optional. SSH public key(s) to authorize for the `admin` user, one per line. Without this, only kheeper console access remains. |

## Ports

The host firewall opens `22/tcp` for SSH. Downstream images add their own ports on top by dropping a `firewalld` service file or running `firewall-cmd` at build time.

## Layering on this image

```Containerfile
FROM us.kheeper.com/public/base:v0.1.2

# install your app, add your firewall openings, drop in unit files, etc.
```

## dnf

`dnf makecache` runs at build time so downstream images can `dnf install` without each one re-fetching repository metadata.

## firewalld

`firewalld` is installed and enabled, and the default zone is tightened: `dhcpv6-client`, `mdns`, and the `ssh` service are removed and a single explicit `22/tcp` rule is added.

## ssh

SSH login is restricted to a single unprivileged `admin` user (UID 1000) with passwordless sudo via a `/etc/sudoers.d/admin` drop-in. Root SSH login is disabled (`PermitRootLogin no`, `AllowUsers admin`) and the OS root account is locked (`passwd -l root`). `sshd` is configured (`/etc/ssh/sshd_config.d/10-base.conf`) for publickey-only auth with agent/TCP/X11 forwarding disabled and conservative session and auth-retry limits. `PerSourcePenalties` is set explicitly so a single misbehaving source IP gets temporarily blocked by `sshd` itself (30s on auth failure, 10m on repeated abuse) without needing `fail2ban` or a separate `firewalld` ruleset.

`admin_authorized_keys` from the host's kheeper config is rendered into `/var/home/admin/.ssh/authorized_keys` via the `authorized_keys.khtmpl` template, with directory and file modes enforced by a `tmpfiles.d` drop-in (`0700` on the home and `.ssh` directories, `0600` on `authorized_keys`).

## journald

Logs are persisted to disk (`/var/log/journal`) with a 512M cap, 64M per file, and a one-month retention ceiling.
