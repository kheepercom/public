#!/bin/bash
# Resolve the leaf's model-weights bound image to a filesystem path.
#
# bootc pulls the image declared in llm-model.image into
# /sysroot/ostree/bootc/storage as a logically bound image. This script
# reads the store metadata, finds the unpacked layer, and symlinks
# /var/lib/llm-model to its diff directory so vLLM can bind-mount it.
#
# Only single-layer weight images are supported (all kheeper weights
# images are FROM-scratch with a single COPY).
set -euo pipefail

image_file=/usr/share/containers/systemd/llm-model.image
store=/sysroot/ostree/bootc/storage
link=/var/lib/llm-model

ref=$(sed -n 's/^Image=//p' "$image_file")
if [[ -z "$ref" ]]; then
    echo "error: no Image= in $image_file" >&2
    exit 1
fi

layer_id=$(python3 - "$ref" "$store" <<'PY'
import json, sys
ref, store = sys.argv[1], sys.argv[2]
with open(f"{store}/overlay-images/images.json") as f:
    for img in json.load(f):
        if ref in img.get("names", []):
            print(img["layer"])
            sys.exit(0)
sys.exit(1)
PY
) || { echo "error: $ref not found in bootc store" >&2; exit 1; }

diff=$store/overlay/$layer_id/diff
if [[ ! -d "$diff" ]]; then
    echo "error: layer dir missing: $diff" >&2
    exit 1
fi

ln -sfn "$diff" "$link"
echo "linked $link -> $ref"
