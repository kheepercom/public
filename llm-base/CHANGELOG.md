# Changelog

## v0.4.0

### Changes

- Bump vLLM to v0.28.0 (from v0.22.0)
- Bump Open WebUI to v0.11.1 (from v0.9.6)
- Pin `KERNEL_VERSION` to 7.1.10-200.fc44.x86_64, the kernel shipped by
  `base` v0.2.2. The open NVIDIA kmod is compiled against this version at
  build time, so it has to track the base layer
- Rebuild on `metrics-base` v0.3.0 (Grafana 13)

### Notes

- The NVIDIA driver stays pinned at 595.58.03. RPM Fusion has 610.57.04, but
  it ships no `akmod-nvidia-open` — only the unified `akmod-nvidia` — so the
  `akmods --kmod nvidia-open` build here has no source to compile. See
  MAINTAINERS.md

## v0.3.3

### Changes

- Rebuild on `metrics-base` v0.2.1

## v0.3.2

### Changes

- Rebuild on `metrics-base` v0.2.0

## v0.3.1

### Fixes

- Open WebUI base URL now includes `/v1` so the model dropdown discovers vLLM's models

## v0.3.0

### Features

- Built-in [Open WebUI](https://github.com/open-webui/open-webui) chat interface at `https://<domain>/`, proxied by Caddy; data persisted in `/var/lib/open-webui`

### Changes

- Model weights are now bind-mounted from the filesystem instead of using podman's `Mount=type=image` (works around a bootc/podman interop bug where `additionalimagestore` layers can't be mounted)
- New `llm-model-link.service` resolves the leaf's bound weights image to `/var/lib/llm-model` at boot by symlinking to the unpacked layer in bootc's store — no data copy
- Fix vLLM container image version: `.container` now references v0.22.0 to match the `.image` bound-image declaration

### Breaking

- Leaf images no longer supply a `llm-vllm.container.d/10-model.conf` drop-in; the base image bind-mounts `/var/lib/llm-model` at `/model` directly. Remove the `10-model.conf` COPY from leaf Containerfiles.

## v0.2.1

### Changes

- Rebuild on `metrics-base` v0.1.2 (latest `fedora-bootc:44` digest)
- Bump pinned kernel to `7.0.10-201.fc44.x86_64` to match the new base digest
- Bump vLLM bound image to `docker.io/vllm/vllm-openai:v0.22.0`
- NVIDIA open driver held at `595.58.03` — newest RPM Fusion F44 build with a matching `akmod-nvidia-open`

## v0.2.0

### Changed

- vLLM container is now a logically bound image (`docker.io/vllm/vllm-openai:v0.21.0`) pulled by bootc into `/usr/lib/bootc/storage`, replacing the build-time skopeo pre-pull and the baked `/usr/lib/containers/storage` additional store.
- `llm-vllm.container` no longer mounts a model path; leaf images now supply `/model` via a drop-in. The vLLM quadlet scopes bootc's LBI store with a per-container `--storage-opt additionalimagestore=/usr/lib/bootc/storage` instead of a host-wide `containers-storage.conf`.

### Breaking

- Leaf images must build `FROM llm-base:v0.2.0` and supply both the model weights (as a bound `*-weights` image) and a `llm-vllm.container.d/10-model.conf` drop-in mounting it at `/model`. See [`gemma4`](../gemma4) for the reference layering.

## v0.1.0

### Features

- NVIDIA open driver via RPM Fusion `akmod-nvidia-open`, precompiled at image-build time against the kernel pinned in `base`; nouveau blocked via `kargs.d` + `modprobe.d`; `nvidia-persistenced` enabled
- `nvidia-container-toolkit` in CDI mode; one-shot `llm-cdi-init.service` generates `/etc/cdi/nvidia.yaml` from the host's actual GPU on first boot
- `docker.io/vllm/vllm-openai:v0.21.0` pre-pulled into a `/usr/lib/containers/storage` additional image store
- Podman quadlet `llm-vllm.container` runs vLLM on `127.0.0.1:8000`, model bind-mounted read-only from `/usr/share/llm/model`, served-model-name + tunables driven by env files so leaf images only bake weights; `VLLM_EXTRA_ARGS` escape hatch in the env file passes through extra model-specific flags
- Caddy reverse proxy with automatic TLS via Let's Encrypt; `/v1/*` → vLLM (10-min read/write timeouts), `/grafana/*` → Grafana with sub-path drop-in
- Firewall opens `80/tcp` + `443/tcp` (Caddy/ACME + HTTPS)
- Bearer-token auth enforced by vLLM's `--api-key` from operator-supplied `api_key` (min 24 chars)
- Shared `.llm` config schema (`domain`, `api_key`, `max_model_len`, `gpu_memory_utilization`) at `/etc/kheeper/schema.d/llm.json`
- vmsingle scrape config + Grafana dashboard for vLLM's Prometheus metrics (model-agnostic `job="vllm"`)
- vLLM compile/JIT caches persisted in `/var/lib/vllm` across reboots
