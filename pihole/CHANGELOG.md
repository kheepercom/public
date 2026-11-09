# Changelog

## v0.4.1

### Changes

- Rebuild on `base` v0.4.1 (new `fedora-bootc:45` digest)

### Fixes

- Disable Caddy's admin endpoint. Fedora 45's SELinux policy denies
  `httpd_t` binding port 2019, so Caddy exited at startup after a full boot

## v0.4.0

### Changes

- Rebuild on `base` v0.4.0 (new `fedora-bootc:45` digest)

## v0.3.1

### Changes

- Rebuild on `base` v0.3.1

## v0.3.0

### Changes

- Rebuild on `base` v0.3.0 (Fedora 45)

## v0.2.1

### Fixes

- Restore SELinux labels under `/var/lib/caddy` at boot. Files labeled
  `var_lib_t` instead of `httpd_var_lib_t` keep Caddy from saving renewed
  certificates, so they silently expire

## v0.2.0

### Changes

- Bump Pi-hole to 2026.10.0 (from 2026.07.2). Security releases covering RCE,
  privilege escalation and DNS denial-of-service advisories.
  `misc.dnsmasq_lines` and `webserver.advancedOpts` can no longer be set
  through the API or web UI; this image sets neither
- Rebuild on `base` v0.2.7

## v0.1.11

### Changes

- Rebuild on `base` v0.2.6

## v0.1.10

### Changes

- Rebuild on `base` v0.2.5

## v0.1.9

### Changes

- Rebuild on `base` v0.2.4

## v0.1.8

### Changes

- Rebuild on `base` v0.2.3

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
