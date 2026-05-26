# Postgres

[Homepage](https://www.postgresql.org)

[GitHub](https://github.com/postgres/postgres)

> PostgreSQL is a powerful, open source object-relational database system with over 35 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.

Operate Postgres on your server with persistence on the host filesystem, scheduled wal-g base backups + WAL archiving, `postgres_exporter` metrics, and a Let's Encrypt TLS certificate auto-issued and renewed by [`lego`](https://go-acme.github.io/lego/) — including a short-lived IP certificate if you don't have a domain.

## Configuration

| Field | Description |
| ----- | ----------- |
| `domain_name` | Optional. Public domain resolving to this host. If unset, the public IPv4 is auto-detected via `ifconfig.co` and a short-lived IP certificate is issued instead. After your host autoregisters it will have a DNS record at `<host>.<org>.kheeper.app` that you can use. |
| `password` | Password for the `postgres` superuser. External clients connect over TLS as `postgres` with this password. Minimum 16 characters. |

## Launch on GCP

Connect your GCP project to your kheeper org (once per project):

```
ORG=<your-kheeper-org>
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get project) --format='value(projectNumber)')
kheeper clouds create my-gcp --org $ORG --project-number $PROJECT_NUMBER
```

Open the firewall rules Postgres needs. The image's host firewall opens `80/tcp` (ACME http-01 challenge) and `5432/tcp` (Postgres); the cloud-side firewall must match:

```
# 80 for ACME http-01 issuance and renewal
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --target-tags allow-http

# 5432 for Postgres clients
gcloud compute firewall-rules create allow-postgres \
    --allow tcp:5432 \
    --target-tags allow-postgres
```

Create the VM:

```
HOST=my-postgres
gcloud compute instances create $HOST \
    --image-family fedora-bootc --image-project kheeper \
    --zone us-central1-a \
    --machine-type c4-standard-2 \
    --boot-disk-size 40GB \
    --tags=allow-http,allow-postgres
```

The host auto-registers within a minute and gets a DNS A record at `$HOST.$ORG.kheeper.app` you can use for `domain_name`. Confirm:

```
kheeper hosts list --org $ORG
```

While the host is starting, configure your first release:

```
kheeper releases start config.json --image us.kheeper.com/public/postgres:v0.1.1
```

That writes a default `./config.json`. Set `password` and, if you have a domain, set `domain_name`; otherwise leave it empty and the image issues an IP certificate. Then create and activate the release:

```
kheeper releases create $ORG/$HOST:v1 \
    --image us.kheeper.com/public/postgres:v0.1.1 \
    --config-file config.json \
    --activate
```

`$ORG/$HOST:v1` is your release tag; `us.kheeper.com/public/postgres:v0.1.1` is the image it's built from.

## Alternative platforms

- [Bare metal](https://kheeper.com/docs/getting-started/boot-bare-metal) — register a physical host via iPXE
- [AWS](https://kheeper.com/docs/getting-started/boot-aws) — same flow as GCP using EC2 + a security group

In both cases, replicate the firewall section above on your cloud / network: `80/tcp` from anywhere for ACME and `5432/tcp` for Postgres clients.

## Connecting with certificate verification

Always connect with `sslmode=verify-full` so libpq verifies the cert chain *and* checks that the host you dialed matches a SAN in the cert. Anything weaker (`require`, `verify-ca`) leaves you open to MITM.

The certificate is issued by Let's Encrypt, so any client trust store that includes ISRG roots will validate it. With libpq 16+ you can point `sslrootcert` at the OS trust store:

```
psql "host=db.example.com user=postgres sslmode=verify-full sslrootcert=system"
```

For a host booted without a `domain_name` (IP certificate), pass the public IP as `host` — libpq compares it against the cert's IP SAN:

```
psql "host=1.2.3.4 user=postgres sslmode=verify-full sslrootcert=system"
```

If your client is on a system without a CA bundle, point `sslrootcert` at a copy of the [ISRG Root X1](https://letsencrypt.org/certs/isrgrootx1.pem) certificate instead of `system`.
