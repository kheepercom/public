# Changelog

## v0.1.7

### Changes

- Bump Pi-hole to 2026.07.2
- Rebuild on `base` v0.2.2

## v0.1.6

### Changes

- Rebuild on `base` v0.2.1

## v0.1.5

### Changes

- Rebuild on `base` v0.2.0

## v0.1.4

### Fixes

- Retry on failure when the container image pull fails at boot (e.g. transient DNS resolution)

## v0.1.3

### Fixes

- Run the container on a dual-stack Podman network so IPv6 DNS queries reach Pi-hole

## v0.1.2

### Changes

- Rebuild on `base` v0.1.2 (latest `fedora-bootc:44` digest)
- Bump Pi-hole to 2026.05.0

## v0.1.1

### Changes

- Rebuild on `base` v0.1.1 (latest `fedora-bootc:44` digest)

## v0.1.0

### Features

- Pi-hole v6 (`docker.io/pihole/pihole:2025.07.0`) running as a Podman Quadlet container with persistence at `/var/lib/pihole/`
- Caddy reverse proxy on the public domain with automatic TLS via Let's Encrypt fronts the admin UI
- Firewall opens `80/tcp` and `443/tcp` for ACME and HTTPS
- DNS port `53` (TCP+UDP) opened only to the source CIDRs configured in `dns_allowed_cidrs` (IPv4 or IPv6), applied at boot via `pihole-firewall.service`
- Admin password and upstream resolvers rendered from kheeper host config
