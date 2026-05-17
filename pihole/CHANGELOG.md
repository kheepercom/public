# Changelog

## v0.1.0

### Features

- Pi-hole v6 (`docker.io/pihole/pihole:2025.07.0`) running as a Podman Quadlet container with persistence at `/var/lib/pihole/`
- Caddy reverse proxy on the public domain with automatic TLS via Let's Encrypt fronts the admin UI
- Firewall opens `80/tcp` and `443/tcp` for ACME and HTTPS
- DNS port `53` (TCP+UDP) opened only to the source CIDRs configured in `dns_allowed_cidrs` (IPv4 or IPv6), applied at boot via `pihole-firewall.service`
- Admin password and upstream resolvers rendered from kheeper host config
