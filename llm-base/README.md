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

Inherits `22/tcp` from [`base`](../base). Opens `80/tcp` (Caddy ACME HTTP challenge) and `443/tcp` (HTTPS). vLLM and Grafana stay on `127.0.0.1`; Caddy reverse-proxies `/v1/*` to vLLM and `/grafana/*` to Grafana.

## Layering on this image

vLLM itself is a logically bound image here — bootc pulls it into `/usr/lib/bootc/storage` rather than a pre-pulled additional store, and the vLLM quadlet carries `--storage-opt additionalimagestore=/usr/lib/bootc/storage` so podman resolves both the vLLM image and the leaf's weights image from bootc's store.

A leaf image binds a weights image (built `FROM scratch`, model files at its root), mounts it into vLLM, and declares which model name vLLM advertises:

```Containerfile
FROM us.kheeper.com/public/llm-base:v0.2.1

# Model weights as a logically bound image, pulled by bootc separately from
# the OS image (only re-pulled when the weights tag changes).
COPY llm-model.image /usr/share/containers/systemd/llm-model.image
RUN install -d -m 0755 /usr/lib/bootc/bound-images.d \
	&& ln -s ../../../share/containers/systemd/llm-model.image \
		/usr/lib/bootc/bound-images.d/llm-model.image

# Mount the weights image read-only into the vLLM container at /model.
COPY 10-model.conf /usr/share/containers/systemd/llm-vllm.container.d/10-model.conf

# Static env: the model name vLLM advertises on /v1/models.
COPY llm-vllm-model.env /etc/kheeper/llm-vllm-model.env

RUN bootc container lint
```

`llm-model.image` declares the weights LBI:

```ini
[Image]
Image=us.kheeper.com/public/<model>-weights:v1.0.0
```

`10-model.conf` mounts it (the image rootfs lands at `/model`):

```ini
[Container]
Mount=type=image,source=us.kheeper.com/public/<model>-weights:v1.0.0,destination=/model,readwrite=false
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
- Podman quadlet `llm-vllm.container` runs vLLM with `AddDevice=nvidia.com/gpu=all` and `--storage-opt additionalimagestore=/usr/lib/bootc/storage` so podman resolves the vLLM and weights images from bootc's store; the model is supplied by a leaf via a `llm-vllm.container.d` drop-in mounting a weights image at `/model`
- Caddy reverse proxy with automatic TLS via Let's Encrypt; 10-minute read/write timeouts on `/v1/*` for long streaming completions; `/grafana/*` proxied with sub-path config injected via a systemd drop-in
- Firewall opens `80/tcp` + `443/tcp`
- vmsingle scrape config and Grafana dashboard for vLLM's Prometheus metrics: tokens/sec, time-to-first-token (p50/p95/p99), e2e latency (p50/p95/p99), active + queued requests, KV cache utilization, request failures
- vLLM compile/JIT caches persisted in `/var/lib/vllm` across reboots

## Metrics

A scrape config at `/etc/victoria-metrics/scrape.d/llm.json` registers vLLM with the local vmsingle from [`metrics-base`](../metrics-base). The bundled "vLLM" dashboard at `/etc/grafana/dashboards/llm.json` queries are model-agnostic (`job="vllm"`), so any leaf gets the dashboard for free.
