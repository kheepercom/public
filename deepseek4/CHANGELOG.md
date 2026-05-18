# Changelog

## v0.1.0

### Features

- `deepseek-ai/DeepSeek-V4-Flash` weights baked into `/usr/share/llm/model/`
- vLLM tuned for DeepSeek V4 via `VLLM_EXTRA_ARGS`: `--kv-cache-dtype fp8` (halves KV cache memory), `--enable-chunked-prefill`, `--block-size 256`, `--trust-remote-code`, and DeepSeek-specific `--tokenizer-mode`, `--tool-call-parser`, and `--reasoning-parser` parsers
- vLLM serving stack, NVIDIA driver/CDI wiring, Caddy TLS, and Grafana dashboard inherited from `kheeper.com/public/llm-base:v0.1.0`
