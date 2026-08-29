# llm-base

`us.kheeper.com/public/llm-base` — [`metrics-base`](../metrics-base) plus everything needed to serve a single LLM as an OpenAI-compatible HTTPS API on a GPU host: NVIDIA open driver, NVIDIA Container Toolkit, a [vLLM](https://docs.vllm.ai) container bound by bootc, [Caddy](https://caddyserver.com) for TLS, and a Grafana dashboard wired into the [`metrics-base`](../metrics-base) stack.

This image is meant to be layered, not booted directly. Leaf images supply the model weights and the served-model-name; everything else is here. See [`gemma4`](../gemma4) for the reference layering.

## Configuration

Inherits `admin_authorized_keys` from [`base`](../base). Adds the `.llm` config block, shared across every leaf built on this image:

| Field | Description |
| ----- | ----------- |
| `domain` | Public domain resolving to this host. Used by Caddy for automatic TLS and as the externally-visible URL for the OpenAI-compatible API. |
| `api_key` | Bearer token clients send as `Authorization: Bearer <api_key>`. Minimum 24 chars; generate with `openssl rand -hex 24`. Rotation requires editing `config.json` and restarting `llm-vllm.service`. |
| `max_model_len` | Optional, default 32768. vLLM context window in tokens. The model's true maximum is determined by the leaf image. |
| `gpu_memory_utilization` | Optional, default 0.95. Fraction of GPU VRAM vLLM uses (0.5..0.98). |

## Ports

Inherits `22/tcp` from [`base`](../base). Opens `80/tcp` (Caddy ACME HTTP challenge) and `443/tcp` (HTTPS). vLLM, Open WebUI, and Grafana stay on `127.0.0.1`; Caddy reverse-proxies `/v1/*` to vLLM, `/grafana/*` to Grafana, and `/` to Open WebUI.

## Layering on this image

vLLM itself is a logically bound image — bootc pulls it into `/usr/lib/bootc/storage`. Model weights are also bound images; at boot, `llm-model-link.service` resolves the leaf's weights image to its unpacked layer in bootc's store and symlinks `/var/lib/llm-model` to it. The vLLM container bind-mounts that path at `/model`.

A leaf image binds a weights image (built `FROM scratch`, model files at its root) and declares which model name vLLM advertises:

```Containerfile
FROM us.kheeper.com/public/llm-base:v0.4.0

# Model weights as a logically bound image, pulled by bootc separately from
# the OS image (only re-pulled when the weights tag changes).
COPY llm-model.image /usr/share/containers/systemd/llm-model.image
RUN install -d -m 0755 /usr/lib/bootc/bound-images.d \
	&& ln -s ../../../share/containers/systemd/llm-model.image \
		/usr/lib/bootc/bound-images.d/llm-model.image

# Static env: the model name vLLM advertises on /v1/models.
COPY llm-vllm-model.env /etc/kheeper/llm-vllm-model.env

RUN bootc container lint
```

`llm-model.image` declares the weights LBI:

```ini
[Image]
Image=us.kheeper.com/public/<model>-weights:v1.0.0
```

`llm-vllm-model.env` must set at least:

```
VLLM_SERVED_MODEL_NAME=<org>/<model-id>
```

Optionally set `VLLM_EXTRA_ARGS` to inject model-specific flags into vLLM's command line (e.g. `--trust-remote-code`, `--kv-cache-dtype fp8`, custom parsers). The variable is appended to the base `Exec=` and word-split by systemd, so multiple flags separated by whitespace work as expected:

```
VLLM_EXTRA_ARGS=--trust-remote-code --kv-cache-dtype fp8
```

## What's inside

- NVIDIA open driver via RPM Fusion `akmod-nvidia-open`, built at image-build time against the kernel pinned in [`base`](../base); `nvidia-persistenced` enabled
- `nvidia-container-toolkit` in CDI mode; one-shot `llm-cdi-init.service` generates `/etc/cdi/nvidia.yaml` from the host's actual GPU on first boot
- vLLM (`docker.io/vllm/vllm-openai`) as a logically bound image, pulled by bootc into `/usr/lib/bootc/storage` alongside the OS image — no build-time skopeo, no baked-in additional image store
- `llm-model-link.service` resolves the leaf's bound weights image to `/var/lib/llm-model` at boot by reading bootc's store metadata and symlinking to the unpacked layer — no data copy, no `additionalimagestore` mount
- Podman quadlet `llm-vllm.container` runs vLLM with `AddDevice=nvidia.com/gpu=all`; model weights bind-mounted read-only from `/var/lib/llm-model` at `/model`
- [Open WebUI](https://github.com/open-webui/open-webui) (`ghcr.io/open-webui/open-webui`) as a bound image; provides a ChatGPT-style browser UI at `https://<domain>/` with its own login system (first visitor creates the admin account); data persisted in `/var/lib/open-webui`
- Caddy reverse proxy with automatic TLS via Let's Encrypt; `/v1/*` → vLLM (10-minute read/write timeouts), `/grafana/*` → Grafana, `/` → Open WebUI
- Firewall opens `80/tcp` + `443/tcp`
- vmsingle scrape config and Grafana dashboard for vLLM's Prometheus metrics: tokens/sec, time-to-first-token (p50/p95/p99), e2e latency (p50/p95/p99), active + queued requests, KV cache utilization, request failures
- vLLM compile/JIT caches persisted in `/var/lib/vllm` across reboots

## Metrics

A scrape config at `/etc/victoria-metrics/scrape.d/llm.json` registers vLLM with the local vmsingle from [`metrics-base`](../metrics-base). The bundled "vLLM" dashboard at `/etc/grafana/dashboards/llm.json` queries are model-agnostic (`job="vllm"`), so any leaf gets the dashboard for free.
