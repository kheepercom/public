# Pi-hole

[Homepage](https://pi-hole.net)

[GitHub](https://github.com/pi-hole/pi-hole)

> Pi-hole is a network-wide ad-blocker that acts as a DNS sinkhole, optionally a DHCP server, intended for use on a private network.

Operate Pi-hole on your server with persistence on the host filesystem and automatic TLS for the admin UI provided by [Caddy](https://caddyserver.com).

## Configuration

| Field | Description |
| ----- | ----------- |
| `domain` | Public domain resolving to this host. Used by Caddy for automatic TLS on the admin UI. After your host autoregisters it will have a DNS record for <host>.<org>.kheeper.app that you can use. |
| `admin_password` | Password for the Pi-hole admin web UI. Minimum 8 characters. |
| `dns_allowed_cidrs` | Source CIDRs allowed to query DNS on port 53. IPv4 and IPv6 are both supported. **Pi-hole MUST NOT be exposed as an open resolver** — list only the networks (e.g., your IP address or VPN subnet) that should be able to send DNS queries. |
| `upstream_dns` | Optional. Upstream DNS resolvers Pi-hole forwards to. Defaults to `1.1.1.1` and `9.9.9.9`. |

## Launch on GCP

Connect your GCP project to your kheeper org (once per project):

```
ORG=<your-kheeper-org>
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get project) --format='value(projectNumber)')
kheeper clouds create my-gcp --org $ORG --project-number $PROJECT_NUMBER
```

Open the firewall rules Pi-hole needs. The image's host firewall (`firewalld`) opens `80/tcp` and `443/tcp` from anywhere and `53/tcp` + `53/udp` only from the CIDRs in `dns_allowed_cidrs`. The cloud-side firewall must match:

```
# 80/443 for ACME and the admin UI
gcloud compute firewall-rules create allow-https \
    --allow tcp:80,tcp:443 \
    --target-tags allow-https

# 53/tcp+udp scoped to the same CIDRs you'll put in dns_allowed_cidrs
gcloud compute firewall-rules create allow-pihole-dns \
    --allow tcp:53,udp:53 \
    --source-ranges <comma-separated IPv4 CIDRs from dns_allowed_cidrs> \
    --target-tags allow-pihole-dns
```

Keep the cloud-firewall source list in sync with `dns_allowed_cidrs` so Pi-hole never accepts queries from an unintended network.

Create the VM:

```
HOST=my-pihole
gcloud compute instances create $HOST \
    --image-family fedora-bootc --image-project kheeper \
    --zone us-central1-a \
    --machine-type c4-standard-2 \
    --boot-disk-size 40GB \
    --metadata=kheeper-region=us.kheeper.com \
    --tags=allow-https,allow-pihole-dns
```

The host auto-registers within a minute and gets a DNS A record at `$HOST.$ORG.kheeper.app` you can use for `domain`. Confirm:

```
kheeper hosts list --org $ORG
```

While the host is starting, configure your first release:

```
kheeper releases start config.json --image us.kheeper.com/public/pihole:v0.1.6
```

That writes a default `./config.json`. Edit it so `domain` matches your DNS record, set `admin_password`, and list at least one CIDR in `dns_allowed_cidrs`. Then create and activate the release:

```
kheeper releases create $ORG/$HOST:v1 \
    --image us.kheeper.com/public/pihole:v0.1.6 \
    --config-file config.json \
    --activate
```

`$ORG/$HOST:v1` is your release tag; `us.kheeper.com/public/pihole:v0.1.6` is the image it's built from.

## Alternative platforms

- [Bare metal](https://kheeper.com/docs/getting-started/boot-bare-metal) — register a physical host via iPXE
- [AWS](https://kheeper.com/docs/getting-started/boot-aws) — same flow as GCP using EC2 + a security group

In both cases, replicate the firewall section above on your cloud / network: `80/443` from anywhere and `53/tcp+udp` scoped to `dns_allowed_cidrs`.

## IPv6

If `dns_allowed_cidrs` includes IPv6 entries, the host VM must have an IPv6 address (use a dual-stack subnet — GCP's default subnet is IPv4-only) and the cloud firewall needs a second rule for the v6 sources. GCP rejects mixing v4 and v6 in one rule:

```
gcloud compute firewall-rules create allow-pihole-dns-v6 \
    --allow tcp:53,udp:53 \
    --source-ranges <comma-separated IPv6 CIDRs from dns_allowed_cidrs> \
    --target-tags allow-pihole-dns-v6
```

Add `allow-pihole-dns-v6` to the VM's `--tags` so the instance opts into this rule alongside `allow-https` and `allow-pihole-dns`.
