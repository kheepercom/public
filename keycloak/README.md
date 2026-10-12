# Keycloak

[Homepage](https://www.keycloak.org)

[GitHub](https://github.com/keycloak/keycloak)

> Open Source Identity and Access Management for Modern Applications and Services.

Run your own identity provider, with OIDC, SAML, LDAP/AD federation, MFA,
passkeys and social login. State lives in a local Postgres and TLS comes from
[Caddy](https://caddyserver.com).

This is a [sealed image](https://kheeper.com/docs/guides/sealed-images): it is
built for bootc's composefs backend and there is no ostree version. It runs
only on a host installed with `--composefs`, which today means bare metal
over iPXE.

## Configuration

| Field | Description |
| ----- | ----------- |
| `domain` | Public domain resolving to this host. Used by Caddy for automatic TLS and as Keycloak's hostname. After your host autoregisters it will have a DNS record at `<host>.<org>.kheeper.app` that you can use. |
| `admin_password` | Password for the temporary `admin` user in the master realm, created on first boot. Minimum 12 characters. Changing it after first boot does nothing. |

Keycloak marks the bootstrap `admin` as temporary. Sign in at
`https://<domain>/admin`, create a permanent admin, and delete `admin`.

## Launch on bare metal

Follow the [sealed images guide](https://kheeper.com/docs/guides/sealed-images)
to create your org's Secure Boot keys and install a composefs host:

```
ORG=<your-kheeper-org>
HOST=my-keycloak
kheeper hosts ipxe create $ORG/$HOST --composefs
```

Open `80/tcp` and `443/tcp` to the host on your network.

Configure your first release:

```
kheeper releases start config.json --image us.kheeper.com/public/keycloak:v0.1.0
```

That writes a default `./config.json`. Edit it so `domain` matches your DNS
record and set `admin_password`. Then create a sealed release and activate it:

```
kheeper releases create $ORG/$HOST:v1 \
    --image us.kheeper.com/public/keycloak:v0.1.0 \
    --config-file config.json \
    --seal --activate
```

## What's inside

- Keycloak in `/usr/lib/keycloak`, pre-built for Postgres with health and
  metrics enabled, started with `--optimized`. Its data directory is
  `/var/lib/keycloak`
- Single-node `local` cache: no clustering, nothing listening beyond loopback
  except Caddy
- `keycloak-init.service` gives the `keycloak` Postgres role a random password
  at first boot and stores it in `/var/lib/keycloak/db.env`. Postgres listens
  on `localhost` because JDBC can't use the unix socket
- WAL archiving and daily base backups from [`postgres-base`](../postgres-base)
- Health and metrics on the management interface at `127.0.0.1:9000`, scraped
  by the local vmsingle. User event metrics count logins and failures per
  realm
- A `Keycloak Overview` Grafana dashboard: logins and failures by realm,
  request rate and latency, database pool, JVM heap, CPU and GC
