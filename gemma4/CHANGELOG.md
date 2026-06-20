# Changelog

## v0.3.0

### Features

- Open WebUI chat interface at `https://<domain>/`, inherited from `llm-base` v0.3.0

### Changes

- Rebuild on `llm-base` v0.3.0 (bind-mount weight mounting, Open WebUI, vLLM v0.22.0)

## v0.2.3

### Bug Fixes

- Fixed weight-image registry in the vLLM mount drop-in (`kheeper.com` → `us.kheeper.com`); v0.2.2 only corrected the bound-image pull, so the mount still failed and vLLM never started

## v0.2.2

### Bug Fixes

- Fixed tag of the weight image

## v0.2.1

### Changes

- Rebuild on `llm-base` v0.2.1 (latest base digest, kernel `7.0.10-201`, vLLM v0.22.0)

## v0.2.0

### Changed

- `google/gemma-4-31B-it` weights now ship as a logically bound image (`kheeper.com/public/gemma4-weights:v1.0.0`) instead of being baked into the OS image. bootc pulls it separately into `/usr/lib/bootc/storage`; OS rebuilds no longer re-pull the ~59 GB weight layer.
- vLLM mounts the weights read-only at `/model` via a quadlet drop-in.
- Builds on [`llm-base`](../llm-base) v0.2.0.

## v0.1.0

### Features

- `google/gemma-4-31B-it` weights baked into `/usr/share/llm/model/`
- vLLM serving stack, NVIDIA driver/CDI wiring, Caddy TLS, and Grafana dashboard inherited from `kheeper.com/public/llm-base:v0.1.0`
