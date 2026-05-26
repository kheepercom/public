# llm-base maintainer notes

What to check / update when the underlying components move, and the
non-obvious constraints on editing files in this directory.

## When `kheeper.com/public/metrics-base` (or its base) bumps Fedora or the kernel

The `FROM` in `Containerfile` pulls metrics-base, which pulls
`kheeper.com/public/base`, which pulls `quay.io/fedora/fedora-bootc`. When
that chain bumps Fedora major or the kernel:

1. **Update `ARG KERNEL_VERSION`**. It must match the kernel actually
   shipped in the new base layer. Verify by booting the new base on a test
   host and running `uname -r`. The `akmods --force --kernels ${KERNEL_VERSION}`
   step compiles the open kmod against this version; a mismatch silently
   produces an unloadable kmod at boot.

2. **Update the RPM Fusion release URL** if Fedora major changed. The line
   ```
   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm
   ```
   has `44` hardcoded. f45 → `-45.noarch.rpm`.

3. **Re-verify `block-nouveau.conf` + `10-nvidia.toml`** still take effect.
   nouveau's auto-load behavior changes between kernel versions. After
   booting a new build, check `lspci -k -s 05:00.0` (or your GPU PCI addr)
   shows `Kernel driver in use: nvidia`, not `nouveau`.

4. **Re-test the open driver against the new kernel**. RPM Fusion's
   `kmod-nvidia-open` source isn't always available the day a new kernel
   ships. If `akmods` fails to build, you may need to hold off on the kernel
   bump until RPM Fusion catches up.

## When the NVIDIA driver pin (`ARG NVIDIA_DRIVER_VERSION`) needs to move

`ARG NVIDIA_DRIVER_VERSION=595.58.03` is the source of truth for every
NVIDIA package in the image. To bump:

1. Find what open-kmod sources RPM Fusion has:
   ```
   dnf repoquery --available kmod-nvidia-open
   ```
   The open kmod source lags the proprietary by ~1–2 minor versions. Pick
   the highest that exists.

2. Confirm matching `xorg-x11-drv-nvidia-${V}` packages exist:
   ```
   dnf repoquery --available 'xorg-x11-drv-nvidia*' | grep ${V}
   ```

3. **Do not include the `-release.fc44` suffix in the ARG.** `akmod-nvidia*`
   is at `-2.fc44` while `xorg-x11-drv-nvidia*` is at `-1.fc44`. dnf needs
   the freedom to resolve each to the right release. Use `595.58.03`, not
   `595.58.03-1.fc44`.

4. Both `akmod-nvidia` (proprietary) **and** `akmod-nvidia-open` must be
   listed in the `dnf install`. Only the open one gets built — `akmods
   --kmod nvidia-open` is explicit. The proprietary akmod is there purely
   to satisfy the `nvidia-kmod` virtual capability that
   `xorg-x11-drv-nvidia` requires at dnf-resolve time. Removing
   `akmod-nvidia` from the install list breaks dependency resolution.

5. `nvidia-gpu-firmware` is **not** version-pinned (it's a date-named rpm
   that bundles all driver versions). Confirm the new pin's blobs are
   shipped:
   ```
   sudo podman run --rm --entrypoint=/bin/sh kheeper.com/public/llm-base:vX -c \
     "ls /lib/firmware/nvidia/${NVIDIA_DRIVER_VERSION}/"
   ```
   Should list `gsp_ga10x.bin`, etc. If the directory is missing, the
   kernel module logs `Direct firmware load for nvidia/<V>/gsp_ga10x.bin
   failed with error -2` at boot and the GPU is unusable.

6. Update the `dnf versionlock` line if you add or remove any NVIDIA
   package; the versionlock keeps later in-place dnf upgrades from drifting
   off the matched-set.

## When vLLM bumps (`llm-vllm.image`)

`llm-vllm.image` and the `Image=` line in `llm-vllm.container` must be
kept in sync. They are **not** the same place:

- `llm-vllm.image` is the logically bound image declaration; bootc pulls
  that image into `/usr/lib/bootc/storage` alongside the OS image.
- The quadlet's literal `Image=` is what podman actually runs at boot,
  resolved from that store via the quadlet's
  `GlobalArgs=--storage-opt additionalimagestore=/usr/lib/bootc/storage`.

If you bump only one, builds succeed and the host boots, but either bootc
pulls a version podman never runs, or podman can't find the `Image=` in
the bound-image store and falls back to pulling from docker.io at first
boot.

