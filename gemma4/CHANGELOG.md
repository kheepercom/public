# Changelog

## v0.1.0

### Features

- `google/gemma-4-31B-it` weights baked into `/usr/share/gemma4/model/`
- vLLM (containerized via `docker.io/vllm/vllm-openai:v0.21.0`, pre-pulled into the bootc image's additional image store) serving an OpenAI-compatible API on `127.0.0.1:8000`
- NVIDIA driver via RPM Fusion `kmod-nvidia-open` (open variant), precompiled and pinned to the base image's kernel `7.0.8-200.fc44.x86_64`; `nvidia-persistenced` enabled
- `nvidia-container-toolkit` in CDI mode; one-shot `gemma4-cdi-init.service` generates `/etc/cdi/nvidia.yaml` from the host's actual GPU on first boot
- Podman quadlet `gemma4-vllm.container` runs vLLM with `AddDevice=nvidia.com/gpu=all` and the model bind-mounted read-only
- Caddy reverse proxy with automatic TLS via Let's Encrypt; `/v1/*` proxies to vLLM (with 10-minute read/write timeouts for long streaming completions), `/grafana/*` proxies to Grafana with sub-path config injected via a systemd drop-in
- Firewall opens `80/tcp` + `443/tcp` (Caddy/ACME + HTTPS)
- Bearer-token auth enforced by vLLM's `--api-key` from operator-supplied `api_key` (min 24 chars)
- vmsingle scrape config and Grafana dashboard for vLLM's Prometheus metrics: tokens/sec, time-to-first-token (p50/p95/p99), e2e latency (p50/p95/p99), active + queued requests, KV cache utilization, request failures
- vLLM compile/JIT caches persisted in `/var/lib/vllm` across reboots
