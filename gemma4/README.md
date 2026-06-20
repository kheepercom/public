# Gemma 4

[Homepage](https://ai.google.dev/gemma)

[Model card](https://huggingface.co/google/gemma-4-31B-it)

> Gemma 4 is Google's family of open-weight large language models. This image runs the 31B instruction-tuned variant on a single NVIDIA GPU as an OpenAI-compatible API.

The model weights ship as a separate logically bound image (`us.kheeper.com/public/gemma4-weights:v1.0.0`); bootc pulls it alongside the OS image but as independently-cached storage, and vLLM mounts it read-only at `/model`. vLLM serves the API on `127.0.0.1:8000`; [Caddy](https://caddyserver.com) terminates TLS on `:443` with automatic Let's Encrypt and reverse-proxies `/v1/*` to vLLM. A Grafana dashboard for token throughput, time-to-first-token, latency, and KV-cache utilization is available at `https://<domain>/grafana/`.

## Hardware requirements

- **NVIDIA GPU with ≥ 80 GB VRAM** for the 31B model in bf16 (Hopper H100/H200, Blackwell B200/RTX PRO 6000, or comparable). The image will not boot a usable vLLM on smaller GPUs without quantization.
- **≥ 96 GB system RAM.** vLLM memory-maps the 58 GB safetensors checkpoint during load; below ~80 GB RAM the page cache thrashes and first-inference latency explodes.
- **≥ 800 GB boot disk.** The bootc OS image itself is relatively small; the ~59 GB weights image is pulled separately into bootc storage (`/usr/lib/bootc/storage`). Size the disk for OS + weights plus bootc's headroom for in-place upgrades, which temporarily doubles on-disk usage.
- Linux/x86_64 host with NVIDIA GPU passthrough enabled (most cloud "GPU" instance types).

## Configuration

| Field | Description |
| ----- | ----------- |
| `base.admin_authorized_keys` | SSH public key(s), one per line. Required so you can `ssh admin@<host>` to debug or check logs while the model loads. Inherited from [`base`](../base). |
| `llm.domain` | Public domain resolving to this host. Used by Caddy for automatic TLS. After your host auto-registers it will have a DNS record at `<host>.<org>.us.kheeper.app` you can use. Inherited from [`llm-base`](../llm-base). |
| `llm.api_key` | Bearer token clients send as `Authorization: Bearer <api_key>`. Minimum 24 characters; generate with `openssl rand -hex 24`. **Rotation** requires editing `config.json` and restarting `llm-vllm.service`. Inherited from [`llm-base`](../llm-base). |
| `llm.max_model_len` | Optional, default 32768. vLLM context window in tokens. Gemma 4 31B-it caps at 131072 (128k). Inherited from [`llm-base`](../llm-base). |
| `llm.gpu_memory_utilization` | Optional, default 0.95. Fraction of GPU VRAM vLLM uses (0.5..0.98). Inherited from [`llm-base`](../llm-base). |

## Launch on GCP

Connect your GCP project to your kheeper org (once per project):

```
ORG=<your-kheeper-org>
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get project) --format='value(projectNumber)')
kheeper clouds create my-gcp --org $ORG --project-number $PROJECT_NUMBER
```

Open the firewall rules Gemma 4 needs. The image's host firewall opens `80/tcp` and `443/tcp` from anywhere; the cloud-side firewall must match:

```
gcloud compute firewall-rules create allow-https \
    --allow tcp:80,tcp:443 \
    --target-tags allow-https
```

GPU VMs need a non-zero **`GPUS_ALL_REGIONS`** quota for your project (separate from per-region GPU quotas; default is 0). Raise it in the GCP console — `gcloud` can't request quota changes.

Create the VM (Blackwell example):

```
HOST=my-gemma4
gcloud compute instances create $HOST \
    --image-family fedora-bootc --image-project kheeper \
    --zone us-central1-b \
    --machine-type g4-standard-48 \
    --accelerator count=1,type=nvidia-rtx-pro-6000 \
    --maintenance-policy TERMINATE --restart-on-failure \
    --boot-disk-size 800GB --boot-disk-type hyperdisk-balanced \
    --metadata=kheeper-region=us.kheeper.com \
    --tags allow-https
```

A few notes on the flags above. `g4-standard-48` gives the host 180 GB RAM, which comfortably fits the 58 GB safetensors checkpoint during load; smaller sizes in the g4 family work but trade away that headroom. `hyperdisk-balanced` is **required** by the g4 family — `pd-ssd` will be rejected. If you get `ZONE_RESOURCE_POOL_EXHAUSTED` (STOCKOUT), try another zone — `us-central1-f`, `us-west1-a/b/c`, `us-east1-d`, and `us-east4-b/c` all carry `nvidia-rtx-pro-6000`, but capacity varies. Two warnings from `gcloud` you can ignore: "boot disk size larger than image size" (Fedora bootc auto-grows the partition on first boot) and "creating a global DNS VM" (the image registers and is reached via public IP through Cloudflare/kheeper DNS).

The host auto-registers within a minute and gets a DNS A record at `$HOST.$ORG.us.kheeper.app` you can use for `domain`. Confirm:

```
kheeper hosts list --org $ORG
```

While the host is starting, configure your first release:

```
kheeper releases start config.json --image us.kheeper.com/public/gemma4:v0.2.3
```

That writes a default `./config.json` that you'll need to complete, looking something like this:

```json
{
  "base": {
    "admin_authorized_keys": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkJvX1Z3eDdaR0NvbW11bml0eTEyM0Zha2VLRXlTeHQ0bWc="
  },
  "llm": {
    "api_key": "Q2MhShrtODNw+B1fTHxRTExI",
    "domain": "my-gemma4.user-12345678.us.kheeper.app",
    "gpu_memory_utilization": 0.95,
    "max_model_len": 32768
  }
}
```

Then create and activate the release:

```
kheeper releases create $ORG/$HOST:v1 \
    --image us.kheeper.com/public/gemma4:v0.2.3 \
    --config-file config.json \
    --activate
```

`$ORG/$HOST:v1` is your release tag; `us.kheeper.com/public/gemma4:v0.2.3` is the image it's built from.

First boot takes roughly 40 minutes: ~25 min for bootc to pull the OS image plus the ~59 GB `gemma4-weights` image into its storage, ~10 min to deploy and soft-reboot, ~5 min for vLLM to load the model into VRAM. Wait until `kheeper releases list $ORG/$HOST` shows the release has been booted.

When `curl -sI https://$HOST.$ORG.us.kheeper.app/v1/models -H "Authorization: Bearer $API_KEY"` returns `HTTP/2 200`, the API is serving. Subsequent reboots are fast (the OS image and weights image are already in local bootc storage).


## Using the API

The endpoint speaks the OpenAI Chat Completions protocol:

```bash
curl -s https://<your-domain>/v1/chat/completions \
    -H "Authorization: Bearer <your-api-key>" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "google/gemma-4-31B-it",
        "messages": [{"role": "user", "content": "Say hello."}]
    }'
```

## Metrics

Grafana lives at `https://<your-domain>/grafana/` (default credentials `admin` / `admin`; Grafana forces a password change on first login). The bundled "vLLM" dashboard (inherited from [`llm-base`](../llm-base)) shows tokens/sec, time-to-first-token, end-to-end latency, active/queued requests, KV cache utilization, and request failure rate.

## Alternative platforms

- [Bare metal](https://kheeper.com/docs/getting-started/boot-bare-metal) — register a physical host via iPXE
- [AWS](https://kheeper.com/docs/guides/aws) — same flow as GCP using EC2 + a security group, with an NVIDIA-capable instance type (e.g. `p5.48xlarge`)
