# Changelog

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
