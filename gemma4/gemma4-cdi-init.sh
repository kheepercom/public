#!/bin/bash
set -euo pipefail

install -d -m 0755 /etc/cdi
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
