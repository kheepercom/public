# OpenFGA

[Homepage](https://openfga.dev)

[GitHub](https://github.com/openfga/openfga)

> OpenFGA is an open-source authorization solution that allows developers to build granular access control using an easy-to-read modeling language and friendly APIs.

Operate OpenFGA on your server with persistence in a local Postgres and automatic TLS provided by [Caddy](https://caddyserver.com).

## Configuration

| Field | Description |
| ----- | ----------- |
| `domain` | Public domain resolving to this host. Used by Caddy for automatic TLS. After your host autoregisters it will have a DNS record at `<host>.<org>.kheeper.app` that you can use. |
| `key` | Preshared API key. Clients authenticate by sending `Authorization: Bearer <key>`. Minimum 16 characters. |

## Launch on GCP

Connect your GCP project to your kheeper org (once per project):

```
ORG=<your-kheeper-org>
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get project) --format='value(projectNumber)')
kheeper clouds create my-gcp --org $ORG --project-number $PROJECT_NUMBER
```

Open the firewall rules OpenFGA needs. The image's host firewall opens `80/tcp` and `443/tcp` from anywhere; the cloud-side firewall must match:

```
# 80/443 for ACME and the OpenFGA HTTPS API
gcloud compute firewall-rules create allow-https \
    --allow tcp:80,tcp:443 \
    --target-tags allow-https
```

Create the VM:

```
HOST=my-openfga
gcloud compute instances create $HOST \
    --image-family fedora-bootc --image-project kheeper \
    --zone us-central1-a \
    --machine-type c4-standard-2 \
    --boot-disk-size 40GB \
    --metadata=kheeper-region=us.kheeper.com \
    --tags=allow-https
```

The host auto-registers within a minute and gets a DNS A record at `$HOST.$ORG.kheeper.app` you can use for `domain`. Confirm:

```
kheeper hosts list --org $ORG
```

While the host is starting, configure your first release:

```
kheeper releases start config.json --image us.kheeper.com/public/openfga:v0.3.0
```

That writes a default `./config.json`. Edit it so `domain` matches your DNS record and set `key` to a strong preshared secret. Then create and activate the release:

```
kheeper releases create $ORG/$HOST:v1 \
    --image us.kheeper.com/public/openfga:v0.3.0 \
    --config-file config.json \
    --activate
```

`$ORG/$HOST:v1` is your release tag; `us.kheeper.com/public/openfga:v0.3.0` is the image it's built from.

## Alternative platforms

- [Bare metal](https://kheeper.com/docs/getting-started/boot-bare-metal) — register a physical host via iPXE
- [AWS](https://kheeper.com/docs/getting-started/boot-aws) — same flow as GCP using EC2 + a security group

In both cases, replicate the firewall section above on your cloud / network: `80/443` from anywhere.
