# Changelog

## v0.2.2

### Bug Fixes

- Fixed tag of the weight image

## v0.2.1

### Changes

- Rebuild on `llm-base` v0.2.1 (latest base digest, kernel `7.0.10-201`, vLLM v0.22.0)

## v0.2.0

### Changed

- `deepseek-ai/DeepSeek-V4-Flash` weights now ship as a logically bound image (`kheeper.com/public/deepseek4-weights:v1.0.0`) instead of being baked into the OS image. bootc pulls it separately into `/usr/lib/bootc/storage`; OS rebuilds no longer re-pull the weight layer.
- vLLM mounts the weights read-only at `/model` via a quadlet drop-in.
- Builds on [`llm-base`](../llm-base) v0.2.0.

## v0.1.0

### Features

- `deepseek-ai/DeepSeek-V4-Flash` weights baked into `/usr/share/llm/model/`
- vLLM tuned for DeepSeek V4 via `VLLM_EXTRA_ARGS`: `--kv-cache-dtype fp8` (halves KV cache memory), `--enable-chunked-prefill`, `--block-size 256`, `--trust-remote-code`, and DeepSeek-specific `--tokenizer-mode`, `--tool-call-parser`, and `--reasoning-parser` parsers
- vLLM serving stack, NVIDIA driver/CDI wiring, Caddy TLS, and Grafana dashboard inherited from `kheeper.com/public/llm-base:v0.1.0`
