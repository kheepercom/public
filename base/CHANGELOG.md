# Changelog

## v0.1.2

### Changes

- Update base image to the latest `fedora-bootc:44` digest (`44.20260604.0`)

## v0.1.1

### Changes

- Update base image to the latest `fedora-bootc:44` digest

## v0.1.0

### Features

- `firewalld` enabled with a hardened default zone
- Unprivileged `admin` user with passwordless sudo
- sshd with pubkey-only auth and rate limits
- Persistent journald to `/var/log/journal` with a 512M cap and one month retention
