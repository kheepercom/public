# Changelog

## v0.1.0

### Features

- Keycloak 26.8.0 on OpenJDK 25, built for bootc's composefs backend so it
  can be released with `--seal`. There is no ostree version
- Local Postgres from `postgres-base` v0.5.4. Keycloak connects over
  loopback with a password generated on the host at first boot
- Caddy reverse proxy with automatic TLS via Let's Encrypt
- Firewall opens `80/tcp` and `443/tcp` for ACME and HTTPS
- Temporary `admin` user in the master realm from `admin_password`
- vmsingle scrape config for Keycloak metrics on `127.0.0.1:9000`, with user
  event metrics and HTTP latency histograms enabled
- `Keycloak Overview` Grafana dashboard: logins and failures by realm, request
  rate and latency, database pool, JVM heap, CPU and GC