Also bump `TimeoutStartSec=` in the quadlet's `[Service]` section if the
new vLLM is slower to load (current value 600s is comfortable for 60 GB
weights on an RTX PRO 6000).

## Editing the Caddyfile template

Use `handle /grafana/*`, **not** `handle_path /grafana/*`. `handle_path`
strips the matched prefix before forwarding to the upstream. Grafana's
sub-path config (`GF_SERVER_SERVE_FROM_SUB_PATH=true`,
`GF_SERVER_ROOT_URL=.../grafana/`) expects to see the `/grafana/` prefix
on every incoming request and 301-redirects to add it back when missing,
causing an infinite redirect loop with `handle_path`.

The `/v1/*` block has `read_timeout 10m` / `write_timeout 10m` for
streaming chat-completion responses. Don't drop these to the Caddy
defaults — long generations time out.

## Editing the vLLM quadlet

Non-obvious bits in `llm-vllm.container`:

- The `[Service]` section needs both `EnvironmentFile=` lines (for
  `/etc/kheeper/llm-vllm-model.env` and `/etc/kheeper/llm-vllm.env`).
  `EnvironmentFile=` in `[Container]` only feeds the *container's* env
  (via `podman --env-file`); systemd's `${VLLM_API_KEY}` /
  `${VLLM_SERVED_MODEL_NAME}` expansion in `Exec=` happens **before**
  podman runs, so without `[Service]` EnvironmentFiles those expand to
  empty strings and vLLM gets `--api-key '' --max-model-len ''`
  (the latter is a fatal error).

- The split between `llm-vllm.env` (user-tunable, rendered from
  `llm-vllm.env.khtmpl`) and `llm-vllm-model.env` (static, shipped by the
  leaf image with `VLLM_SERVED_MODEL_NAME=...`) is deliberate: the model
  identity is part of the image, not configuration.

- The model is **not** mounted by this base unit. Each leaf binds a
  `FROM scratch` `<model>-weights` image (an LBI) and ships a
  `llm-vllm.container.d/10-model.conf` drop-in mounting it with
  `Mount=type=image,source=...,destination=/model,readwrite=false`. Use
  `Mount=type=image` (read-only by default — **no `:Z`**), not
  `Volume=...:/model:Z`: `Z` triggers an SELinux relabel of the source,
  which fails on bootc's read-only composefs `/usr` with `lsetxattr ...
  EROFS` before the container even starts. The weights tag is pinned in
  two leaf files — `llm-model.image` and `10-model.conf` — bump both
  together.

- Adding a new env var to `llm-vllm.env.khtmpl`? Also add the
  corresponding `--<flag> ${VAR}` to `Exec=`, and (if it's a runtime
  knob) expose it in `schema.json` with sensible defaults.

- `$VLLM_EXTRA_ARGS` at the tail of `Exec=` is **unbraced on purpose** —
  systemd word-splits `$VAR` but treats `${VAR}` as a single argument
  (systemd.service(5)). Leaves use it to inject multi-flag model-specific
  tuning (`--trust-remote-code`, custom parsers, etc.) without touching
  the base. Don't add braces around it. Don't quote it.

## Editing `llm-cdi-init.sh`

The whole script body is one command: `nvidia-ctk cdi generate
--output=/etc/cdi/nvidia.yaml`. Don't add `nvidia-ctk runtime configure
--runtime=crun --cdi.enabled` here — that's the old (pre-CDI) podman wiring
and errors with "unrecognized runtime 'crun'", causing the unit to fail
even though the CDI spec is already written. Podman picks up CDI devices
directly from `--device nvidia.com/gpu=all` in the quadlet without any
runtime configuration step.

The `llm-cdi-init.service` unit has `ConditionPathExists=!/etc/cdi/nvidia.yaml`
so it only runs once per boot, on the first attempt where the spec doesn't
exist. That's intentional.

## bootc-lint warnings to expect

`RUN bootc container lint` runs at the end of the build. Two warning
categories are normal and can be ignored:

- **"Found non-empty logfiles"** — akmods + dnf write logs during the
  build. They're harmless leftovers.
- **"Found content in /var missing systemd tmpfiles.d entries"** —
  package-cache dirs etc. bootc wipes `/var` on first boot so these
  build-time artifacts don't survive. Only add a tmpfiles.d entry if the
  package genuinely needs that path **at runtime**, not because the lint
  warned about it.

The lint will refuse to pass on actually-broken things (missing init
files, SELinux relabel issues, etc.), so don't silence it broadly.
