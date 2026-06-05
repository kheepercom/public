# DeepSeek 4 Flash

[Homepage](https://www.deepseek.com/)

[Model card](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash)

> DeepSeek V4 Flash is the latency-optimized variant of DeepSeek's V4 series of open-weight large language models. This image runs it on a single NVIDIA GPU as an OpenAI-compatible API.

The model weights ship as a separate logically bound image (`us.kheeper.com/public/deepseek4-weights:v1.0.0`); bootc pulls it alongside the OS image but as independently-cached storage, and vLLM mounts it read-only at `/model`. vLLM serves the API on `127.0.0.1:8000`; [Caddy](https://caddyserver.com) terminates TLS on `:443` with automatic Let's Encrypt and reverse-proxies `/v1/*` to vLLM. A Grafana dashboard for token throughput, time-to-first-token, latency, and KV-cache utilization is available at `https://<domain>/grafana/`.

## Hardware requirements

- **NVIDIA GPU with ≥ 48 GB VRAM** (L40S, A100 40/80 GB, H100, RTX PRO 6000, or comparable). The image will not boot a usable vLLM on smaller GPUs without quantization.
- **≥ 180 GB system RAM.** vLLM memory-maps the safetensors checkpoint during load; below a comfortable margin the page cache thrashes and first-inference latency explodes.
- **≥ 1500 GB boot disk.** The bootc OS image itself is small now; the weights image is pulled separately into bootc storage (`/usr/lib/bootc/storage`). Size the disk for OS + weights plus bootc's headroom for in-place upgrades, which temporarily doubles on-disk usage.
- Linux/x86_64 host with NVIDIA GPU passthrough enabled (most cloud "GPU" instance types).

## Configuration

| Field | Description |
| ----- | ----------- |
| `base.admin_authorized_keys` | SSH public key(s), one per line. Required so you can `ssh admin@<host>` to debug or check logs while the model loads. Inherited from [`base`](../base). |
| `llm.domain` | Public domain resolving to this host. Used by Caddy for automatic TLS. After your host auto-registers it will have a DNS record at `<host>.<org>.kheeper.app` you can use. Inherited from [`llm-base`](../llm-base). |
| `llm.api_key` | Bearer token clients send as `Authorization: Bearer <api_key>`. Minimum 24 characters; generate with `openssl rand -hex 24`. **Rotation** requires editing `config.json` and restarting `llm-vllm.service`. Inherited from [`llm-base`](../llm-base). |
| `llm.max_model_len` | Optional, default 32768. vLLM context window in tokens. Inherited from [`llm-base`](../llm-base). |
| `llm.gpu_memory_utilization` | Optional, default 0.95. Fraction of GPU VRAM vLLM uses (0.5..0.98). Inherited from [`llm-base`](../llm-base). |

## Launch on GCP

Connect your GCP project to your kheeper org (once per project):

```
ORG=<your-kheeper-org>
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get project) --format='value(projectNumber)')
kheeper clouds create my-gcp --org $ORG --project-number $PROJECT_NUMBER
```

Open the firewall rules DeepSeek 4 needs. The image's host firewall opens `80/tcp` and `443/tcp` from anywhere; the cloud-side firewall must match:

```
gcloud compute firewall-rules create allow-https \
    --allow tcp:80,tcp:443 \
    --target-tags allow-https
```

GPU VMs need a non-zero **`GPUS_ALL_REGIONS`** quota for your project (separate from per-region GPU quotas; default is 0). Raise it in the GCP console — `gcloud` can't request quota changes.

Create the VM (Blackwell example):

```
HOST=my-deepseek4
gcloud compute instances create $HOST \
    --image-family fedora-bootc --image-project kheeper \
    --zone us-central1-a \
    --machine-type g4-standard-48 \
    --accelerator count=1,type=nvidia-rtx-pro-6000 \
    --maintenance-policy TERMINATE --restart-on-failure \
    --boot-disk-size 1500GB --boot-disk-type hyperdisk-balanced \
    --tags allow-https
```

A few notes on the flags above. `g4-standard-48` gives the host 180 GB RAM, which is the minimum for the checkpoint to memory-map cleanly during load — don't go smaller in the g4 family. `hyperdisk-balanced` is **required** by the g4 family — `pd-ssd` will be rejected. If you get `ZONE_RESOURCE_POOL_EXHAUSTED` (STOCKOUT), try another zone — `us-central1-f`, `us-west1-a/b/c`, `us-east1-d`, and `us-east4-b/c` all carry `nvidia-rtx-pro-6000`, but capacity rotates. Two warnings from `gcloud` you can ignore: "boot disk size larger than image size" (Fedora bootc auto-grows the partition on first boot) and "creating a global DNS VM" (the image registers and is reached via public IP through Cloudflare/kheeper DNS).

The host auto-registers within a minute and gets a DNS A record at `$HOST.$ORG.kheeper.app` you can use for `domain`. Confirm:

```
kheeper hosts list --org $ORG
```

While the host is starting, configure your first release:

```
kheeper releases start config.json --image us.kheeper.com/public/deepseek4:v0.2.2
```

That writes a default `./config.json`. Fill in the three required fields — your SSH public key, the host's DNS record, and a fresh API key — and save the key somewhere you'll remember (you'll need it for every API call):

```
API_KEY=$(openssl rand -hex 24)
echo "API_KEY=$API_KEY"   # write this down

jq --arg keys "$(cat ~/.ssh/id_ed25519.pub)" \
   --arg domain "$HOST.$ORG.kheeper.app" \
   --arg api_key "$API_KEY" \
   '.base.admin_authorized_keys=$keys
    | .llm.domain=$domain
    | .llm.api_key=$api_key' \
   config.json > config.json.tmp && mv config.json.tmp config.json
```

Then create and activate the release:

```
kheeper releases create $ORG/$HOST:v1 \
    --image us.kheeper.com/public/deepseek4:v0.2.2 \
    --config-file config.json \
    --activate
```

`$ORG/$HOST:v1` is your release tag; `us.kheeper.com/public/deepseek4:v0.2.2` is the image it's built from.

First boot is dominated by the image pull and vLLM's first model load into VRAM. You can watch progress over SSH:

```
ssh admin@$HOST.$ORG.kheeper.app sudo journalctl -fu kheeper-upgrade -u llm-vllm
```

When `curl -sI https://$HOST.$ORG.kheeper.app/v1/models -H "Authorization: Bearer $API_KEY"` returns `HTTP/2 200`, the API is serving. Subsequent reboots are fast (the OS image and weights image are already in local bootc storage).

## Alternative platforms

- [Bare metal](https://kheeper.com/docs/getting-started/boot-bare-metal) — register a physical host via iPXE
- [AWS](https://kheeper.com/docs/getting-started/boot-aws) — same flow as GCP using EC2 + a security group, with an NVIDIA-capable instance type (e.g. `p5.48xlarge`)

In both cases, replicate the firewall section above: `80/tcp` + `443/tcp` from anywhere.

## Using the API

The endpoint speaks the OpenAI Chat Completions protocol:

```bash
curl -s https://<your-domain>/v1/chat/completions \
    -H "Authorization: Bearer <your-api-key>" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "deepseek-ai/DeepSeek-V4-Flash",
        "messages": [{"role": "user", "content": "Say hello."}]
    }'
```

From Python:

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://<your-domain>/v1",
    api_key="<your-api-key>",
)
print(client.chat.completions.create(
    model="deepseek-ai/DeepSeek-V4-Flash",
    messages=[{"role": "user", "content": "Say hello."}],
).choices[0].message.content)
```

## Browser chat UI

For a ChatGPT-style web interface, [Open WebUI](https://github.com/open-webui/open-webui) takes any OpenAI-compatible endpoint as a backend. One Docker command on your laptop:

```bash
docker run -d -p 3000:8080 \
    -e OPENAI_API_BASE_URL=https://<your-domain>/v1 \
    -e OPENAI_API_KEY=<your-api-key> \
    -v open-webui:/app/backend/data \
    --name open-webui \
    ghcr.io/open-webui/open-webui:main
```

Then open <http://localhost:3000>, create the local admin account (Open WebUI's own login — separate from the kheeper image), and `deepseek-ai/DeepSeek-V4-Flash` shows up in the model picker.

## Metrics

Grafana lives at `https://<your-domain>/grafana/` (default credentials `admin` / `admin`; Grafana forces a password change on first login). The bundled "vLLM" dashboard (inherited from [`llm-base`](../llm-base)) shows tokens/sec, time-to-first-token, end-to-end latency, active/queued requests, KV cache utilization, and request failure rate.
