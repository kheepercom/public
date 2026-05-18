# Changelog

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
