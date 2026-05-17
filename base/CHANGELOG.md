# Changelog

## v0.1.0

### Features

- `firewalld` enabled with a hardened default zone
- Unprivileged `admin` user with passwordless sudo
- sshd with pubkey-only auth and rate limits
- Persistent journald to `/var/log/journal` with a 512M cap and one month retention
